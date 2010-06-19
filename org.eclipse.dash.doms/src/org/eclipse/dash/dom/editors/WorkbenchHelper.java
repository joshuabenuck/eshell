/**
 * Copyright (c) 2005-2006 Aptana, Inc.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html. If redistributing this code,
 * this entire header must remain intact.
 */
package org.eclipse.dash.dom.editors;


import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.Platform;
import org.eclipse.core.runtime.content.IContentType;
import org.eclipse.jface.viewers.LabelProvider;
import org.eclipse.ui.IEditorDescriptor;
import org.eclipse.ui.IEditorInput;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.IEditorReference;
import org.eclipse.ui.IEditorRegistry;
import org.eclipse.ui.IPathEditorInput;
import org.eclipse.ui.IViewPart;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.IWorkbenchPage;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.PartInitException;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.browser.IWebBrowser;
import org.eclipse.ui.browser.IWorkbenchBrowserSupport;
import org.eclipse.ui.editors.text.EditorsUI;
import org.eclipse.ui.part.FileEditorInput;

/**
 * Utility classes for accessing parts of the workbench.
 * 
 * @author Ingo Muschenetz
 */
public final class WorkbenchHelper
{
	/**
	 * Private constructor for utility class
	 */
	private WorkbenchHelper()
	{

	}

	/**
	 * Show a specific view
	 * 
	 * @param viewId
	 *            The ID of the view to show
	 * @param window
	 *            The active window
	 * @return The IViewPart of the activated view.
	 * @throws PartInitException
	 */
	public static IViewPart showView(String viewId, IWorkbenchWindow window) throws PartInitException
	{
		IWorkbenchPage page = window.getActivePage();
		if (page != null)
		{
			return page.showView(viewId);
		}
		return null;
	}

	/**
	 * Find a specific view
	 * 
	 * @param viewId
	 *            The ID of the view to show
	 * @param window
	 *            The active window
	 * @return The IViewPart of the activated view.
	 * @throws PartInitException
	 */
	public static IViewPart findView(String viewId, IWorkbenchWindow window) throws PartInitException
	{
		IWorkbenchPage page = window.getActivePage();
		if (page != null)
		{
			return page.findView(viewId);
		}
		return null;
	}

	/**
	 * Open a file in the workbench
	 * 
	 * @param file
	 *            The file to open
	 * @param window
	 *            The active window
	 * @return The IEditorPart of the opened file
	 */
//	public static IEditorPart openFile(File file, IWorkbenchWindow window)
//	{
//		return new OpenFileHelper(window).open(file);
//	}

	/**
	 * Open a file in the workbench
	 * 
	 * @param editorID
	 *            The editor to use in opening the file
	 * @param file
	 *            The file to open
	 * @param window
	 *            The active window
	 * @return The IEditorPart of the opened file
	 */
//	public static IEditorPart openFile(String editorID, File file, IWorkbenchWindow window)
//	{
//		return new OpenFileHelper(window).open(editorID, file);
//	}

	/**
	 * Open a file in the workbench
	 * 
	 * @param file
	 *            The file to open
	 * @param window
	 *            The active window
	 * @return The IEditorPart of the opened file
	 */
	public static IEditorPart openFile(IFile file, IWorkbenchWindow window)
	{
		return new OpenFileHelper(window).open(file);
	}

	/**
	 * Open a file in the workbench
	 * 
	 * @param editorID
	 *            The editor to use in opening the file
	 * @param file
	 *            The file to open
	 * @param window
	 *            The active window
	 * @return The IEditorPart of the opened file
	 */
	public static IEditorPart openFile(String editorID, IFile file, IWorkbenchWindow window)
	{
		return new OpenFileHelper(window).open(editorID, file);
	}

	/**
	 * Open a url in a browser
	 * 
	 * @param url
	 *            The URL to open
	 */
	public static void launchBrowser(String url)
	{
		BrowserLaunchHelper.launchBrowser(url);
	}
}

/**
 * Utility class for launching a browser from a specific URL
 * 
 * @author Ingo Muschenetz
 */
final class BrowserLaunchHelper
{
	/**
	 * Private constructor for utility class
	 */
	private BrowserLaunchHelper()
	{

	}

	static void launchBrowser(String url)
	{
		IWorkbenchBrowserSupport support = PlatformUI.getWorkbench().getBrowserSupport();
		try
		{
			IWebBrowser browser = support.getExternalBrowser();
			String urlEncoded = StringUtils.urlEncodeForSpaces(url.toCharArray());
			browser.openURL(new URL(urlEncoded)); //$NON-NLS-1$
		}
		catch (MalformedURLException e)
		{
			System.err.println("Error: " + e);
		}
		catch (PartInitException e)
		{
			System.err.println("Error: " + e);
		}
	}
}

/**
 * Utility class for launching a opening a file in an editor
 * 
 * @author Ingo Muschenetz
 */
class OpenFileHelper
{
	IWorkbenchWindow window;

	OpenFileHelper(IWorkbenchWindow window)
	{
		this.window = window;
	}

	/**
	 * Open the specified file in the Workbench. If the file is already open, it will be activated
	 * instead.
	 * 
	 * @param file
	 * @return The editor editing the opened file
	 */
//	public IEditorPart open(File file)
//	{
//		String editorId = getEditorId(new FileInput(file));
//		return open(editorId, file);
//	}

	/**
	 * Open the specified file in the Workbench. If the file is already open, it will be activated
	 * instead.
	 * 
	 * @param file
	 * @return The editor editing the opened file
	 */
	public IEditorPart open(IFile file)
	{
		String editorId = getEditorId(new ResourceFileInput(file));
		return open(editorId, file);
	}

	/**
	 * Open the specified file in the Workbench. If the file is already open, it will be activated
	 * instead.
	 * 
	 * @param editorID
	 *            The editor to use in editing the file
	 * @param file
	 * @return The editor editing the opened file
	 */
	public IEditorPart open(String editorID, IFile file)
	{
		IEditorInput input = createEditorInput(file);
		return open(editorID, input);
	}

	/**
	 * Open the specified file in the Workbench. If the file is already open, it will be activated
	 * instead.
	 * 
	 * @param editorID
	 *            The editor to use in editing the file
	 * @param file
	 * @return The editor editing the opened file
	 */
//	public IEditorPart open(String editorID, File file)
//	{
//		IEditorInput input = createEditorInput(file);
//		return open(editorID, input);
//	}

	private IEditorPart open(String editorId, IEditorInput input)
	{
		try
		{
			IWorkbenchPage page = window.getActivePage();

			// only open new instance if there isn't one open already
			if (input instanceof IPathEditorInput)
			{
				IWorkbenchPage[] pages = window.getPages();
				for (int i = 0; i < pages.length; i++)
				{
					IEditorReference[] refs = pages[i].getEditorReferences();
					for (int j = 0; j < refs.length; j++)
					{
						IEditorInput editorInput;
						try
						{
							editorInput = refs[j].getEditorInput();
							if (editorInput instanceof IPathEditorInput)
							{
								IPathEditorInput pathFileInput = (IPathEditorInput) editorInput;
								String path = pathFileInput.getPath().toOSString();
								if (path.equalsIgnoreCase(((IPathEditorInput) input).getPath().toOSString()))
								{
									IEditorPart editorPart = refs[j].getEditor(true);
									// activate the editor in the current page
									page.activate(editorPart);
								}
							}
						}
						catch (PartInitException e)
						{
							System.err.println("Error: EditorPartCannotBeActivated: " + editorId + ": " + e);
						}
					}
				}
			}
			// there is no editor open for the given file, so open a new one
			try
			{
				return page.openEditor(input, editorId);
			}
			catch (PartInitException e)
			{
				System.err.println("Error: EditorPartCannotBeOpened: " + editorId + ": " + e);
			}
		}
		catch (Exception e)
		{
			System.err.println("Error: ErrorOpeningEditor: " + editorId + ": " + e);
		}

		return null;
	}

//	private IEditorInput createEditorInput(File file)
//	{
//		IFile workspaceFile = getWorkspaceFile(file);
//		if (workspaceFile != null)
//		{
//			// let the workbench open the workspace file, reactivating if its already open
//			return new FileEditorInput(workspaceFile);
//		}
//		else
//		{
//			// open the file manually (it won't really be loaded as Java)
//			// just like the OpenExternalFileAction does.
//			IEditorInput input = createJavaFileEditorInput(file);
//			return input;
//		}
//
//	}

	private IEditorInput createEditorInput(IFile file)
	{
		// let the workbench open the workspace file, reactivating if its already open
		return new FileEditorInput(file);
	}

	private String getEditorId(EditorFileInput file)
	{
		try
		{
			IWorkbench workbench = window.getWorkbench();
			IEditorRegistry editorRegistry = workbench.getEditorRegistry();
			IEditorDescriptor descriptor = editorRegistry.getDefaultEditor(file.getName(), getContentType(file));
			if (descriptor != null)
			{
				return descriptor.getId();
			}

			return EditorsUI.DEFAULT_TEXT_EDITOR_ID;
		}
		catch (Exception x)
		{
			System.err.println("Error: ErrorGettingEditorId: " + x);
			return EditorsUI.DEFAULT_TEXT_EDITOR_ID;
		}
	}

//	private IFile getWorkspaceFile(File file)
//	{
//		try
//		{
//			IWorkspace workspace = ResourcesPlugin.getWorkspace();
//			IPath location = Path.fromOSString(file.getAbsolutePath());
//			IFile[] files = workspace.getRoot().findFilesForLocation(location);
//			files = filterNonExistentFiles(files);
//			if (files == null || files.length == 0)
//			{
//				return null;
//			}
//			if (files.length == 1)
//			{
//				return files[0];
//			}
//			return selectWorkspaceFile(files);
//		}
//		catch (Exception e)
//		{
//			System.err.println("Error: getWorkspaceFile: " + e.getMessage()); //$NON-NLS-1$
//			return null;
//		}
//	}

	private IContentType getContentType(EditorFileInput file)
	{
		if (file == null)
		{
			return null;
		}

		InputStream stream = null;
		try
		{
			// [RD] bugfix - assigning inputStream to stream
			stream = file.getInputStream();
			return Platform.getContentTypeManager().findContentTypeFor(stream, file.getName());
		}
		catch (Exception x)
		{
			System.err.println("Error: ErrorGettingInputStreamFromFile: " + x);
			return null;
		}
		finally
		{
			try
			{
				if (stream != null)
				{
					stream.close();
				}
			}
			catch (IOException x)
			{
				System.err.println("Error: ErrorClosingInputStream: " + x);
			}
		}
	}

	private IFile[] filterNonExistentFiles(IFile[] files)
	{
		if (files == null)
		{
			return null;
		}

		int length = files.length;
		ArrayList existentFiles = new ArrayList(length);
		for (int i = 0; i < length; i++)
		{
			if (files[i].exists())
			{
				existentFiles.add(files[i]);
			}
		}
		return (IFile[]) existentFiles.toArray(new IFile[existentFiles.size()]);
	}

//	private IFile selectWorkspaceFile(IFile[] files)
//	{
//		ElementListSelectionDialog dialog = new ElementListSelectionDialog(window.getShell(), new FileLabelProvider());
//		dialog.setElements(files);
//		dialog.setTitle(Messages.WorkbenchHelper_ElementListSelectionDialogTitle);
//		dialog.setMessage(Messages.WorkbenchHelper_ElementListSelectionDialogMessage);
//		if (dialog.open() == Window.OK)
//		{
//			return (IFile) dialog.getFirstResult();
//		}
//		return null;
//	}

	/**
	 * Provides labels for IFile
	 * 
	 * @author Ingo Muschenetz
	 */
	static class FileLabelProvider extends LabelProvider
	{
		/**
		 * @see org.eclipse.jface.viewers.LabelProvider#getText(java.lang.Object)
		 */
		public String getText(Object element)
		{
			if (element instanceof IFile)
			{
				IPath path = ((IFile) element).getFullPath();
				return path != null ? path.toString() : ""; //$NON-NLS-1$
			}
			return super.getText(element);
		}
	}

	/**
	 * Defines an EditorFileInput
	 * 
	 * @author Ingo Muschenetz
	 */
	private interface EditorFileInput
	{
		/**
		 * Get the name of the file
		 * 
		 * @return The file name
		 */
		String getName();

		/**
		 * Returns the input stream of the edited file
		 * 
		 * @return The input stream
		 * @throws Exception
		 */
		InputStream getInputStream() throws Exception;
	}

	/**
	 * Defines a file input
	 * 
	 * @author Ingo Muschenetz
	 */
	private static class FileInput implements EditorFileInput
	{
		private File file;

		FileInput(File f)
		{
			setFile(f);
		}

		/**
		 * Get the name of the file
		 * 
		 * @return The file name
		 */
		public String getName()
		{
			return getFile().getName();
		}

		/**
		 * Returns the input stream of the edited file
		 * 
		 * @return The input stream
		 * @throws Exception
		 */
		public InputStream getInputStream() throws Exception
		{
			return new FileInputStream(getFile());
		}

		/**
		 * @param file
		 *            The file to set.
		 */
		void setFile(File file)
		{
			this.file = file;
		}

		/**
		 * @return Returns the file.
		 */
		File getFile()
		{
			return file;
		}
	}

	/**
	 * Provides a wrapper for resource files
	 * 
	 * @author Ingo Muschenetz
	 */
	private static class ResourceFileInput implements EditorFileInput
	{
		private IFile file;

		ResourceFileInput(IFile f)
		{
			setFile(f);
		}

		/**
		 * Get the name of the file
		 * 
		 * @return The file name
		 */
		public String getName()
		{
			return getFile().getName();
		}

		/**
		 * Returns the input stream of the edited file
		 * 
		 * @return The input stream
		 * @throws Exception
		 */
		public InputStream getInputStream() throws Exception
		{
			return getFile().getContents();
		}

		/**
		 * @param file
		 *            The file to set.
		 */
		void setFile(IFile file)
		{
			this.file = file;
		}

		/**
		 * @return Returns the file.
		 */
		IFile getFile()
		{
			return file;
		}
	}
}
