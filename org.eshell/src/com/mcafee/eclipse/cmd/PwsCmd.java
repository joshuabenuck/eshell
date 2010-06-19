package com.mcafee.eclipse.cmd;

import java.util.Collection;

import com.mcafee.eclipse.Cmd;
import com.mcafee.eclipse.Env;

public class PwsCmd implements Cmd {

    @Override
    public Object execute(Env env, String cmd, Collection<String> args) {
        return env.getCurrentShell().name();
    }

    @Override
    public String help() {
        return "Prints the working shell.";
    }

}
