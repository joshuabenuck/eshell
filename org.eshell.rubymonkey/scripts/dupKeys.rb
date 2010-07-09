# Menu: Mark Duplicate Keys
# Key: M3+R
require 'prelude'

addBundles([
  "org.eclipse.ui",
  "org.eclipse.core.resources"
])
java_import org.eclipse.ui.PlatformUI
java_import org.eclipse.core.resources.IResource

class DupKeysCmd
  def execute(env, cmd)
    return nil if cmd != "dupKeys"
    input = display {
      PlatformUI.workbench.activeWorkbenchWindow.
        activePage.activeEditor.editorInput
    }
    if input.name.index(".properties") == nil
      alert(input.name + " is not a properties file.")
      return true
    end
    resource = input.getAdapter(IResource.java_class)
    reader = java.io.BufferedReader.new(
      java.io.InputStreamReader.new(resource.contents))
    keys = {}
    while reader.ready do
      line = reader.readLine.strip
      next if line.size() == 0
      next if line.index("#") != nil
      if line.index("=") != nil
        (key, value) = line.split("=").collect {|i| i.strip}
        alert("Duplicate key: " + key) if keys.has_key?(key)
        keys[key] = value
      end
    end
    return true
  end
end

if $0 == __FILE__
  DupKeysCmd.new.execute(nil, "dupKeys")
  alert("Done!")
end