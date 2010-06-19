package com.mcafee.eclipse;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

public class DefaultDynamicShell implements DynamicShell {
    private String name;
    private DynamicShell parent;
    private Map<String, Cmd> cmds = new HashMap<String, Cmd>();
    
    public DefaultDynamicShell(String name, DynamicShell parent) {
        this.name = name;
        this.parent = parent;
    }
    
    @Override
    public String name() {
        return name;
    }

    @Override
    public String[] completions(String name) {
        return null;
    }

    @Override
    public Object execute(Env env, String name, Collection<String> args) {
        Cmd cmd = cmds.get(name);
        if (cmd == null) {
            if (parent == null) {
                throw new NullPointerException("Unable to find cmd named: " + name);
            } else { return parent.execute(env, name, args); }
        }
        return cmd.execute(env, name, args);
    }

    @Override
    public String[] list() {
        return cmds.keySet().toArray(new String[0]);
    }

    public void register(String name, Cmd cmd)
    {
        cmds.put(name, cmd);
    }
    
    public void unregister(String name)
    {
        cmds.remove(name);
    }
}
