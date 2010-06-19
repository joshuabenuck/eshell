# Menu: Python> test
# Key: M3+Z
import sys
from org.eclipse.jface.dialogs import MessageDialog
from org.eclipse.ui.console import ConsolePlugin
from org.eclipse.ui import PlatformUI
from org.eclipse.ant.core import AntRunner
from jarray import array
from java.lang import String
from org.eclipse.ant.internal.ui.launchConfigurations import AntLaunchShortcut
from org.eclipse.debug.core import ILaunchManager
import prelude
#reload(prelude)
from prelude import *

for p in sys.path: print p
for i in dir(prelude): print i
project = getProject("eshell")
buildFiles = findBuildFiles(project)
runner = AntRunner()
runner.buildFileLocation = buildFiles[0].rawLocation.toFile().absolutePath
#for t in runner.availableTargets:
#    pp(t)
runner.setExecutionTargets(array(["test"], String))
#runner.addBuildLogger("org.eclipse.ant.internal.ui.antsupport.logger.AntProcessBuildLogger")
runner.run()
#AntLaunchShortcut().launch(buildFiles[0].fullPath, project.getProject(), ILaunchManager.RUN_MODE, "test")
