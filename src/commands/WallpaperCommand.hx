package commands;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import claw.Command;

class WallpaperCommand implements Command {
	public var name:String = "wallpaper";
	public var description:String = "change wallpaper";
	public var arguments:Array<String> = ["path", "--no-color-update"];

	public function new() {}

	public function execute(args:Array<String>):Void {
		if (args.length == 0)
			throw "missing wallpaper path";

		var wallpaperPath:String = args[0];

		if (!FileSystem.exists(wallpaperPath))
			throw "file at " + wallpaperPath + " doesn't exist";

		if (!FileSystem.exists(Globals.whiskerUserPref))
			throw "whisker user preferences not found";

		var prefs:Dynamic = Json.parse(
			File.getContent(Globals.whiskerUserPref)
		);

		if (!Reflect.hasField(prefs, "theme")) {
			Sys.println("preferences has missing field 'theme', loaded defaults");

			Reflect.setProperty(prefs, "theme", {
				wallpaper: wallpaperPath,
				dark: true,
				scheme: "tonal-spot",
				smart: false
			});
		} else {
			prefs.theme.wallpaper = wallpaperPath;

			if (!Reflect.hasField(prefs.theme, "dark")) {
				Sys.println("missing field 'dark', loaded default (true)");
				Reflect.setProperty(prefs.theme, "dark", true);
			}

			if (!Reflect.hasField(prefs.theme, "scheme")) {
				Sys.println("missing field 'scheme', loaded default (tonal-spot)");
				Reflect.setProperty(prefs.theme, "scheme", "tonal-spot");
			}

			if (!Reflect.hasField(prefs.theme, "smart")) {
				Sys.println("missing field 'smart', loaded default (false)");
				Reflect.setProperty(prefs.theme, "smart", false);
			}
		}

		File.saveContent(
			Globals.whiskerUserPref,
			Json.stringify(prefs)
		);

		if (!args.contains("--no-color-update")) {
			var colorCommand:ColorCommand = new ColorCommand();
			colorCommand.update();
		}

		Sys.println("wallpaper successfully changed!");
	}
}