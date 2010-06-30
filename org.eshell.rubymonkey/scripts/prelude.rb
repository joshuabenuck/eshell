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

def getProject(name)
    javaProjects = JavaCore.create(ResourcesPlugin.getWorkspace().getRoot()).getJavaProjects()
    javaProjects.each do |project|
        if project.getProject().getDescription().getName() == name
            return project
        end
    end
end

def findBuildFiles(project)
    buildFiles = []
    project.getNonJavaResources().each do |f|
        if f.name.index("build.xml") != nil
            buildFiles.push(f)
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