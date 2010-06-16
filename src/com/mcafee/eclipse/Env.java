package com.mcafee.eclipse;

public class Env {
    private Object lastResult = null;
    private DynamicShell currentShell = null;
    private String currentProject = null;
    
    public Env() {}
    public Env(Env env) {
        this.lastResult = env.getLastResult();
        this.currentShell = env.getCurrentShell();
        this.currentProject = env.getCurrentProject();
    }
    public Object getLastResult() { return lastResult; }
    public void setLastResult(Object lr) { this.lastResult = lr; }
    public DynamicShell getCurrentShell() { return currentShell; }
    public void setCurrentShell(DynamicShell s) { this.currentShell = s; }
    public String getCurrentProject() { return currentProject; }
}
