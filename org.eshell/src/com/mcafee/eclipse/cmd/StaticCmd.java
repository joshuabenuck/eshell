package com.mcafee.eclipse.cmd;

import java.util.Collection;

import com.mcafee.eclipse.Cmd;
import com.mcafee.eclipse.Env;

public class StaticCmd implements Cmd {
    private Object result;
    
    public StaticCmd(Object result)
    {
        this.result = result;
    }
    
    @Override
    public Object execute(Env env, String cmd, Collection<String> args) {
        return result;
    }

    @Override
    public String help() {
        return "Returns a static object.";
    }

}
