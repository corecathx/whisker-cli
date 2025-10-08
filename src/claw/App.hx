package claw;

import claw.commands.HelpCommand;

/**
 * Main entry class for Claw apps.
 */
class App {
	/**
	 * Current active Claw app.
	 */
	public static var instance:App = null;
	/**
	 * Your app's name.
	 */
	public var name:String = "";

	/**
	 * Your app's description.
	 */
	public var desc:String = "";

	/**
	 * Your app's version.
	 */
	public var version = "0.1";

	/**
	 * Lists of available commands in this Claw app.
	 * By default, Claw creates the `help` command for you.
	 */
	public var commands:Array<Command> = [];

	/**
	 * Initialize a new Claw application.
	 */
	public function new() {
		instance = this;
		commands = [
			new HelpCommand()
		];
	}

	public function run() {
		var args:Array<String> = Sys.args();
		if (args.length == 0) {
			Sys.println('${name}: no command provided. see "${name} help".');
			return;
		}

		var cmdName:String = args[0];
		var cmdArgs:Array<String> = args.slice(1);

		var cmd:Command = commands.filter(c -> c.name == cmdName)[0];
		if (cmd != null)
			cmd.execute(cmdArgs);
		else
			Sys.println('${name}: unknown command "${cmdName}". see "${name} help".');
	}

	/**
	 * Create a new command.
	 * @param command Your command class.
	 */
	public function addCommand(command:Command) {
		commands.push(command);
	}
}
