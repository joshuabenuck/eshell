package org.eclipse.dash.domifier;

import org.eclipse.eclipsemonkey.dom.IMonkeyDOMFactory;

public class DomifierDOMFactory implements IMonkeyDOMFactory {

	public Object getDOMroot() {
		return new Domifier();
	}

}
