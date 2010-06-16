package com.mcafee.eclipse;

import junit.framework.TestCase;

import com.mcafee.eclipse.cmd.PwsCmd;
import com.mcafee.eclipse.cmd.StaticCmd;

public class ShellETest extends TestCase {
    private DefaultDynamicShell root = new DefaultDynamicShell("/", null);
    private DefaultDynamicShell ant = new DefaultDynamicShell("ant", root);
    private DefaultDynamicShell server = new DefaultDynamicShell("server", root);
    
	@Override
    protected void setUp() throws Exception {
	    ant.register("core", getBuildShell("core"));
	    ant.register("scheduler", getBuildShell("scheduler"));
	    server.register("start", new StaticCmd("start"));
	    server.register("stop", new StaticCmd("stop"));
	    root.register("ant", new StaticCmd(ant));
	    root.register("server", new StaticCmd(server));
	    root.register("pws", new PwsCmd());
    }
	
	public Cmd getBuildShell(String name)
	{
	    DefaultDynamicShell shell = new DefaultDynamicShell(name, ant);
	    shell.register("dist", new StaticCmd("dist " + name));
	    shell.register("reinstall", new StaticCmd("reinstall " + name));
	    return new StaticCmd(shell);
	}

    public void testParse() throws Exception {
		ShellE shellE = new ShellE(root);
		shellE.run("ant");
		shellE.run("core");
		assertEquals("core", shellE.run("pws"));
//		shellE.complete("");
		shellE.run("server");
		assertEquals("server", shellE.run("pws"));
		shellE.run("ant scheduler");
		assertEquals("scheduler", shellE.run("pws"));
		assertEquals("start", shellE.run("ant scheduler; server start"));
		assertEquals("server", shellE.run("pws"));
//		shellE.complete("");
	}
}	

/*
 * cs ant/core; dist; cs /ant/scheduler; dist
 * - /ant/dist-and-deploy; /server/start; /ext/install/responsedemo
 * - /response/create long "long running"
 * - /response/create name=long action="long running" | /tasklog/show
 * 
 * ant dist-and-deploy
 * ant core dist
 * ant deploy; server start; ext install responsedemo
 * ant core; dist; redeploy-front-end; .. scheduler reinstall; /
 * mvc-action core; ls
 * 
 * - split on semi-colons
 * - for each cmd:
 *   * split on spaces
 *   * get cmd from current shell
 *   * if failed: get cmd from parent until error
 *   * check command type; if shell, change temp shell
 *   * else execute w/ remaing params
 *   * repeat until no parts left
 *   * if last cmd is shell, change current shell 
 *
 * Options:
 * - Dispatch by command name and command must parse.
 * - Parse args and choose which method to call based on available methods.
 * - Parse args and pass in string array to execute.
 * 
 * Goal:
 * core dist
 * dist-and-deploy
 * 
 * ant
 * 
 * cmd : change_shell | execute_command
 * change_shell : 'cs' relative_path | absolute_path
 * relative_path : [a-z|A-Z][/[a-z|A-Z]]*
 * absolute_path : / relative_path 
 * execute_command : shell+ command
 * shell : in shell list
 * command : command in last shell
 */