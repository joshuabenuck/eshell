/*******************************************************************************
 * Copyright (c) 2005 Eclipse Foundation
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Bjorn Freeman-Benson - initial implementation
 *     Ward Cunningham - initial implementation
 *******************************************************************************/

package org.eclipse.dash.dom.project;

import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.eclipsemonkey.dom.IMonkeyDOMFactory;
import org.eclipse.jdt.core.IJavaProject;
import org.eclipse.jface.text.ITextSelection;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.IEditorInput;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.IWorkbenchPage;
import org.eclipse.ui.IWorkbenchPart;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.part.FileEditorInput;

public class ProjectDOMFactory implements IMonkeyDOMFactory {

	public Object getDOMroot() {
		ISelection selection = PlatformUI.getWorkbench()
				.getActiveWorkbenchWindow().getSelectionService()
				.getSelection();
		if( selection == null  || selection.isEmpty()) {
			return "No project selected";
		} else if (selection instanceof IStructuredSelection) {
			Object[] array = ((IStructuredSelection) selection).toArray();
			Object item1 = array[0];
			if (item1 instanceof IJavaProject) {
				IProject project = ((IJavaProject) item1).getProject();
				return new Project(project);
			} else if (item1 instanceof IResource) {
				IProject project = ((IResource) item1).getProject();
				return new Project(project);
			} else {
				return null;
			}
		} else if (selection instanceof ITextSelection) {
			ITextSelection textsel = (ITextSelection) selection;
			IWorkbenchPage page = PlatformUI.getWorkbench()
					.getActiveWorkbenchWindow().getActivePage();
			IWorkbenchPart part = page.getActiveEditor();
			if (part instanceof IEditorPart) {
				IEditorInput input = ((IEditorPart) part).getEditorInput();
				if (input instanceof FileEditorInput) {
					FileEditorInput finput = (FileEditorInput) input;
					return new Project(finput.getFile().getProject());
				} else {
					return "Unable to determine project from text \""
							+ textsel.getText() + "\"";
				}
			} else {
				return "Unable to determine project from text \""
						+ textsel.getText() + "\"";
			}
		} else {
			return "Cannot determine project from selection "
					+ selection.toString();
		}
	}
}
