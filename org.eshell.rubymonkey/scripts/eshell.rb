# Menu: eshell
# Key: M3+Z

require 'java'
require 'prelude'
require 'bz'
require 'dupKeys'
addBundles(
  ["org.eclipse.ui.console",
   "org.eclipse.ui",
  ])

java_import org.eclipse.ui.console.ConsolePlugin
java_import org.eclipse.ui.PlatformUI

# Must not be run in UI thread!
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
  
  def execute(env, target)
    return nil if complete(target).size == 0
    antListener = AntListener.new(@file)
    begin
      DebugPlugin.default.launchManager.addLaunchListener(antListener)
      AntLaunchShortcut.new().launch(@file.fullPath, 
        @project.getProject(), 
        ILaunchManager.RUN_MODE, target)
      antListener.complete.await
      return true
    rescue Exception => e
      DebugPlugin.default.launchManager.removeLaunchListener(antListener)
      alert(e.message + "\n" + e.backtrace.join("\n"))
    end
  end
end

class AntShell
  def complete()
    @buildFiles.collect { |b| b }
  end
  
  def execute(env, line)
    return nil if line.index("ant ") != 0
    project = env["project"]
    @buildFiles = findBuildFiles(project)
    line = line.split(" ")[1]
    files = @buildFiles.select do |f|
      f.to_s.index(line) != nil
    end
    raise Exception.new("Too many matches: " + files) if files.size() > 1
    return nil if files.size() == 0
    return BuildFileShell.new(project, files[0])
  end
end

addBundles(["org.eclipse.wst.server.core",
            "org.eclipse.debug.core"])
java_import org.eclipse.wst.server.core.ServerCore
java_import org.eclipse.debug.core.ILaunchManager
class ServerShell
  def execute(env, cmd)
    return nil if cmd.index("server ") != 0
    project = env["project"]
    parts = cmd.split(" ")
    action = parts[1]
    server = nil; server = parts[2] if parts.length > 2
    return start(project, server) if action == "start"
    return stop(project, server) if action == "stop"
    return nil
  end
  
  def start(project, server = nil)
    location = project == nil ? "unknown" : project.project.rawLocation.to_s
    matches = ServerCore.servers.select { |s| s.runtime.location.to_s.index(location) == 0 || s.name == server}
    raise Exception.new("Too many servers match the active project: " + matches.to_s) if matches.length > 1
    raise Exception.new("No servers match the active project: " + location) if matches.length == 0
    matches[0].synchronousStart(ILaunchManager.DEBUG_MODE, nil)
    return true
  end
  
  def stop(project, server = nil)
    location = project == nil ? "unknown" : project.project.rawLocation.to_s
    matches = ServerCore.servers.select { |s| s.runtime.location.to_s.index(location) == 0 || s.name == server }
    raise Exception.new("Too many servers match the active project: " + matches.to_s) if matches.length > 1
    raise Exception.new("No servers match the active project: " + location) if matches.length == 0
    matches[0].synchronousStop(false)
    return true
  end
end

class PathVar
  def name()
    return "path"
  end
  
  def convert(value)
    return value
  end
end

class ProjectVar
  def name()
    return "project"
  end
  
  def convert(value)
    proj = getProject(value)
    raise "Unknown project: " + value if proj == nil
    return proj
  end
end

class SetCmd
  @@vars = {}
  def self.register(setVar)
    @@vars[setVar.name] = setVar
  end
  
  def execute(env, cmd)
    return nil unless cmd.index("set ") == 0
    parts = cmd.split(" ")
    parts.shift; name = parts.shift
    value = parts.shift
    while parts.length > 0
      value += " #{parts.shift}"
    end
    if value == nil
      $state.remove(name)
      return true
    end 
    var = @@vars[name]
    raise "Unknown environment variable: " + name if var == nil
    env[name] = var.convert(value)
    $state[name] = value
    return true
  end
end

# Keep track of current path and rerun it to restore state.
# This allows us to not store ruby objects in the plugin's state.
class Eshell
  def initialize()
    SetCmd.register(ProjectVar.new)
    SetCmd.register(BzUrlVar.new)
    SetCmd.register(PathVar.new)
    @shells = [self]
    @path = ""
    @env = {}
    #$state.keys.each {|k| $state.remove(k) }
  $state.keys.each {|k| runStmt("set #{k} #{$state[k]}", [self]) }
    #@env["project"] = getProject($state["project"]) if $state["project"] != nil
    #@env["path"] = $state["path"] unless $state["path"] == nil
    begin
      runCmd(@env["path"]) unless @env["path"] == nil
    rescue Exception => e
      @env["path"] = $state["path"] = ""
      @shells = [self]
    end
  end
  
  def env() return @env; end
  def path() return @path; end

  def runCmd(cmdLine)
    cmdLine.split(";").each { |stmt|
      (path, shells) = runStmt(stmt.strip, @shells.clone)
      @shells = @shells | shells and @path += path + " " if shells != nil
    }
    @env["path"] = $state["path"] = @path = @path.strip
  end
  
  def runStmt(stmt, shells)
    raise "No such cmd: " + stmt if shells.length == 0
    shell = shells.last
    resultWasShell = false
    result = shell.execute(@env, stmt)
    if result == nil
      shells.pop
      (ignored, tmp) = runStmt(stmt, shells)
      result = tmp == nil ? nil : tmp[0]
    end
    if result.class.name =~ /Shell$/
      shells.push(result)
      resultWasShell = true
    end
    return [stmt, shells] if resultWasShell
    return [nil, nil]
  end
  
  def cp(env, cmd)
    return nil unless cmd.index("cp ") == 0
    name = cmd.split(" ")[1]
    project = getProject(name)
    raise "Unable to find project named: " + name if project == nil 
    raise "Non-Java project: " + name if !project.respond_to?("getNonJavaResources")
    env["project"] = project
    $state["project"] = name
    return true
  end
  
  def execute(env, cmd)
    result = cp(env, cmd)
    return result unless result == nil
    [
      SetCmd.new,
      AntShell.new,
      ServerShell.new,
      BzCmd.new,
      DupKeysCmd.new
    ].each { |s|
      result = s.execute(env, cmd)
      return result unless result == nil
    }
    return nil
  end
end

_run {
begin
  Eshell.new().runCmd("cp eshell; ant eshell; cp org.eclipse.dash.doms; ant build.xml; init")
  Eshell.new().runCmd("cp org.eclipse.dash.doms; ant build.xml")
rescue Exception => e
  alert(e.message + "\n" + e.backtrace.join("\n"))
end
}

run {
  begin
    eshell = Eshell.new
    projectName = eshell.env["project"] == nil ? "" : eshell.env["project"].project.description.name.to_s
    cmd = prompt("project: " + projectName + 
                 "\tshell: " + eshell.path)
    return if cmd == nil
    eshell.runCmd(cmd)
  rescue Exception => e
    alert(e.message + "\n" + e.backtrace.join("\n"))
  end
}