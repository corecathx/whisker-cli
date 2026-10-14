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

		function parseValue(raw:String):Dynamic {
			try {
				return Json.parse(raw);
			} catch (e:Dynamic) {
				return raw;
			}
		}

		function printValue(value:Dynamic) {
			if (value == null || !Std.isOfType(value, String))
				Sys.println(Json.stringify(value));
			else
				Sys.println(value);
		}

		if (!FileSystem.exists(Globals.whiskerConfigDir)) {
			FileSystem.createDirectory(Globals.whiskerConfigDir);
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

		function getNested(obj:Dynamic, path:Array<String>):Dynamic {
			var cur = obj;
			for (p in path)
				if (Reflect.hasField(cur, p))
					cur = Reflect.getProperty(cur, p);
				else
					return null;
			return cur;
		}

		function hasNested(obj:Dynamic, path:Array<String>):Bool {
			var cur = obj;
			for (p in path) {
				if (cur == null || !Reflect.hasField(cur, p))
					return false;
				cur = Reflect.getProperty(cur, p);
			}
			return true;
		}

		function setNested(obj:Dynamic, path:Array<String>, val:Dynamic):Bool {
			var cur = obj;
			for (i in 0...path.length - 1) {
				var key = path[i];
				if (!Reflect.hasField(cur, key)) {
					Reflect.setProperty(cur, key, {});
				}
				cur = Reflect.getProperty(cur, key);
				if (!Reflect.isObject(cur)) {
					return false;
				}
			}
			Reflect.setProperty(cur, path[path.length - 1], val);
			return true;
		}

		if (args.contains('set')) {
			if (args.length < 3) {
				Sys.println("usage: whisker prefs set <key> <value>");
				return;
			}

			var path = args[1].split(".");
			var value:Dynamic = parseValue(args[2]);

			if (!setNested(jsonData, path, value)) {
				Sys.println("not found: " + args[1]);
				return;
			}

			File.saveContent(Globals.whiskerUserPref, Json.stringify(jsonData, null, '\t'));

			if (FileSystem.exists(Globals.whiskerCSchemes)) {
				var colorsJson:Dynamic = Json.parse(File.getContent(Globals.whiskerCSchemes));
				if (jsonData.theme != null) {
					if (Reflect.hasField(jsonData.theme, "scheme"))
						colorsJson.active = jsonData.theme.scheme;
					if (Reflect.hasField(jsonData.theme, "dark"))
						colorsJson.mode = jsonData.theme.dark ? 'dark' : 'light';
				}
				File.saveContent(Globals.whiskerCSchemes, Json.stringify(colorsJson));
			}

			printValue(value);
			return;
		}

		if (args.contains('get')) {
			if (args.length < 2) {
				Sys.println("usage: whisker prefs get <key>");
				return;
			}

			var path = args[1].split(".");
			if (!hasNested(jsonData, path)) {
				Sys.println("not found: " + args[1]);
				return;
			}

			printValue(getNested(jsonData, path));
			return;
		}

		Sys.println("currently loaded prefs:");
		for (field in Reflect.fields(jsonData)) {
			var fieldData:Dynamic = Reflect.getProperty(jsonData, field);
			var isObject:Bool = Reflect.isObject(fieldData) && Reflect.fields(fieldData).length > 0;
			if (isObject && Reflect.fields(fieldData).length == 1 && Reflect.fields(fieldData)[0] == 'length')
				isObject = false;
			if (isObject) {
				Sys.println(field);
				for (child in Reflect.fields(fieldData))
					Sys.println(ClawHelpers.padRight('| $child', 25) + Reflect.getProperty(fieldData, child));
			} else {
				Sys.println(ClawHelpers.padRight(field, 25) + Reflect.getProperty(jsonData, field));
			}
		}
	}
}
