# Base framework
def addBundles(names)
  names.each do |name|
    addBundle(name)
  end
end

def addBundle(name)
  bundle = $bundles[name]
  if bundle == nil
    raise "Unknown bundle: " + name
  end
  $loader.addBundle(bundle)
end
require 'java'
addBundles(["org.eclipse.jface",
  "org.eclipse.core.runtime",
  "org.eclipse.core.variables",
  "org.eclipse.core.resources",
  "org.eclipse.ui.externaltools",
  "org.eclipse.jdt.core",
  "org.eclipse.ant.core",
  "org.eclipse.ant.ui",
  "org.eclipse.debug.core",
  "org.eclipse.swt"])
java_import org.eclipse.jface.dialogs.MessageDialog
java_import org.eclipse.swt.widgets.Display
java_import java.lang.Runnable

# Thread utilities
class Runner < java.lang.Thread
  include java.lang.Runnable
  def initialize(&block)
    @logic = block
    @result = nil
  end
  def run()
    @result = @logic.call()
  end
  def result()
    return @result
  end
end

def run(&block)
  begin
    r = Runner.new(&block)
    r.start()
    return r.result
  rescue Exception => e
    alert(e.message + "\n" + e.backtrace.join("\n"))
  end
  return nil
end

def _run(&block) end
  
def display(&block)
  r = Runner.new(&block)
  Display.default.syncExec(r)
  return r.result
end

# Dialogs
java_import org.eclipse.swt.SWT
java_import org.eclipse.swt.widgets.Composite
java_import org.eclipse.swt.widgets.List
java_import org.eclipse.swt.layout.GridLayout
java_import org.eclipse.swt.layout.GridData
java_import org.eclipse.jface.dialogs.IDialogConstants
java_import org.eclipse.swt.events.SelectionListener
class ListDialog < MessageDialog
  include SelectionListener
  attr_accessor :selected
  
  def initialize(parent, title, image, message, kind, labels, index, items, opts={})
    super(parent, title, image, message, kind, labels, index)
    @listItems = items
    @selectionHandler = opts[:selectionHandler]
    @selected = nil
  end
  
  def self.show(title, message, items, opts={})
    retValue = -1
    dialog = nil
    display {
      dialog = ListDialog.new($window.shell, title, nil,
                message, 0, 
                [IDialogConstants::OK_LABEL].to_java(:string), 0, items, opts)
      retValue = dialog.open
    }
    return dialog.selected if retValue != -1
    return retValue
  end
  
  def createCustomArea(parent)
    composite = Composite.new(parent, 0)
    layout = GridLayout.new
    layout.numColumns = 1
    layout.marginHeight = 0
      #convertVerticalDLUsToPixels(IDialogConstants::VERTICAL_MARGIN)
    layout.marginWidth = 0 
      #convertHorizontalDLUsToPixels(IDialogConstants::HORIZONTAL_MARGIN)
    layout.horizontalSpacing = 0 
      #convertHorizontalDLUsToPixels(IDialogConstants::HORIZONTAL_SPACING)
    composite.setLayout(layout)
    composite.setLayoutData(GridData.new(GridData::FILL_BOTH))

    if @listItems != nil
      @list = List.new(composite, SWT::BORDER)
      data = GridData.new(GridData::GRAB_HORIZONTAL | 
                          GridData::GRAB_VERTICAL | 
                          GridData::HORIZONTAL_ALIGN_FILL | 
                          GridData::VERTICAL_ALIGN_CENTER)
      @list.setLayoutData(data)
      @list.setItems(@listItems)
      @list.addSelectionListener self
    end
    return composite
  end
  
  def widgetSelected(event)
    @selected = @listItems[@list.selectionIndex]
    if @selectionHandler != nil
      @selectionHandler.call(event)
    end
  end
  
  def widgetDefaultSelected(event)
  end
end

def alert(message)
  message = message.to_s
  return display {
    MessageDialog.openInformation(
      $window.shell,
      "eshell alert",
      message)
  }
end

def confirm(message)
  return display {
    MessageDialog.openConfirm($window.shell, "eshell confirm", message)
  }
end

def list(items, title="eshell list", message="", opts={})
  ListDialog::show(title, message, items, opts)
end

$historyLimit = 25
class CommandHistory
  attr_accessor :entries
  def initialize
    historyString = $state["history"]
    @entries = []
    if historyString != nil
      @entries = historyString.split("\u0001")
    end
    @index = @entries.size
  end
  
  def onFirstEntry
    return @index == 0
  end
  
  def nextEntry
    if @index < (@entries.size)
      @index+=1
      return "" if @entries.size == @index
      return @entries[@index]
    end
    return nil
  end
  
  def prevEntry
    if @index > 0
      @index-=1
      return @entries[@index]
    end
    return nil
  end
  
  def addEntry(entry)
    if entry != @entries[@entries.size - 1]
      @entries.push entry
      if @entries.size > $historyLimit
        @entries.shift
      end
      $state["history"] = @entries.join("\u0001")
    end
  end
end
$history = CommandHistory.new

java_import org.eclipse.jface.dialogs.InputDialog
java_import org.eclipse.jface.window.Window
java_import org.eclipse.swt.events.KeyListener
java_import org.eclipse.swt.graphics.Point
class CommandHistoryListener
  include KeyListener
  
  def keyReleased(event)
    entry = nil
    if event.keyCode == SWT::ARROW_UP
      entry = $history.prevEntry
    elsif event.keyCode == SWT::ARROW_DOWN
      entry = $history.nextEntry
    else
      return
    end
    event.source.setText(entry) if entry != nil
    text = event.source.text
    pos = $history.onFirstEntry ? 0 : text.size
    event.source.setSelection(Point.new(pos, pos))
    event.source.redraw
  end
  def keyPressed(event)
  end
end

def prompt(message, defaultValue=nil, opts={})
  return display {
    dialog = InputDialog.new(nil, "eshell prompt", message, defaultValue, nil)
    dialog.create
    dialog.text.addKeyListener(opts[:keyListener]) if opts[:keyListener]
    dialogResult = dialog.open
    value = defaultValue
    if dialogResult == Window::OK
      value = dialog.getValue()
    end
    value
  }
end

def history
  retValue = list($history.entries, "Choose history entry to run", "")
  run_cmd retValue if retValue != -1
end

# Project / build file support
java_import org.eclipse.jdt.core.JavaCore
java_import org.eclipse.core.resources.ResourcesPlugin
java_import org.eclipse.core.resources.IResourceVisitor

def getProject(name)
    return JavaCore.create(ResourcesPlugin.getWorkspace().getRoot()).getJavaProject(name)
end

class BuildFileAdder
  include IResourceVisitor
  
  def initialize(buildFiles)
    @buildFiles = buildFiles
  end
  
  def visit(resource)
    @buildFiles.push(resource) if resource.rawLocation.to_s.index("build.xml") != nil
    return false if resource.rawLocation.to_s.index(".svn") != nil
    return true if resource.type == IResource::FOLDER
    return false
  end
end

def findBuildFiles(project)
    buildFiles = []
    project.getNonJavaResources().each do |f|
        next if f.rawLocation.to_s.index(".svn") != nil
        if f.rawLocation.to_s.index("build.xml") != nil
          buildFiles.push(f)
        elsif f.type == IResource::FOLDER
          f.accept(BuildFileAdder.new(buildFiles))
        end
    end
    return buildFiles
end

java_import org.eclipse.core.variables.VariablesPlugin
java_import org.eclipse.ui.externaltools.internal.model.IExternalToolConstants
java_import org.eclipse.ant.internal.ui.AntUtil
java_import org.eclipse.core.runtime.CoreException

def getFileFromLocation(location)
  # Taken from AntMainTab.getIFile()
  manager = VariablesPlugin.default.stringVariableManager
  begin
    #location = configuration.getAttribute(IExternalToolConstants.ATTR_LOCATION, "default")
    if location != "default"
       expandedLocation = manager.performStringSubstitution(location)
       if expandedLocation != nil
         file = AntUtil.getFileForLocation(expandedLocation, nil)
         return file
       end
    end
  rescue CoreException
  end
  return nil
end

java_import org.eclipse.ant.core.AntRunner
java_import org.eclipse.ant.internal.ui.launchConfigurations.AntLaunchShortcut
java_import org.eclipse.debug.core.DebugPlugin
java_import org.eclipse.debug.core.ILaunchManager
java_import org.eclipse.debug.core.ILaunchesListener2
java_import java.util.concurrent.CountDownLatch

class AntListener
  include ILaunchesListener2
  def initialize(buildFile)
    @buildFile = buildFile
    @complete = CountDownLatch.new(1)
  end
  def complete
    return @complete
  end
  def launchesAdded(launches) end
  def launchesChanged(launches) end
  def launchesRemoved(launches) end
  def launchesTerminated(launches)
    begin
      launches.each { |l|
        loc = l.launchConfiguration.attributes[IExternalToolConstants.ATTR_LOCATION]
        file = getFileFromLocation(loc)
        if file == @buildFile
          @complete.countDown
        end
      }
    rescue Exception => e
      alert(e.message + "\n" + e.backtrace.join("\n"))
    ensure
      DebugPlugin.default.launchManager.removeLaunchListener(self)
    end
  end
end

# Rework into runAntScript(path, target)
_run {
  project = getProject("eshell")
  buildFiles = findBuildFiles(project)
  antListener = AntListener.new(buildFiles[0])
  begin
    DebugPlugin.default.launchManager.addLaunchListener(antListener)
    AntLaunchShortcut.new().launch(buildFiles[0].fullPath, project.getProject(), ILaunchManager.RUN_MODE, "test")
    antListener.complete.await
    alert "done"
  rescue
    DebugPlugin.default.launchManager.removeLaunchListener(antListener)
  end
}

java_import org.eclipse.ui.console.ConsolePlugin
java_import org.eclipse.ui.PlatformUI

# Basic shell command registration
module Shell
  attr_accessor :parent
  
  def method_missing(method, *params)
    if parent != nil
      parent.send(method, params)
    else
      Object.send(method, params)
    end
  end
end

class Hash
  def to_mod
    hash = self
    Module.new {
      hash.each_pair do |k, v|
        define_method(k.to_sym) { v }
      end
    }
  end
end

def register(name, config=nil)
  if config.is_a? Hash
    Object.send(:define_method, name) {Object.new.extend(config.to_mod)}
  else
    Object.send(:define_method, name) { config }
  end
end

$project = nil
$env = {}
$last = nil
$status_line = nil

def project(name)
  p = getProject(name.to_s)
  # TODO: Improve
  $state["project"] = name.to_s
  $project = p
end

def getFile(name)
  return $project.getProject().getFile(name)
end

def getFiles(names)
  names.map {|n| $project.project.getFile(n)}
end

def getFolder(name)
  return $project.getProject().getFolder(name)
end

def getFolders(names)
  names.map {|n| $project.project.getFolder(n)}
end

def markDerived dirName="build"
  dirs = findDirs dirName
  folders = xmap :getFolder, dirs
  margs :setDerived, true, nil, folders
  list folders.collect{|f| f.to_s}, "Following dirs marked as derived", ""  
end

# Must not be run in UI thread!
class BuildShell
  include Shell
  def initialize(path, targets)
    @path = path
    @aliases = {}
    @targets = []
    targets.each { |t|
      if t.is_a? Array
        t = t.clone
        name = t.shift
        @targets.push name
        t.each { |a|
          @aliases[a] = name
        }
      else
        @targets.push t
      end
    }
  end
  
  def parent
    ant
  end
  
  def method_missing(name, *args)
    if @aliases.has_key? name
      name = @aliases[name]
    end
    if @targets.include? name
      target = name.to_s
      file = getFile(@path)
      @runner = AntRunner.new()
      @runner.buildFileLocation = file.rawLocation.toFile().absolutePath
      antListener = AntListener.new(file)
      begin
        DebugPlugin.default.launchManager.addLaunchListener(antListener)
        AntLaunchShortcut.new().launch(file.fullPath, 
          $project.getProject(), 
          ILaunchManager.RUN_MODE, target)
        antListener.complete.await
      rescue Exception => e
        alert(e.message + "\n" + e.backtrace.join("\n"))
      ensure
        DebugPlugin.default.launchManager.removeLaunchListener(antListener)
      end
      return self
    else
      #raise NoMethodError.new(name.to_s)
      parent.send(name, *args)
    end
  end
end

def buildShell(path, targets)
  return BuildShell.new(path, targets)
end

def url(_url = nil, _prompt = "Please enter url: ")
  addBundles([
    "org.eclipse.ui"
  ])
  java_import org.eclipse.ui.PlatformUI
  _url = prompt(_prompt) if _url == nil  
  return true if _url == nil
  _url = "http://#{_url}" if _url.index("http://") != 0
  support = PlatformUI.workbench.browserSupport
  display {
    support.createBrowser("url").openURL(
      java.net.URL.new(_url))
  }
end

def browsers
  addBundles(["org.eclipse.ui.browser"])
  java_import org.eclipse.ui.internal.browser.WebBrowserUIPlugin
  return WebBrowserUIPlugin::browsers
end

def firefoxDef
  return browsers.select { |b| b.id == "org.eclipse.ui.browser.firefox" && b.os == "Win32"}[0]
end

$firefoxPath = "c:\\progra~2\\mozilla firefox\\firefox.exe"
def fx(url)
  firefoxDef.createBrowser("1", $firefoxPath, "").openURL(java.net.URL.new(url))
end

def define(word)
  url("http://google.com/search?q=define:+#{word}")
end

=begin
addBundles(["org.eclipse.wst.server.core",
            "org.eclipse.debug.core"])
java_import org.eclipse.wst.server.core.ServerCore
java_import org.eclipse.debug.core.ILaunchManager
#java_import org.eclispe.debug.core.IStreamListener
class ServerShell
  def execute(env, cmd)
    return nil if cmd.index("server ") != 0
    project = env["project"]
    parts = cmd.split(" ")
    action = parts[1]
    server = nil; server = parts[2] if parts.length > 2
    return start(project, server) if action == "start"
    return stop(project, server) if action == "stop"
    return nil
  end
  
  def start(project, server = nil)
    location = "unknown"
    location = project.project.location.to_s if project != nil and project.project.location != nil
    matches = ServerCore.servers.select { |s|
      (s.runtime.location.to_s.index(location) == 0 || s.name == server)
    }
    raise Exception.new("Too many servers match the active project: " + matches.to_s) if matches.length > 1
    raise Exception.new("No servers match the active project: " + location) if matches.length == 0
    matches[0].synchronousStart(ILaunchManager.DEBUG_MODE, nil)
    #TODO: Make an env var.
    java.lang.Thread.sleep(5000)
    # Possible alternative approach.
    #matches[0].launch.processes[0].streamsProxy.outputStreamMonitor.addListener
    #IStreamListener.streamAppended(text, monitor)
    return true
  end
  
  def stop(project, server = nil)
    location = "unknown" 
    location = project.project.location.to_s if project != nil and project.project.location != nil
    matches = ServerCore.servers.select { |s|
      (s.runtime.location.to_s.index(location) == 0 || s.name == server)
    }
    raise Exception.new("Too many servers match the active project: " + matches.to_s) if matches.length > 1
    raise Exception.new("No servers match the active project: " + location) if matches.length == 0
    matches[0].synchronousStop(false)
    return true
  end
end
=end

def bz(number=nil)
  number = prompt("Please enter BZ number: ") if number == nil
  return Object.new if number == nil
  support = PlatformUI.workbench.browserSupport
  display {
    support.createBrowser("bz").openURL(
      java.net.URL.new($bzUrl + "show_bug.cgi?id=" + number.to_s))
  }
end

def dupKeys
  addBundles([
    "org.eclipse.ui",
    "org.eclipse.core.resources"
  ])
  java_import org.eclipse.ui.PlatformUI
  java_import org.eclipse.core.resources.IResource
  input = display {
    PlatformUI.workbench.activeWorkbenchWindow.
      activePage.activeEditor.editorInput
  }
  if input.name.index(".properties") == nil
    alert(input.name + " is not a properties file.")
    return Object.new
  end
  resource = input.getAdapter(IResource.java_class)
  reader = java.io.BufferedReader.new(
    java.io.InputStreamReader.new(resource.contents))
  keys = {}
  while reader.ready do
    line = reader.readLine.strip
    next if line.size() == 0
    next if line.index("#") != nil
    if line.index("=") != nil
      (key, value) = line.split("=").collect {|i| i.strip}
      alert("Duplicate key: " + key) if keys.has_key?(key)
      keys[key] = value
    end
  end
  return Object.new
end

# http://www.javapractices.com/topic/TopicAction.do?Id=82
def cc(filename)
  java_import java.awt.Toolkit
  java_import java.awt.datatransfer.DataFlavor
  java_import java.io.FileWriter
  java_import java.io.BufferedWriter
  java_import javax.imageio.ImageIO
  java_import java.io.File
  clipboard = Toolkit.defaultToolkit.systemClipboard
  contents = clipboard.getContents(nil)
  if contents.isDataFlavorSupported(DataFlavor.stringFlavor)
    contents = getTransferData(DataFlavor.stringFlavor)
    writer = BufferedWriter.new(FileWriter.new($clipboardPath + "/" + filename))
    writer.write(contents)
    writer.close
  elsif contents.isDataFlavorSupported(DataFlavor.imageFlavor)
    img = contents.getTransferData(DataFlavor.imageFlavor)
    parts = filename.to_s.split(".")
    filename = parts[0]
    ext = (parts.size > 1) ? parts[1] : "png"
    ImageIO.write(img,ext,File.new($clipboardPath + "/" + filename + "." + ext))
  else
    alert("Unsupported data type!")
  end
end

def vim(filename = nil)
  java_import java.lang.Runtime
  display {
    if filename == nil
      input = PlatformUI.workbench.activeWorkbenchWindow.activePage.
        activeEditor.editorInput
      alert("No active editor and no filename was specified!") if input == nil
      filename = input.file.rawLocation.toFile().absolutePath
    end
    Runtime.runtime.exec($vimPath + " --servername eclipse --remote-tab-silent " + filename)
  }
end

=begin
class Object
  public
  def | partial
    return partial.call(self)
  end
end
=end

def curry fn,*a
  return lambda { |*b|
     fn.call(*(a + b))
   }
end

def pmethods(obj)
  list(obj.methods.sort)
end

java_import org.eclipse.ui.part.FileEditorInput
def edit(file)
  display {
    page = PlatformUI.workbench.activeWorkbenchWindow.activePage
    desc = PlatformUI.workbench.editorRegistry.getDefaultEditor(file.name)
    page.openEditor(FileEditorInput.new(file), desc.id)
  }
end

# Runs a method on each element in the list.
def xargs *args
  m = args.shift
  args.slice!(-1).each {|a|
    method(m).call(*(args + [a]))
  }
end

# Like xargs, but runs the method off of the objects in the list.
def margs *args
  m = args.shift
  args.slice!(-1).each {|a|
    a.method(m).call(*(args))
  }
end

def config file
  p = getProject("eshell")
  p = getProject("org.eshell.rubymonkey") if !p.isOpen
  edit p.project.getFile(file)
end

def eshellrc; config "scripts/eshellrc.rb"; end
def eshell; config "scripts/eshell.rb"; end

def run_cmd cmd
  begin
    if cmd == ""
      cmd = $state["last_cmd"]
    else
      $history.addEntry(cmd)
    end 
    return if cmd == nil
    $state["last_cmd"] = cmd
    retValue = "!undefined!"
    cmd.split("|").each { |c|
      if retValue != "!undefined!"
        c += "," if c.count(" ") > 1
        c += " retValue"
      end
      retValue = eval c
    }
  rescue Exception => e
    alert(e.message + "\n" + e.backtrace.join("\n"))
  end
end

def findDirs dirName="build"
  root = $project.project.location.to_s
  return Dir.glob(File.join(root + "/**", dirName)).collect {|d|
    path = d.to_s.slice(root.size + 1, d.to_s.size)
    print path
    path
  }
end

def xmap f, l
  return l.collect {|e| method(f).call(e) }
end

def mmap f, l
  return l.collect {|e| e.method(f).call(*a) }
end

def run_shell()
  if $state["project"] != nil
    project $state["project"]
  end
  run {
    begin
      cmd = prompt("project: " + $state["project"].to_s + 
        "\tlast command: " + $state["last_cmd"].to_s, nil,
        {:keyListener => CommandHistoryListener.new})
      run_cmd cmd
    rescue Exception => e
      alert(e.message + "\n" + e.backtrace.join("\n"))
    end
  }
end
