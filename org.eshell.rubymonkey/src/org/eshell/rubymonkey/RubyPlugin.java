/*******************************************************************************
 * Copyright (c) 2007 José Fonseca
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 *     José Fonseca - initial implementation
 *******************************************************************************/

package org.eshell.rubymonkey;

import java.net.URL;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListSet;

import org.eclipse.core.runtime.Path;
import org.eclipse.core.runtime.Platform;
import org.eclipse.eclipsemonkey.EclipseMonkeyPlugin;
import org.eclipse.eclipsemonkey.IScriptStoreListener;
import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.osgi.framework.Bundle;
import org.osgi.framework.BundleContext;

/**
 * The activator class controls the plug-in life cycle
 */
public class RubyPlugin extends AbstractUIPlugin {
    private BundleContext context = null;
    private static RubyPlugin plugin = null;
    
	/**
	 * The constructor
	 */
	public RubyPlugin() {
	    plugin = this;
	}
	
	public static RubyPlugin getDefault()
	{
	    return plugin;
	}

	public void start(BundleContext context) throws Exception {
		super.start(context);
		this.context = context;
	}
	
	public BundleContext getContext()
	{
	    return context;
	}
	
	private String getPluginRootDir() {
        try {
        	Bundle bundle = getBundle();
			URL bundleURL = Platform.find(bundle, new Path("."));
		    URL fileURL = Platform.asLocalURL(bundleURL);
	        return fileURL.getPath();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
	
    @Override
    public void stop(BundleContext context) throws Exception {
        super.stop(context);
    }
}
