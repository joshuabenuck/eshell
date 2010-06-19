/*
 * Menu: eshell> ant
 * Key: M3+A
 * DOM: http://download.eclipse.org/technology/dash/update/org.eclipse.eclipsemonkey.lang.javascript
 * DOM: http://muellerware.org/projects/em-sl/update/org.muellerware.eclipsemonkey.dom.scriptloader
 * @requires-bundle org.eclipse.jdt.core
*/

function main() {
	alert(Packages.org.eclipse.ui.console.ConsolePlugin);
	var JavaCore = ScriptLoader.loadProjectFile("eshell", "scripts/lib/java.js");
	alert(JavaCore);
	var ResourcesPlugin = Packages.org.eclipse.core.resources.ResourcesPlugin;
	var PlatformUI = Packages.org.eclipse.ui.PlatformUI;
	var MessageDialog = Packages.org.eclipse.jface.dialogs.MessageDialog;
	
	var javaProjects = Packages.org.eclipse.jdt.core.JavaCore.create(ResourcesPlugin.getWorkspace().getRoot()).getJavaProjects();
	for (i in javaProjects)
	{
		alert(javaProjects[i].getProject().getDescription().getName());
	}
	
	//var views = PlatformUI.getWorkbench().getActiveWorkbenchWindow().getActivePage().getViewReferences();
	//for (i in views)
	//{
		//if(views[i].getId() == "org.eclipse.ant.ui.views.AntView") 
		//if(views[i].getId() == "org.eclipse.jdt.ui.PackageExplorer") alert(views[i].getView(true));
		
		//alert(views[i].getId());
	//}
	
	/*MessageDialog.openInformation( 	
			window.getShell(), 	
			"Monkey Dialog", 
			views.getView("AntView")
			)*/
}