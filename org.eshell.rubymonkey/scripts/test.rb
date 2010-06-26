# Menu: Ruby > test
# Key: M3+Z

require 'java'
require 'prelude'
addBundles(
  ["org.eclipse.ui.console",
   "org.eclipse.ui",
  ])

#puts window.methods()
#puts $LOAD_PATH
#alert("testing")

#puts(bundles["org.eclipse.jface"])
#puts(bundles["org.eclipse.jdt.core"])
#puts(bundles["org.eclipse.core.resources"])

java_import org.eclipse.ui.console.ConsolePlugin
java_import org.eclipse.ui.PlatformUI

#puts ResourcesPlugin.getWorkspace().getRoot().findMember("${workspace_loc:/eshell/build.xml}")
#runner = AntRunner.new()
#runner.buildFileLocation = buildFiles[0].rawLocation.toFile().absolutePath
#runner.availableTargets.each do |t|
#    puts(t)
#end
#runner.setExecutionTargets(array(["test"], String))
#runner.addBuildLogger("org.eclipse.ant.internal.ui.antsupport.logger.AntProcessBuildLogger")
#runner.run()
puts prompt("Enter a command: ")