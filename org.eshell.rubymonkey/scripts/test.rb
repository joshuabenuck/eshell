# Menu: Ruby > test
# Key: M3+Z

require 'java'
require 'prelude'
addBundles(
  ["org.eclipse.ui.console",
   "org.eclipse.ui",
   "org.eclipse.ant.core",
   "org.eclipse.ant.ui",
   "org.eclipse.debug.core"]
)

#puts window.methods()
#puts $LOAD_PATH
#alert("testing")

#puts(bundles["org.eclipse.jface"])
#puts(bundles["org.eclipse.jdt.core"])
#puts(bundles["org.eclipse.core.resources"])

java_import org.eclipse.ui.console.ConsolePlugin
java_import org.eclipse.ui.PlatformUI
java_import org.eclipse.ant.core.AntRunner
java_import org.eclipse.ant.internal.ui.launchConfigurations.AntLaunchShortcut
java_import org.eclipse.debug.core.DebugPlugin
java_import org.eclipse.debug.core.ILaunchManager
java_import org.eclipse.debug.core.ILaunchesListener2
java_import java.util.concurrent.CountDownLatch

#puts ResourcesPlugin.getWorkspace().getRoot().findMember("${workspace_loc:/eshell/build.xml}")
project = getProject("eshell")
buildFiles = findBuildFiles(project)
#runner = AntRunner.new()
#runner.buildFileLocation = buildFiles[0].rawLocation.toFile().absolutePath
#runner.availableTargets.each do |t|
#    puts(t)
#end
#runner.setExecutionTargets(array(["test"], String))
#runner.addBuildLogger("org.eclipse.ant.internal.ui.antsupport.logger.AntProcessBuildLogger")
#runner.run()

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

class Runner < java.lang.Thread
  include java.lang.Runnable
  def initialize(&block)
    @logic = block
  end
  def run()
    @logic.call()
  end
end

def run(&block)
  Runner.new(&block).start()
end

# Rework into runAntScript(path, target)
run {
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