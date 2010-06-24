# Menu: Ruby > test
# Key: M3+Z

#puts window.methods()
#puts $LOAD_PATH
require 'java'
require 'prelude'
#alert("testing")

#puts(bundles["org.eclipse.jface"])
#puts(bundles["org.eclipse.jdt.core"])
#puts(bundles["org.eclipse.core.resources"])

addBundle("org.eclipse.ui.console")
addBundle("org.eclipse.ui")
addBundle("org.eclipse.ant.core")
addBundle("org.eclipse.ant.ui")
addBundle("org.eclipse.debug.core")
java_import org.eclipse.ui.console.ConsolePlugin
java_import org.eclipse.ui.PlatformUI
java_import org.eclipse.ant.core.AntRunner
java_import org.eclipse.ant.internal.ui.launchConfigurations.AntLaunchShortcut
java_import org.eclipse.debug.core.ILaunchManager

project = getProject("eshell")
buildFiles = findBuildFiles(project)
runner = AntRunner.new()
runner.buildFileLocation = buildFiles[0].rawLocation.toFile().absolutePath
#for t in runner.availableTargets:
#    pp(t)
#runner.setExecutionTargets(array(["test"], String))
#runner.addBuildLogger("org.eclipse.ant.internal.ui.antsupport.logger.AntProcessBuildLogger")
#runner.run()
#AntLaunchShortcut().launch(buildFiles[0].fullPath, project.getProject(), ILaunchManager.RUN_MODE, "test")
