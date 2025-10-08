package commands;

import claw.ClawHelpers;
import sys.io.File;
import haxe.Json;
import sys.FileSystem;
import claw.Command;

class PreferencesCommand implements Command {
	public var name:String = "prefs";
	public var description:String = "modify user preferences";
	public var arguments:Array<String> = ['get', 'set', '--no-prompt'];

	public function new() {}

	public function execute(args:Array<String>) {
		inline function isBoolean(val:Dynamic) {
			return val == "true" || val == "false";
		}
		if (!FileSystem.exists(Globals.whiskerUserPref)) {
			if (!args.contains('--no-prompt')
				&& ClawHelpers.prompt("preferences.json file is missing! would you like to create one?", ['y', 'n']) == 'n') {
				Sys.println('alright.');
				return;
			}
			Sys.println("creating " + Globals.whiskerUserPref);
			File.saveContent(Globals.whiskerUserPref, "{}");
		}
		var rawText:String = File.getContent(Globals.whiskerUserPref);
		var jsonData:Dynamic = Json.parse(rawText);
		if (args.contains('set')) {
			if (args.length < 3) {
				Sys.println("usage: whisker prefs set <key> <value>");
				return;
			}
			var key = args[1];
			var value:Dynamic = isBoolean(args[2]) ? args[2] == 'true' : args[2];
			Reflect.setProperty(jsonData, key, value);
			File.saveContent(Globals.whiskerUserPref, Json.stringify(jsonData, null, '\t'));

			if (FileSystem.exists(Globals.whiskerCSchemes)) {
				// :sob:
				var colorsJson:Dynamic = Json.parse(File.getContent(Globals.whiskerCSchemes));
				colorsJson.active = jsonData.colorScheme;
				colorsJson.mode = jsonData.darkMode ? 'dark' : 'light';

				File.saveContent(Globals.whiskerCSchemes, Json.stringify(colorsJson));
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
			Sys.println(ClawHelpers.padRight(field, 20) + Reflect.getProperty(jsonData, field));
		}
	}
}
