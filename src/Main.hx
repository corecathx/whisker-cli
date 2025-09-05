package;

import haxe.Timer;
import haxe.Exception;
import sys.io.Process;
import sys.io.File;
import sys.FileSystem;

typedef Command = {
	name:String,
	desc:String,
	args:Array<String>,
	callback:Array<String>->Void
}

/**
 * Whisker CLI thing
 */
class Main {
	static var _startTime:Float = Timer.stamp();
	static var appName = "whisker";
	static var appDesc = "a helper script for whisker shell.";
	static var appVersion = "0.1";

	static var whiskerLockFile = "/tmp/whisker.lck";
	static var whiskerQsFolder = Sys.getEnv("HOME") + "/.config/whisker/";

	static var commands:Array<Command> = [
		{
			name: "help",
			desc: "show available commands",
			args: [],
			callback: (args) -> {
				Sys.println('${appName} v${appVersion} - ${appDesc}');
				Sys.println("");
				Sys.println("usage:");
				Sys.println('  ${appName} <command> [arguments]');
				Sys.println("");
				Sys.println("commands:");
				for (cmd in commands) {
					var argStr:String = "";
                    for (i in cmd.args) 
                        argStr+='[$i] ';
					Sys.println('  ' + padRight(cmd.name + " " + argStr, 30) + cmd.desc);
				}
			}
		},
		{
			name: "shell",
			desc: "start or stop whisker shell",
			args: ["stop", "--stdout"],
			callback: (args) -> {
				var showStdout:Bool = args.contains("--stdout");
				if (args.length > 0 && args[0] == "stop") {
					if (FileSystem.exists(whiskerLockFile)) {
						var pid = File.getContent(whiskerLockFile);
						try {
							var p = new Process("kill", [pid]);
							p.close();
							FileSystem.deleteFile(whiskerLockFile);
							Sys.println("whisker shell stopped!");
						} catch (e:Dynamic) {
							Sys.println("failed to stop whisker shell.");
						}
					} else Sys.println("whisker shell is not running.");
					return;
				}

				if (FileSystem.exists(whiskerLockFile)) {
					Sys.println("whisker is already running!");
					return;
				}

				try {
					var proc:Process = new Process("quickshell", ["-c", whiskerQsFolder]);
					var pid:String = Std.string(proc.getPid());
					File.saveContent(whiskerLockFile, pid);
					Sys.println("whisker shell successfully running! (PID: " + pid + ")");
					if (showStdout) {
						try {
							while (true) {
								var line = proc.stdout.readLine();
								Sys.println(line);
							}
						} catch (e:Dynamic) {
						}
					}
					proc.exitCode();
					proc.close();
				} catch (e:Dynamic) {
					Sys.println("shell exited! (" + Math.round((Timer.stamp() - _startTime) * 10) / 10 + "s)");
                    // just incase quickshell crashed / whisker killed by command
                    if (FileSystem.exists(whiskerLockFile)) {
                        Sys.println("whisker is already running!");
                        return;
                    }
				}
			}
		}
	];

	static function main() {
		var input:Array<String> = Sys.args();
		if (input.length == 0) {
			Sys.println('${appName}: no command provided. see "${appName} help".');
			return;
		}

		var cmdName:String = input[0];
		var cmdArgs:Array<String> = input.slice(1);

		var cmd:Command = commands.filter(c -> c.name == cmdName)[0];
		if (cmd != null)
			cmd.callback(cmdArgs);
		else
			Sys.println('${appName}: unknown command "${cmdName}". see "${appName} help".');
	}

	static function padRight(str:String, length:Int):String
		return str + StringTools.rpad("", " ", Std.int(Math.max(0, length - str.length)));
}
