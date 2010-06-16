package com.mcafee.eclipse;

import java.util.Collection;


public class RootShell implements DynamicShell {
	@Override
	public String[] completions(String name) {
		return null;
	}

	@Override
	public Object execute(Env env, String name, Collection<String> args) {
		return null;
	}

	@Override
	public String[] list() {
		return null;
	}

    @Override
    public String name() {
        // TODO Auto-generated method stub
        return null;
    }
}
