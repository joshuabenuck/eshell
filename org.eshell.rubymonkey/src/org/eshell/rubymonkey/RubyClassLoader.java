/*******************************************************************************
 * Copyright (c) 2005-2006 Aptana, Inc.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html. If redistributing this code,
 * this entire header must remain intact.
 * 
 * Contributions:
 *    Kevin Lindsey based on code by Patrick Mueller
 *    José Fonseca - adapted for python
 *******************************************************************************/

package org.eshell.rubymonkey;

import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

import org.osgi.framework.Bundle;

/**
 * @author Kevin Lindsey based on code by Patrick Mueller
 */
public class RubyClassLoader extends ClassLoader
{
    private Map<String, Bundle> bundles = new HashMap<String, Bundle>();
	private ArrayList<Bundle> _bundles;

	/**
	 * ScriptClassLoader
	 */
	public RubyClassLoader(ClassLoader parent)
	{
		super(parent);

		this._bundles = new ArrayList<Bundle>();
	}

	/**
	 * addBundle
	 *
	 * @param bundle
	 */
	public void addBundle(Bundle bundle)
	{
//	    System.out.println("Loading bundle: " + bundle);
		if (bundle == null)
		{
			throw new IllegalArgumentException("ScriptClassLoader_Bundle_Not_Defined");
		}

		if (this._bundles.contains(bundle) == false)
		{
		    this._bundles.add(bundle);
		}
//		String packages = (String) bundle.getHeaders().get("Provide-Package");
//		if (packages != null) {
//			String[] names = packages.split(",");
//			for (String name : names) {
//				bundles.put(name, bundle);
//			}
//		}
//		packages = (String) bundle.getHeaders().get("Export-Package");
//		if (packages != null) {
//			String[] names = packages.split(",");
//			for (String name : names) {
//				bundles.put(name, bundle);
//			}
//		}
	}

	/**
	 * findClass
	 * 
	 * @param name
	 * @return Class
	 * @throws ClassNotFoundException
	 */
	@Override
	protected Class<?> findClass(String name) throws ClassNotFoundException
	{
//	    System.out.println("Finding class: " + name);
        Class<?> result = null;
        try {
            result = super.findClass(name);
        } catch(ClassNotFoundException e) {}
	    if (result != null) return result;
	    
		result = this.loadClassFromBundles(name);
		if (result != null) return result;

		String message = "ScriptClassLoader_Unable_To_Find_Class: " + name;
		throw new ClassNotFoundException(message);
	}
	
	/**
	 * findResource
	 * 
	 * @param name
	 * @return URL
	 */
	@Override
	protected URL findResource(String name)
	{
//	    System.out.println("loading resource: " + name);
		URL result = super.findResource(name);
		return result;
//		if (result != null) return result;
//		System.out.println("iterating...");
//		
//		for(Bundle bundle : _bundles)
//		{
//			result = bundle.getResource(name);
//			if (result != null)
//		    {
//			    System.out.println("found in: " + name);
//			    return result;
//		    }
//		}
//		return result;
	}

	/**
	 * findResources
	 * 
	 * @param name
	 * @return Enumeration
	 * @throws IOException
	 */
	@Override
	protected Enumeration findResources(String name) throws IOException
	{
//	    System.out.println("finding resource: " + name);
		Enumeration<?> result = super.findResources(name);

		if (result != null) return result;
//	    System.out.println("iterating");
		
		for(Bundle bundle : _bundles)
		{
			result = bundle.getResources(name);
			if (result != null) return result;
		}

		String message = "ScriptClassLoader_Unable_To_Find_Resource: " + name;
		throw new IOException(message);
	}

	/**
	 * loadClass
	 * 
	 * @param name
	 * @return Class
	 * @throws ClassNotFoundException
	 */
	@Override
	public Class<?> loadClass(String name) throws ClassNotFoundException
	{
//	    System.out.println("loading class: " + name);
        Class<?> result = null;
        try {
            result = super.loadClass(name);
        } catch(ClassNotFoundException e) {}
        if (result != null) return result;
        
        result = this.loadClassFromBundles(name);
        if (result != null) return result;
        
        String message = "ScriptClassLoader_Unable_To_Load_Class: " + name;
        throw new ClassNotFoundException(message);
	}

	/**
	 * loadClass
	 * 
	 * @param name
	 * @param resolve
	 * @return Class
	 * @throws ClassNotFoundException
	 */
	@Override
	protected synchronized Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException
	{
//        System.out.println("loading class: " + name);
	    Class<?> result = null;
	    try {
	        result = super.loadClass(name, resolve);
	    } catch(ClassNotFoundException e) {}
		if (result != null) return result;
		
		result = this.loadClassFromBundles(name);
		if (result != null) return result;
		
		String message = "ScriptClassLoader_Unable_To_Load_Class: " + name;
		throw new ClassNotFoundException(message);
	}

	/**
	 * loadClassFromBundles
	 * 
	 * @param name
	 * @return Class
	 * @throws ClassNotFoundException
	 */
	private Class<?> loadClassFromBundles(String name) throws ClassNotFoundException
	{
	    for (Bundle bundle : _bundles)
	    {
	        try
	        {
	            Class<?> result = bundle.loadClass(name);
	            if (result != null) return result;
	        }
	        catch(ClassNotFoundException e) {}
	    }
//	    String name = originalName;
//	    while(name.indexOf(".") != -1)
//	    {
//	        Bundle bundle = bundles.get(name);
//	        if (bundle != null) return bundle.loadClass(name);
//	        name = name.substring(0, name.lastIndexOf("."));
//	    }
	    throw new ClassNotFoundException("Unable to load class: " + name);
	}
}

