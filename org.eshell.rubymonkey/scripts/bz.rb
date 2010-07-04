# Menu: Open BZ
# Key: M3+Q

require 'prelude'
addBundles([
  "org.eclipse.ui"
])

$state["bz_url"] = "https://bugs.eclipse.org/bugs/"

alert("No bz_url defined!") and 
  return if $state["bz_url"] == nil
bzUrl = $state["bz_url"]
bz = prompt("Please enter BZ number: ")
return if bz == nil
java_import org.eclipse.ui.PlatformUI
support = PlatformUI.workbench.browserSupport
support.createBrowser("bz").openURL(
  java.net.URL.new(bzUrl + "show_bug.cgi?id=" + bz))