package com.mcafee.eclipse;

import java.util.Collection;

public interface DynamicShell {
    public String name();
	public String[] list();
	public String[] completions(String name);
	public Object execute(Env env, String name, Collection<String> args);
}
