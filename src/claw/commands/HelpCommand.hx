package claw.commands;
import claw.Command;

class HelpCommand implements Command {
	public var name:String = "help";
	public var description:String = "show available commands";
	public var arguments:Array<String> = [];

    public function new() {}
    
	public function execute(args:Array<String>) {
        if (App.instance == null) 
            throw "error: App instance is null.";
        Sys.println('${App.instance.name} v${App.instance.version} - ${App.instance.desc}');
        Sys.println("\nusage:");
        Sys.println('  ${App.instance.name} <command> [arguments]');
        Sys.println("\ncommands:");
        for (cmd in App.instance.commands) {
            var argStr:String = "";
            for (i in cmd.arguments)
                argStr += '[$i] ';
            Sys.println('  ' + ClawHelpers.padRight(cmd.name + " " + argStr, 35) + cmd.description);
        }
    }
}