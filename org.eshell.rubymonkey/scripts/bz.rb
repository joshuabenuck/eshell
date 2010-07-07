# Menu: Open BZ
# Key: M3+Q

require 'prelude'
addBundles([
  "org.eclipse.ui"
])

#$state["bz_url"] = "https://bugs.eclipse.org/bugs/"
class BzUrlVar
  def name()
    return "bz_url"
  end
  
  def convert(value)
    return java.net.URL.new(value)
  end
end
  
java_import org.eclipse.ui.PlatformUI
class BzCmd
  def getUrl()
    alert("No bz_url defined!") and 
      return if $state["bz_url"] == nil
    return $state["bz_url"]
  end
  
  def promptForBz()
    bz = prompt("Please enter BZ number: ")
    return bz
  end
  
  def getBz(cmd)
    return cmd.split(" ")[1]
  end
  
  def execute(env, cmd)
    return nil if cmd.index("bz") != 0
    bzUrl = getUrl()
    return true if bzUrl == nil
    bz = cmd.length == 2 ? promptForBz() : getBz(cmd)
    return true if bz == nil
    support = PlatformUI.workbench.browserSupport
    display {
      support.createBrowser("bz").openURL(
        java.net.URL.new(bzUrl + "show_bug.cgi?id=" + bz))
    }
    return true
  end
end

if $0 == __FILE__
  BzCmd.new.execute(nil, "bz")
else
  # Register BzCmd
end