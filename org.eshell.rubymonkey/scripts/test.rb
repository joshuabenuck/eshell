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
  def launchesTerminated(launches)
    begin
      launches.each do |l|
        puts l.processes[0].methods.sort
      end
    ensure
      DebugPlugin.default.launchManager.removeLaunchListener(self)
    end
  end
end

antListener = AntListener.new()
begin
  DebugPlugin.default.launchManager.addLaunchListener(antListener)
  AntLaunchShortcut.new().launch(buildFiles[0].fullPath, project.getProject(), ILaunchManager.RUN_MODE, "test")
rescue
  DebugPlugin.default.launchManager.removeLaunchListener(antListener)
end