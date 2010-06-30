# Menu: eshell
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
      return true
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
    return nil if complete(target).size == 0
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
      f.to_s.index(line) != nil
    end
    raise Exception.new("Too many matches: " + files) if files.size() > 1
    return nil if files.size() == 0
    return BuildFileShell.new(@project, files[0])
  end
end

# Will be use as the root shell for most commands.
class ProjectShell
  def initialize(project)
    @project = project
    @cmds = {
      "ant" => AntShell.new(project)
    }
  end
  
  def execute(cmd)
    return @cmds[cmd]
  end
end

class CpShell
  def execute(name)
    project = getProject(name)
    return nil if project == nil
    return nil if !project.respond_to?("getNonJavaResources")
    return ProjectShell.new(project)
  end
end

# Keep track of current path and rerun it to restore state.
# This allows us to not store ruby objects in the plugin's state.
class Eshell
  def initialize()
    @shell = self
    @shells = [self]
    @path = ""
  end

  def runCmd(cmdLine)
    cmdLine.split(";").each { |stmt|
      (path, shells) = runStmt(stmt.strip, @shells)
      @shells = @shells | shells and @path += path + " " if shells != nil
    }
    @path = @path.strip
    alert(@path)
  end
  
  def runStmt(stmt, shells)
    raise "No such cmd: " + stmt if shells.length == 0
    lastWasShell = false
    parts = stmt.split(" ")
    parts.each { |cmd|
      shell = shells.last
      lastWasShell = false
      result = shell.execute(cmd)
      if result == nil
        shells.pop
        (ignored, tmp) = runStmt(cmd, shells)
        tmp = shells[0]
      end
      if result.class.name =~ /Shell$/
        shells.push(result)
        lastWasShell = true
      else break
      end
    }
    return [stmt, shells] if lastWasShell
    return [nil, nil]
  end
  
  def execute(cmd)
    return CpShell.new() if cmd == "cp"
    return list() if cmd == "ls"
    return CpShell.new().execute("ls") if cmd == "lp"
    return nil
  end
end

# cp eshell ant eshell
# cp eshell; ant; eshell; dist; test
# ant eshell dist test
# ant ls -- should this search parent shells? No?
# SubShells cannot be the current shell and can only be used absolutely?
# when to search parent shells?

run {
begin
  Eshell.new().runCmd("cp eshell ant eshell")
  Eshell.new().runCmd("cp org.eclipse.dash.doms; ant build.xml")
rescue Exception => e
  alert(e.message + "\n" + e.backtrace.join("\n"))
end
}

_run {
  cmd = prompt("project: eshell\tshell: ant")
  return if cmd == nil
  begin
    Eshell.new().runCmd(cmd)
  rescue Exception => e
    alert(e.message + "\n" + e.backtrace.join("\n"))
  end
}