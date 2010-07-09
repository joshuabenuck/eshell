require 'prelude'
addBundles([
  "org.eclipse.ui"
])

java_import org.eclipse.ui.PlatformUI
class UrlCmd
  def initialize(name="url")
    @name = name
  end
  
  def promptForUrl()
    url = prompt("Please enter url: ")
    return url
  end
  
  def getUrl(cmd)
    return cmd.split(" ")[1]
  end
  
  def execute(env, cmd)
    return nil if cmd.index(@name) != 0
    url = cmd.length == 2 ? promptForUrl() : getUrl(cmd)
    return true if url == nil
    url = "http://#{url}" if url.index("http://") != 0
    support = PlatformUI.workbench.browserSupport
    display {
      support.createBrowser(@name).openURL(
        java.net.URL.new(url))
    }
    return true
  end
end

class DefCmd < UrlCmd
  def initialize()
    super("def")
  end

  def getUrl(cmd)
    word = super(cmd)
    return "http://google.com/search?q=define:+#{word}"
  end  
end

if $0 == __FILE__
  UrlCmd.new.execute(nil, "url")
else
  # Register UrlCmd
end