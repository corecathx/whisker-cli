package commands;

import haxe.Json;
import sys.io.Process;
import sys.io.File;
import sys.FileSystem;
import claw.Command;

class ColorCommand implements Command {
	public var name:String = "color";
	public var description:String = "manage color schemes";
	public var arguments:Array<String> = ["update|#RRGGBB"];

	public function new() {}

	private function isVideo(path:String):Bool {
		var videoExts:Array<String> = [
			"mp4",
			"mkv",
			"webm",
			"avi",
			"mov",
			"flv",
			"wmv",
			"m4v"
		];

		var parts:Array<String> = path.split(".");

		if (parts.length == 0)
			return false;

		var ext:String = parts[parts.length - 1].toLowerCase();

		return videoExts.contains(ext);
	}

	private function extractVideoFrame(
		videoPath:String,
		outputPath:String
	):Void {
		Sys.println("extracting frame from video...");

		var process:Process = new Process("ffmpeg", [
			"-ss",
			"20",
			"-i",
			videoPath,
			"-vf",
			"scale=320:-1",
			"-frames:v",
			"1",
			"-y",
			outputPath
		]);

		var exitCode:Int = process.exitCode();

		if (exitCode != 0) {
			var error:String = process.stderr.readAll().toString();
			process.close();

			throw "failed to extract frame from video: " + error;
		}

		process.close();
	}

	private function updateSchemes(
		sourceType:String,
		source:String,
		mode:String,
		contrast:Float
	):Void {
		var colorsJson:Dynamic = {};
		var generatedMode:String = mode;

		Sys.println("generating color schemes...");

		var schemes:Array<String> = [
			"content",
			"expressive",
			"fidelity",
			"fruit-salad",
			"monochrome",
			"neutral",
			"rainbow",
			"tonal-spot"
		];

		for (scheme in schemes) {
			Sys.println("  " + scheme);

			var matugenArgs:Array<String>;

			if (sourceType == "image") {
				matugenArgs = [
					"image",
					source,
					"-m",
					mode,
					"-t",
					"scheme-" + scheme,
					"-j",
					"hex",
					"--contrast",
					Std.string(contrast),
					"--dry-run",
					"--source-color-index",
					"0",
					"--old-json-output"
				];
			} else if (sourceType == "color") {
				matugenArgs = [
					"color",
					"hex",
					source,
					"-m",
					mode,
					"-t",
					"scheme-" + scheme,
					"-j",
					"hex",
					"--contrast",
					Std.string(contrast),
					"--dry-run",
					"--source-color-index",
					"0",
					"--old-json-output"
				];
			} else {
				throw "unknown color source type: " + sourceType;
			}

			var process:Process = new Process("matugen", matugenArgs);

			var exitCode:Int = process.exitCode();

			if (exitCode != 0) {
				var error:String = process.stderr.readAll().toString();
				process.close();

				throw "matugen failed for scheme '" + scheme + "': " + error;
			}

			var json:String = process.stdout.readAll().toString().trim();

			if (json.length == 0) {
				process.close();

				throw "matugen returned no output for scheme '" + scheme + "'";
			}

			var parsed:Dynamic = Json.parse(json);

			if (!Reflect.hasField(parsed, "colors")) {
				process.close();

				throw "matugen returned invalid output for scheme '" + scheme + "'";
			}

			if (
				mode == "smart" &&
				generatedMode == "smart" &&
				Reflect.hasField(parsed, "mode")
			) {
				generatedMode = parsed.mode;
			}

			Reflect.setField(colorsJson, scheme, parsed.colors);

			process.close();
		}

		Reflect.setField(colorsJson, "mode", generatedMode);

		File.saveContent(
			Globals.whiskerCSchemes,
			Json.stringify(colorsJson)
		);
	}

	private function refreshMatugen(
		sourceType:String,
		source:String,
		mode:String,
		scheme:String,
		contrast:Float
	):Void {
		Sys.println("requesting matugen to refresh templates...");

		var matugenArgs:Array<String>;

		if (sourceType == "image") {
			matugenArgs = [
				"image",
				source,
				"-m",
				mode,
				"-t",
				"scheme-" + scheme,
				"-j",
				"hex",
				"--contrast",
				Std.string(contrast),
				"--source-color-index",
				"0"
			];
		} else if (sourceType == "color") {
			matugenArgs = [
				"color",
				"hex",
				source,
				"-m",
				mode,
				"-t",
				"scheme-" + scheme,
				"-j",
				"hex",
				"--contrast",
				Std.string(contrast),
				"--source-color-index",
				"0"
			];
		} else {
			throw "unknown color source type: " + sourceType;
		}

		var process:Process = new Process("matugen", matugenArgs);

		var exitCode:Int = process.exitCode();

		if (exitCode != 0) {
			var error:String = process.stderr.readAll().toString();
			process.close();

			throw "failed to refresh matugen templates: " + error;
		}

		process.close();
	}

	private function updateFromWallpaper(prefs:Dynamic):Void {
		if (!Reflect.hasField(prefs, "theme"))
			throw "preferences have no theme";

		if (!Reflect.hasField(prefs.theme, "wallpaper"))
			throw "theme has no wallpaper";

		var wallpaperPath:String = prefs.theme.wallpaper;

		if (!FileSystem.exists(wallpaperPath))
			throw "file at " + wallpaperPath + " doesn't exist";

		var smart:Bool = false;

		if (Reflect.hasField(prefs.theme, "smart"))
			smart = prefs.theme.smart;

		var mode:String = "dark";
		var scheme:String = "tonal-spot";

		if (smart) {
			mode = "smart";
		} else {
			var dark:Bool = true;

			if (Reflect.hasField(prefs.theme, "dark"))
				dark = prefs.theme.dark;

			mode = dark ? "dark" : "light";
		}

		if (Reflect.hasField(prefs.theme, "scheme"))
			scheme = prefs.theme.scheme;

		var contrast:Float = 0.0;

		if (Reflect.hasField(prefs.theme, "contrast"))
			contrast = prefs.theme.contrast;

		var imageForColors:String = wallpaperPath;
		var isVideoWallpaper:Bool = isVideo(wallpaperPath);

		if (isVideoWallpaper) {
			imageForColors = "/tmp/whisker-color-generation.png";
			extractVideoFrame(wallpaperPath, imageForColors);
		}

		updateSchemes(
			"image",
			imageForColors,
			mode,
			contrast
		);

		refreshMatugen(
			"image",
			imageForColors,
			mode,
			scheme,
			contrast
		);

		if (isVideoWallpaper && FileSystem.exists(imageForColors))
			FileSystem.deleteFile(imageForColors);

		Sys.println("color schemes successfully updated!");
	}

	private function updateFromColor(
		prefs:Dynamic,
		color:String
	):Void {
		if (!Reflect.hasField(prefs, "theme"))
			throw "preferences have no theme";

		var smart:Bool = false;

		if (Reflect.hasField(prefs.theme, "smart"))
			smart = prefs.theme.smart;

		var mode:String = "dark";
		var scheme:String = "tonal-spot";

		if (smart) {
			mode = "smart";
		} else {
			var dark:Bool = true;

			if (Reflect.hasField(prefs.theme, "dark"))
				dark = prefs.theme.dark;

			mode = dark ? "dark" : "light";
		}

		if (Reflect.hasField(prefs.theme, "scheme"))
			scheme = prefs.theme.scheme;

		var contrast:Float = 0.0;

		if (Reflect.hasField(prefs.theme, "contrast"))
			contrast = prefs.theme.contrast;

		updateSchemes(
			"color",
			color,
			mode,
			contrast
		);

		refreshMatugen(
			"color",
			color,
			mode,
			scheme,
			contrast
		);

		Sys.println("color schemes successfully updated!");
	}

	public function update():Void {
		if (!FileSystem.exists(Globals.whiskerUserPref))
			throw "whisker user preferences not found";

		var prefs:Dynamic = Json.parse(
			File.getContent(Globals.whiskerUserPref)
		);

		updateFromWallpaper(prefs);
	}

	public function execute(args:Array<String>):Void {
		if (args.length == 0)
			throw "missing color command";

		if (!FileSystem.exists(Globals.whiskerUserPref))
			throw "whisker user preferences not found";

		var prefs:Dynamic = Json.parse(
			File.getContent(Globals.whiskerUserPref)
		);

		var command:String = args[0];

		switch (command) {
			case "update":
				updateFromWallpaper(prefs);

			default:
				if (StringTools.startsWith(command, "#")) {
					updateFromColor(prefs, command);
				} else {
					throw "unknown color command: " + command;
				}
		}
	}
}