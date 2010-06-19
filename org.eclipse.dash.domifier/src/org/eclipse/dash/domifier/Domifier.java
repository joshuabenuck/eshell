package org.eclipse.dash.domifier;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;

import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.dash.dom.project.Project;
import org.eclipse.jface.operation.IRunnableWithProgress;
import org.eclipse.pde.core.IModel;
import org.eclipse.pde.internal.core.PDECore;
import org.eclipse.pde.internal.core.exports.FeatureExportInfo;
import org.eclipse.pde.internal.ui.PDEPluginImages;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.progress.IProgressConstants;
import org.eclipse.ui.progress.IProgressService;

public class Domifier {
	File tempdir;

	public void create_temp_directory() throws IOException,
			InterruptedException {
		tempdir = new File("/tmp/domifier");
		if (tempdir.exists()) {
			Runtime.getRuntime().exec("rm -rf /tmp/domifier");
			Thread.sleep(1000);
		}
		tempdir.mkdir();
	}
	
	public void build_plugin_jar(Project project) throws InterruptedException, InvocationTargetException {
		IModel model = PDECore.getDefault().getModelManager().findModel(
				project.getEclipseObject());
		if (model == null)
			return;

		FeatureExportInfo info = new FeatureExportInfo();
		info.toDirectory = true;
		info.useJarFormat = true;
		info.exportSource = false;
		info.destinationDirectory = tempdir.getAbsolutePath();
		info.zipFileName = null;
		info.items = new Object[] { model };
		info.signingInfo = null;

//		final PluginExportJob job = new PluginExportJob(info);
//		job.setUser(true);
//		job.schedule();
//		job.setProperty(IProgressConstants.ICON_PROPERTY,
//				PDEPluginImages.DESC_PLUGIN_OBJ);
//		IProgressService progressService = PlatformUI.getWorkbench()
//				.getProgressService();
//		progressService.busyCursorWhile(new IRunnableWithProgress() {
//			public void run(IProgressMonitor monitor) throws InterruptedException {
//				job.join();
//			}
//		});
//
//		System.out.println(job.getResult() + " done with building");
	}
}
