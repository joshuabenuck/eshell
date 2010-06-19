package com.mcafee.eclipse;

import java.util.Collection;


public interface Cmd {
    public String help();
    public Object execute(Env env, String cmd, Collection<String> args);
}
