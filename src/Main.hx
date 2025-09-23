package;

import haxe.macro.Type.Ref;
import haxe.Json;
import haxe.Timer;
import haxe.Exception;
import sys.io.Process;
import sys.io.File;
import sys.FileSystem;
import claw.App;

using StringTools;

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

	static var userHomeDir = Sys.getEnv("HOME");
	static var userWallDir = userHomeDir + "/Pictures/wallpapers";
	static var whiskerConfigDir = userHomeDir + "/.config/whisker";

	static var whiskerLockFile = "/tmp/whisker.lck";
	// static var whiskerQsFolder = userHomeDir + "/.config/whisker";
	static var whiskerQsFolder = "/usr/share/whisker";
	static var whiskerUserPref = whiskerConfigDir + "/preferences.json";
	static var whiskerCSchemes = whiskerQsFolder + "/schemes.json";

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
				if (showStdout) {
					var proc = new Process("quickshell", ["-c", whiskerQsFolder]);
					var pid = Std.string(proc.getPid());
					File.saveContent(whiskerLockFile, pid);
					Sys.println("whisker shell successfully running! (PID: " + pid + ")");
					try {
						while (true) {
							var line = proc.stdout.readLine();
							Sys.println(line);
						}
					} catch (e:Dynamic) {}
					proc.exitCode();
					proc.close();
				} else {
					var pid = Utils.runDetached("quickshell -c \"" + whiskerQsFolder + "\"").stdout.readLine();

					File.saveContent(whiskerLockFile, pid);
					Sys.println("whisker shell successfully running! (PID: " + pid + ")");
				}
			} catch (e:Dynamic) {
				Sys.println("shell exited! (" + Math.round((Timer.stamp() - _startTime) * 10) / 10 + "s)");
				if (FileSystem.exists(whiskerLockFile)) {
					Sys.println("whisker is already running!");
					return;
				}
			}
		});
		app.addCommand('prefs', 'modify whisker user preferences', ['get', 'set', '--no-prompt'], (args) -> {
			inline function isBoolean(val:Dynamic) {
				return val == "true" || val == "false";
			}
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
				var value:Dynamic = isBoolean(args[2]) ? args[2] == 'true' : args[2];
				Reflect.setProperty(jsonData, key, value);
				File.saveContent(whiskerUserPref, Json.stringify(jsonData, null, '\t'));

				if (FileSystem.exists(whiskerCSchemes)) {
					// :sob:
					var colorsJson:Dynamic = Json.parse(File.getContent(whiskerCSchemes));
					colorsJson.active = jsonData.colorScheme;
					colorsJson.mode = jsonData.darkMode ? 'dark' : 'light';

					File.saveContent(whiskerCSchemes, Json.stringify(colorsJson));
				}
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
		app.addCommand('wallpaper', 'change wallpaper', ["path"], (args) -> {
			if (args.length == 0) {
				Sys.println("error: missing wallpaper path");
				return;
			}

			if (!FileSystem.exists(whiskerUserPref)) {
				Sys.println("error: whisker user preferences not found");
			}

			if (!FileSystem.exists(args[0])) {
				Sys.println("error: file at " + args[0] + " doesn't exist");
				return;
			}

			var prefs:Dynamic = Json.parse(File.getContent(whiskerUserPref));
			prefs.wallpaper = args[0];
			Sys.println('generating color schemes...');
			var colorsJson:Dynamic = {}
			for (scheme in [
				'content',
				'expressive',
				'fidelity',
				'fruit-salad',
				'monochrome',
				'neutral',
				'rainbow',
				'tonal-spot'
			]) {
				Sys.println("  " + scheme);
				var process:Process = new Process('matugen', [
					'image',
					prefs.wallpaper,
					'-m',
					prefs.darkMode ? 'dark' : 'light',
					'-t',
					'scheme-$scheme',
					'-j',
					'hex',
					'--dry-run'
				]);
				process.exitCode();
				var json:String = process.stdout.readAll().toString().trim().split('\n')[0];
				var parsed:Dynamic = Json.parse(json);
				Reflect.setField(colorsJson, scheme, parsed.colors);
			}
			// one last thing
			var process:Process = new Process('matugen', [
				'image',                   prefs.wallpaper,
				   '-m', prefs.darkMode ? 'dark' : 'light',
				   '-t',     'scheme-${prefs.colorScheme}',
				   '-j',                             'hex',
			]);
			colorsJson.active = prefs.colorScheme;
			colorsJson.mode = prefs.darkMode ? 'dark' : 'light';
			// Reflect.setField(colorsJson, scheme, parsed.colors);

			File.saveContent(whiskerCSchemes, Json.stringify(colorsJson));
			File.saveContent(whiskerUserPref, Json.stringify(prefs));
		});
		app.addCommand('list', 'get list of something', ['type'], (args) -> {
			if (args.length == 0) {
				Sys.println("error: type is missing [wallpapers]");
				return;
			}

			var imageExts = ["png", "jpg", "jpeg", "webp", "bmp", "gif", "tif", "tiff", "ico"];

			switch (args[0]) {
				case "wallpapers":
					if (!FileSystem.exists(userWallDir) || !FileSystem.isDirectory(userWallDir)) {
						Sys.println("error: wallpaper directory at " + userWallDir + " doesn't exist or isn't a folder");
						return;
					}

					for (wp in FileSystem.readDirectory(userWallDir)) {
						var ext = wp.split(".").pop().toLowerCase();
						if (imageExts.contains(ext))
							Sys.println('$userWallDir/$wp');
					}

				default:
					Sys.println("error: unknown list type '" + args[0] + "'");
					return;
			}
		});
		app.addCommand('wawa', 'wawa is ok', [], (args) -> {
			var art = [
				"                                                #          ",
				"          ###                              ######          ",
				"         ########                       ##########         ",
				"         ############                #############         ",
				"         #######################   ###############         ",
				"         #########################################         ",
				"         #########################################         ",
				"         #########################################         ",
				"         #########################################         ",
				"         #########################################         ",
				"         #########################################         ",
				"         #########################################         ",
				"         #########################################         ",
				"         ############*+*##########*+*#############         ",
				"         ###########----=########----+############         ",
				"         ###########----=########----+############         ",
				"     ###############----=########----+################     ",
				"     ###############----=########----+################     ",
				"     ###*###########+---#########=---############*####     ",
				"      ##########*+==+#####*----+#####*==+*###########      ",
				"      ###*+++++**#########*====+#########**+++++**###      ",
				"        ###########################################        ",
				"        ###########################################        ",
				"       #############################################       ",
				"       #############################################       ",
				"       ####     ##########################      ####       ",
			].join("\n");

			Sys.println(art);
			Sys.println('wawa is ok');
		});
		app.addCommand('ipc', "call whisker's quickshell ipc", ["target", "action"], (args) -> {
			Sys.println("ok");
			// i got lazy
			Utils.runDetached("qs -p " + whiskerQsFolder + " ipc call " + args.join(' '));
		});
		app.addCommand('notify', 'test', [], (args) -> {
			Utils.notify(app.name, whiskerQsFolder + "/logo.png", 'wawa', 'cat');
		});
		app.run();
	}
}
