package com.mcafee.eclipse;

import java.util.Arrays;
import java.util.Deque;
import java.util.LinkedList;

public class ShellE {
    private Env env = new Env();

    public ShellE(DynamicShell root) {
        this.env = new Env();
        env.setCurrentShell(root);
    }
    
    public String[] complete(String line) {
        return null;
    }
    
    // Change this to use an Env instead. Pass around a copy between statements
    // and only preserve the switched shell if chaining.
    public Object run(String line) {
        Env tmp = new Env(env);
        String statements[] = line.split(";");
        for (String stmt : statements) {
            tmp = processStatement(stmt, tmp);
            if (!(tmp.getLastResult() instanceof DynamicShell)) continue;
            env.setCurrentShell((DynamicShell) tmp.getLastResult());
        }
        return tmp.getLastResult();
    }

    private Env processStatement(String stmt, Env env) {
        Object tmp = env.getCurrentShell();
        Deque<String> cmds = new LinkedList<String>(Arrays.asList(stmt.split(" ")));
        while(!cmds.isEmpty())
        {
            String cmd = cmds.pop();
            tmp = env.getCurrentShell().execute(env, cmd, cmds);
            env.setLastResult(tmp);
            if (!(tmp instanceof DynamicShell)) continue;
            env.setCurrentShell((DynamicShell) tmp);
        }
        return env;
    }
}
