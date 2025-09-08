package claw;

typedef Command = {
	name:String,
	desc:String,
	args:Array<String>,
	callback:Array<String>->Void
}

/**
 * Main entry class for Claw apps.
 */
class App {
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
		commands = [
			{
				name: "help",
				desc: "show available commands",
				args: [],
				callback: (args) -> {
					Sys.println('${name} v${version} - ${desc}');
					Sys.println("\nusage:");
					Sys.println('  ${name} <command> [arguments]');
					Sys.println("\ncommands:");
					for (cmd in commands) {
						var argStr:String = "";
						for (i in cmd.args)
							argStr += '[$i] ';
						Sys.println('  ' + padRight(cmd.name + " " + argStr, 35) + cmd.desc);
					}
				}
			}
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
			cmd.callback(cmdArgs);
		else
			Sys.println('${name}: unknown command "${cmdName}". see "${name} help".');
	}

	/**
	 * Create a new command.
	 * @param name Command's name, which will also be used as the trigger.
	 * @param description Command's description.
	 * @param args Command's arguments, helps user understand what args this command accepts.
	 * @param callback Will be called when this command is triggered.
	 * @return Command Newly created Command object.
	 */
	public function addCommand(name:String, description:String, args:Array<String>, callback:Array<String>->Void):Command {
		var cmd:Command = {
			name: name,
			desc: description,
			args: args,
			callback: callback
		};
		commands.push(cmd);
		return cmd;
	}

	public static function padRight(str:String, length:Int):String
		return str + StringTools.rpad("", " ", Std.int(Math.max(0, length - str.length)));

	public static function prompt(question:String, accepts:Array<String>, defaultIndex:Int = 0):String {
		var lastAnswer:String = '';

		while (!accepts.contains(lastAnswer)) {
			var displayOptions = [];
			for (i in 0...accepts.length) {
				if (i == defaultIndex)
					displayOptions.push(accepts[i].toUpperCase());
				else
					displayOptions.push(accepts[i]);
			}

			Sys.print('$question [${displayOptions.join("/")}]: ');
			var answer:String = Sys.stdin().readLine();

			if (answer == "" && defaultIndex >= 0 && defaultIndex < accepts.length)
				lastAnswer = accepts[defaultIndex].toLowerCase();
			else
				lastAnswer = answer.toLowerCase();
		}

		return lastAnswer;
	}
}
