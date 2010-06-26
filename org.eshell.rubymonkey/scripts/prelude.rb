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
  "org.eclipse.swt"])
java_import org.eclipse.jface.dialogs.MessageDialog
java_import org.eclipse.swt.widgets.Display
java_import java.lang.Runnable

class ShowDialog
  include Runnable
  def initialize(message)
    @message = message
  end
  def run()
      MessageDialog.openInformation(
      $window.getShell(),
      "Monkey Dialog",
      @message)
  end
end

def alert(message)
  Display.default.syncExec(ShowDialog.new(message))
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
