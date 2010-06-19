package org.eclipse.dash.dom.project;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Version {
	String version;

	public Version(String v) {
		version = v;
	}
	
	public Version increment_third_digit() {
		Pattern p = Pattern.compile("(\\d+\\.\\d+\\.)(\\d+)(.*)");
		Matcher m = p.matcher(version);
		if( m.matches() ) {
			int n = Integer.parseInt(m.group(2));
			version = m.group(1) + (n+1) + m.group(3);
		}
		return this;
	}
	
	public String toString() {
		return version;
	}
}
