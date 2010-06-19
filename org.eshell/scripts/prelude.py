# Menu: Python > prelude
# Debug display
from org.eclipse.jface.dialogs import MessageDialog

def ppdir(obj):
    for i in dir(obj):
        print i
        
def pp(obj):
    for i in obj:
        print i
        
def alert(message):
    MessageDialog.openInformation(     
            window.getShell(),     
            "Monkey Dialog", 
            message)

goaway = "please!"

# Project / build file support
from org.eclipse.jdt.core import JavaCore
from org.eclipse.core.resources import ResourcesPlugin

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

print "test"