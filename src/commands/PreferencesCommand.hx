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
		function getNested(obj:Dynamic, path:Array<String>):Dynamic {
			var cur = obj;
			for (p in path) if (Reflect.hasField(cur,p)) cur = Reflect.getProperty(cur,p); else return null;
			return cur;
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
			var value:Dynamic = isBoolean(args[2]) ? args[2] == 'true' : args[2];
			if (!setNested(jsonData,path,value)) {
				Sys.println("not found: " + args[1]);
				return;
			}
			File.saveContent(Globals.whiskerUserPref, Json.stringify(jsonData, null, '\t'));
			if (FileSystem.exists(Globals.whiskerCSchemes)) {
				var colorsJson:Dynamic = Json.parse(File.getContent(Globals.whiskerCSchemes));
				if (jsonData.theme != null) {
					if (Reflect.hasField(jsonData.theme,"scheme")) colorsJson.active = jsonData.theme.scheme;
					if (Reflect.hasField(jsonData.theme,"dark")) colorsJson.mode = jsonData.theme.dark ? 'dark' : 'light';
				}
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
			var path = args[1].split(".");
			var value = getNested(jsonData,path);
			if (value == null) Sys.println("not found: " + args[1]);
			else Sys.println(value);
			return;
		}
		Sys.println("currently loaded prefs:");
		for (field in Reflect.fields(jsonData)) {
		    var fieldData = Reflect.getProperty(jsonData, field);
			var isObject:Bool = Reflect.isObject(fieldData) && Reflect.fields(fieldData).length > 0;
			if (isObject && Reflect.fields(fieldData).length == 1 && Reflect.fields(fieldData)[0] == 'length') // string check
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
