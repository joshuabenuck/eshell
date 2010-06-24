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
addBundle("org.eclipse.jface")
addBundle("org.eclipse.jdt.core")
addBundle("org.eclipse.core.resources")
java_import org.eclipse.jface.dialogs.MessageDialog

def alert(message)
    MessageDialog.openInformation(     
            $window.getShell(),     
            "Monkey Dialog", 
            message)
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
