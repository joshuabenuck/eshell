# Menu: eshell example
# Key: M3+R

require 'java'
require 'eshell'

$vimPath = "c:/windows/gvim.bat"
$bzUrl = "https://bugs.eclipse.org/bugs/"
$clipboardPath = "c:/src/clipboard"
register(:eshell, buildShell("build.xml", [:test, :dist]))

run_shell()