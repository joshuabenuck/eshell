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

# Must not be run in UI thread!
class TargetCmd
  def initialize(project, file, target)
    @project = project
    @file = file
    @target = target
  end
  
  def execute()
    antListener = AntListener.new(@file)
    begin
      DebugPlugin.default.launchManager.addLaunchListener(antListener)
      AntLaunchShortcut.new().launch(@file.fullPath, 
        @project.getProject(), 
        ILaunchManager.RUN_MODE, @target)
      antListener.complete.await
    rescue Exception => e
      DebugPlugin.default.launchManager.removeLaunchListener(antListener)
      alert(e.message + "\n" + e.backtrace.join("\n"))
    end
  end
end

class BuildFileShell
  def initialize(project, file)
    @project = project
    @file = file
    @runner = AntRunner.new()
    @runner.buildFileLocation = file.rawLocation.toFile().absolutePath
    @targets = @runner.availableTargets.collect do |t|
      t.name
    end
  end
  
  def complete(startsWith = nil)
    return @targets if startsWith == nil
    return @targets.select do |t|
      t.index(startsWith) == 0
    end
  end
  
  def execute(target)
    TargetCmd.new(@project, @file, target).execute
  end
end

class AntShell
  def initialize(project)
    @project = project
    @buildFiles = findBuildFiles(project)
  end
  
  def complete()
    @buildFiles.collect { |b| b }
  end
  
  def execute(line)
    files = @buildFiles.select do |f|
      f.name.index(line) != -1
    end
    raise Exception.new("Too many matches: " + files) if files.size() > 1
    return BuildFileShell.new(@project, files[0])
  end
end

class Eshell
  def initialize(rootShell)
    @shell = rootShell
  end

  def runCmd(cmdLine)
    cmdLine.split(";").each { |stmt|
      runStmt(stmt.strip)
    }
  end
  
  def runStmt(stmt)
    stmt.split(" ").each { |cmd|
      puts @shell
      @shell = @shell.execute(cmd)
    }
  end
end

run {
  cmd = prompt("project: eshell\tshell: ant")
  return if cmd == nil
  begin
    Eshell.new(AntShell.new(getProject("eshell"))).runCmd(cmd)
  rescue Exception => e
    alert(e.message + "\n" + e.backtrace.join("\n"))
  end
}