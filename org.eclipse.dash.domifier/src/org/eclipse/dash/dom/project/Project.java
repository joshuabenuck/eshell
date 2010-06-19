package org.eclipse.dash.dom.project;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringBufferInputStream;
import java.util.jar.Attributes;
import java.util.jar.Manifest;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.dash.dom.resources.File;
import org.eclipse.update.internal.model.BundleManifest;

public class Project {
	IProject project;

	Attributes attributes = null;

	public Project(IProject p) {
		super();
		project = p;
	}

	public IProject getEclipseObject() {
		return project;
	}

	public Object createFile(String fileName) {
		IFile file = (IFile) (project.getFile(fileName));
		InputStream is = new StringBufferInputStream("");
		try {
			file.create(is, true, null);
		} catch (CoreException x) {
			return x.toString();
		}
		return new File(file);
	}

	public String name() {
		return project.getName();
	}

	public String id() throws CoreException, IOException {
		return manifestAttributes().getValue("Bundle-SymbolicName");
	}

	public Version version() throws CoreException, IOException {
		String version = manifestAttributes().getValue("Bundle-Version");
		if (version == null)
			return new Version("0.0.0");
		return new Version(version);
	}

	public String provider() throws CoreException, IOException {
		String vendor = manifestAttributes().getValue("Bundle-Vendor");
		if (vendor == null)
			return "no provider";
		return vendor;
	}

	public Attributes manifestAttributes() throws CoreException, IOException {
		if (attributes != null)
			return attributes;
		Manifest m = new Manifest(project.getFile("META-INF/MANIFEST.MF")
				.getContents());
		attributes = m.getMainAttributes();
		return attributes;
	}
}
