package;

import haxe.macro.Type.Ref;
import haxe.Json;
import haxe.Timer;
import haxe.Exception;
import sys.io.Process;
import sys.io.File;
import sys.FileSystem;
import claw.App;

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
	static var whiskerLockFile = "/tmp/whisker.lck";
	static var whiskerQsFolder = Sys.getEnv("HOME") + "/.config/whisker";
	static var whiskerUserPref = Sys.getEnv("HOME") + "/preferences.json";

	static function main() {
		var app:App = new App();
		app.name = 'whisker';
		app.desc = 'a helper script for whisker shell';
		app.addCommand('shell', 'start or stop whisker shell', ['stop', '--stdout'], (args) -> {
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
				} else
					Sys.println("whisker shell is not running.");
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
					} catch (e:Dynamic) {}
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
		});
		app.addCommand('prefs', 'modify whisker user preferences', ['get', 'set', '--no-prompt'], (args) -> {
			if (!FileSystem.exists(whiskerUserPref)) {
				if (!args.contains('--no-prompt')
					&& App.prompt("preferences.json file is missing! would you like to create one?", ['y', 'n']) == 'n') {
					Sys.println('hmm.');
					return;
				}
				Sys.println("creating " + whiskerUserPref);
				File.saveContent(whiskerUserPref, "{}");
			}
			var rawText:String = File.getContent(whiskerUserPref);
			var jsonData:Dynamic = Json.parse(rawText);
			if (args.contains('set')) {
				if (args.length < 3) {
					Sys.println("usage: whisker prefs set <key> <value>");
					return;
				}
				var key = args[1];
				var value = args[2];
				Reflect.setProperty(jsonData, key, value);
				File.saveContent(whiskerUserPref, Json.stringify(jsonData, null, '\t'));
				Sys.println(value);
				return;
			}
			if (args.contains('get')) {
				if (args.length < 2) {
					Sys.println("usage: whisker prefs get <key>");
					return;
				}
				var key = args[1];
				if (Reflect.hasField(jsonData, key)) {
					Sys.println(Reflect.getProperty(jsonData, key));
				} else {
					Sys.println("not found: " + key);
				}
				return;
			}
			Sys.println("currently loaded prefs:");
			for (field in Reflect.fields(jsonData)) {
				Sys.println(App.padRight(field, 20) + Reflect.getProperty(jsonData, field));
			}
		});
		app.addCommand('wawa', 'wawa is ok', [], (args) -> {
			Sys.println('wawa is ok');
		});
		app.run();
	}
}
