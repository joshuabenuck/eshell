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

import org.eclipse.eclipsemonkey.dom.IMonkeyDOMFactory;
import org.mozilla.javascript.Scriptable;

/**
 * @author Paul Colton (Aptana, Inc.)
 *
 */
public class EditorsDOMFactory implements IMonkeyDOMFactory {

	/**
	 * 
	 */
	public EditorsDOMFactory() {
	}

	public Object getDOMroot(Scriptable scope) {
		return new Editors(scope);
	}

    public Object getDOMroot() {
        return new Editors();
    }

}
