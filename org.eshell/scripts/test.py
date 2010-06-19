# Menu: Python> test
# Key: M3+Z
import sys
from org.eclipse.jface.dialogs import MessageDialog
from org.eclipse.ui.console import ConsolePlugin
from org.eclipse.jdt.core import JavaCore
from org.eclipse.core.resources import ResourcesPlugin
from org.eclipse.ui import PlatformUI
from org.eclipse.jface.dialogs import MessageDialog
from org.eclipse.ant.core import AntRunner
from jarray import array
from java.lang import String
from org.eclipse.ant.internal.ui.launchConfigurations import AntLaunchShortcut
from org.eclipse.debug.core import ILaunchManager

def pp(obj):
    for i in dir(obj):
        print i

def alert(message):
    MessageDialog.openInformation(     
            window.getShell(),     
            "Monkey Dialog", 
            message)

def getProject(name):
    javaProjects = JavaCore.create(ResourcesPlugin.getWorkspace().getRoot()).getJavaProjects()
    for project in javaProjects:
        if project.getProject().getDescription().getName() == name:
            return project

def findBuildFiles(project):
    buildFiles = []
    for f in project.getNonJavaResources():
        if f.name.find("build.xml") != -1:
            buildFiles.append(f)
    return buildFiles

project = getProject("eshell")
buildFiles = findBuildFiles(project)
runner = AntRunner()
runner.buildFileLocation = buildFiles[0].rawLocation.toFile().absolutePath
for t in runner.availableTargets:
    pp(t)
runner.setExecutionTargets(array(["test"], String))
#runner.addBuildLogger("org.eclipse.ant.internal.ui.antsupport.logger.AntProcessBuildLogger")
runner.run()
#AntLaunchShortcut().launch(buildFiles[0].fullPath, project.getProject(), ILaunchManager.RUN_MODE, "test")
