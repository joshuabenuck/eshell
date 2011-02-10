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

def alert(message)
  return display {
    MessageDialog.openInformation(
      $window.shell,
      "Monkey Dialog",
      message)
  }
end

def confirm(message)
  return display {
    MessageDialog.openConfirm($window.shell, "Monkey Confirm", message)
  }
end

java_import org.eclipse.jface.dialogs.InputDialog
java_import org.eclipse.jface.window.Window
def prompt(message, defaultValue=nil)
  return display {
    dialog = InputDialog.new(nil, "Monkey Prompt", message, defaultValue, nil)
    dialogResult = dialog.open
    value = defaultValue
    if dialogResult == Window::OK
      value = dialog.getValue()
    end
    value
  }
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

$project = nil
$env = {}
$last = nil
$status_line = nil

java_import org.eclipse.ui.console.ConsolePlugin
java_import org.eclipse.ui.PlatformUI

# Must not be run in UI thread!
class BuildFileShell
  def initialize(project, file)
    @project = project
    @file = file
    @runner = AntRunner.new()
    @runner.buildFileLocation = file.rawLocation.toFile().absolutePath
  end
  
  def execute(env, target)
    antListener = AntListener.new(@file)
    begin
      DebugPlugin.default.launchManager.addLaunchListener(antListener)
      AntLaunchShortcut.new().launch(@file.fullPath, 
        @project.getProject(), 
        ILaunchManager.RUN_MODE, target)
      antListener.complete.await
      return true
    rescue Exception => e
      alert(e.message + "\n" + e.backtrace.join("\n"))
    ensure
      DebugPlugin.default.launchManager.removeLaunchListener(antListener)
    end
  end
end  

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

def project(name)
  p = getProject(name.to_s)
  # TODO: Improve
  $state["project"] = name.to_s
  $project = p
end

def getFile(name)
  return $project.getProject().getFile(name)
end

class BuildShell
  include Shell
  def initialize(path, targets)
    @path = path
    @aliases = {}
    @targets = []
    targets.each { |t|
      if t.is_a? Array
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

addBundles([
  "org.eclipse.ui"
])

java_import org.eclipse.ui.PlatformUI
def url(_url = nil, _prompt = "Please enter url: ")
  _url = prompt(_prompt) if _url == nil  
  return true if _url == nil
  _url = "http://#{_url}" if _url.index("http://") != 0
  support = PlatformUI.workbench.browserSupport
  display {
    support.createBrowser("url").openURL(
      java.net.URL.new(_url))
  }
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

addBundles([
  "org.eclipse.ui",
  "org.eclipse.core.resources"
])
java_import org.eclipse.ui.PlatformUI
java_import org.eclipse.core.resources.IResource
def dupKeys
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

def run_shell()
  if $state["project"] != nil
    project $state["project"]
  end
  run {
    begin
      cmd = prompt("project: " + $state["project"].to_s)
      return if cmd == nil
      eval cmd
    rescue Exception => e
      alert(e.message + "\n" + e.backtrace.join("\n"))
    end
  }
end
