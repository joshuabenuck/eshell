#
# Menu: Find System Prints
# Kudos: Bjorn Freeman-Benson & Ward Cunningham
# License: EPL 1.0
# DOM: http://download.eclipse.org/technology/dash/update/org.eclipse.eclipsemonkey.doms
#
  
files = resources.filesMatching('.*\\.java')
for file in files:
	file.removeMyTasks()
	for line in file.lines:
		if line.getString().find('System.out.print') != -1:
			line.addMyTask(line.getString().strip())

window.getActivePage().showView('org.eclipse.ui.views.TaskList')
