package commands;

import sys.io.Process;
import sys.io.File;
import haxe.Json;
import sys.FileSystem;
import claw.Command;

class WallpapersCommand implements Command {
	public var name:String = "wallpaper";
	public var description:String = "change wallpaper";
	public var arguments:Array<String> = ['path'];

	public function new() {}

	public function execute(args:Array<String>) {
		if (args.length == 0)
			throw "missing wallpaper path";

		if (!FileSystem.exists(Globals.whiskerUserPref))
			throw "whisker user preferences not found";

		if (!FileSystem.exists(args[0]))
			throw "file at " + args[0] + " doesn't exist";

		var prefs:Dynamic = Json.parse(File.getContent(Globals.whiskerUserPref));
		if (!Reflect.hasField(prefs, 'theme')) {
		    Reflect.setProperty(prefs, 'theme', {
				wallpaper: args[0]
			});
		} else {
    		prefs.theme.wallpaper = args[0];

		}
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
				prefs.theme.wallpaper,
				'-m',
				prefs.theme.dark ? 'dark' : 'light',
				'-t',
				'scheme-$scheme',
				'-j',
				'hex',
				'--dry-run'
			]);
			process.exitCode();
			var json:String = process.stdout.readAll().toString().trim();
			var parsed:Dynamic = Json.parse(json);
			Reflect.setField(colorsJson, scheme, parsed.colors);
		}
		// one last thing
		var process:Process = new Process('matugen', [
			'image',               prefs.theme.wallpaper,
			   '-m', prefs.theme.dark ? 'dark' : 'light',
			   '-t',       'scheme-${prefs.theme.scheme}',
			   '-j',                               'hex',
		]);
		colorsJson.active = prefs.theme.scheme;
		colorsJson.mode = prefs.theme.dark ? 'dark' : 'light';
		// Reflect.setField(colorsJson, scheme, parsed.colors);

		File.saveContent(Globals.whiskerCSchemes, Json.stringify(colorsJson));
		File.saveContent(Globals.whiskerUserPref, Json.stringify(prefs));
	}
}
