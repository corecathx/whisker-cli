package commands;
import sys.io.Process;
import sys.io.File;
import haxe.Json;
import sys.FileSystem;
import claw.Command;

class WallpapersCommand implements Command {
	public var name:String = "wallpaper";
	public var description:String = "change wallpaper";
	public var arguments:Array<String> = ['path', '--no-scheme-gen'];

	public function new() {}

	private function isVideo(path:String):Bool {
		var videoExts = ["mp4", "mkv", "webm", "avi", "mov", "flv", "wmv", "m4v"];
		var ext = path.split(".").pop().toLowerCase();
		return videoExts.contains(ext);
	}

	private function extractVideoFrame(videoPath:String, outputPath:String):Void {
		Sys.println('extracting frame from video...');
		var process = new Process('ffmpeg', [
    		'-ss', '20',
            '-i', videoPath,
            '-vf', 'scale=320:-1',
            '-frames:v', '1',
            '-y',
            outputPath
		]);
		var exitCode = process.exitCode();
		if (exitCode != 0) {
			var error = process.stderr.readAll().toString();
			throw "failed to extract frame from video: " + error;
		}
		process.close();
	}

	public function execute(args:Array<String>) {
		if (args.length == 0)
			throw "missing wallpaper path";

		if (!FileSystem.exists(Globals.whiskerUserPref))
			throw "whisker user preferences not found";

		if (!FileSystem.exists(args[0]))
			throw "file at " + args[0] + " doesn't exist";

		var prefs:Dynamic = Json.parse(File.getContent(Globals.whiskerUserPref));

		if (!Reflect.hasField(prefs, 'theme')) {
		    Sys.println("preferences has missing field 'theme', loaded defaults");
			Reflect.setProperty(prefs, 'theme', { // load whisker's defaults
				wallpaper: args[0],
				dark: true,
				scheme: 'tonal-spot'
			});
		} else {
			prefs.theme.wallpaper = args[0];

			var requiredFieldDefaults:Array<Array<Dynamic>> = [['dark', true], ['scheme', 'tonal-spot']];
			for (requiredFields in requiredFieldDefaults) {
			    if (!Reflect.hasField(prefs.theme,requiredFields[0])) {
    			    Sys.println("missing field '" + requiredFields[0] + "', loaded defaults ("+requiredFields[1]+")");
					Reflect.setProperty(prefs.theme, requiredFields[0], requiredFields[1]);
				}
			}
		}

		if (!FileSystem.exists(Globals.whiskerLocalDir))
            FileSystem.createDirectory(Globals.whiskerLocalDir);
        else if (!FileSystem.isDirectory(Globals.whiskerLocalDir))
            throw '${Globals.whiskerLocalDir} exists, but it\'s not a directory... why?';

		var imageForColors = args[0];
		var isVideoWallpaper = isVideo(args[0]);
		var contrast = 0.0;
		if (Reflect.hasField(prefs.theme, "contrast")) {
		    contrast = prefs.theme.contrast;
		}
		if (isVideoWallpaper) {
			imageForColors = '/tmp/whisker-color-generation.png';
			extractVideoFrame(args[0], imageForColors);
		}
		var colorsJson:Dynamic = {}

		if (!args.contains('--no-scheme-gen')) {
		    Sys.println('generating color schemes...');

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
    				imageForColors,
    				'-m',
    				prefs.theme.dark ? 'dark' : 'light',
    				'-t',
    				'scheme-$scheme',
    				'-j',
    				'hex',
                    '--contrast',
                    Std.string(contrast),
    				'--dry-run'
    			]);
    			process.exitCode();
    			var json:String = process.stdout.readAll().toString().trim();
    			var parsed:Dynamic = Json.parse(json);
    			Reflect.setField(colorsJson, scheme, parsed.colors);
    			process.close();
    		}
		} else {
		    Sys.println('"--no-scheme-gen" passed, skipping color schemes generation...');
		}

        Sys.println('requesting matugen to refresh templates...');

		var process:Process = new Process('matugen', [
			'image', imageForColors,
			'-m', prefs.theme.dark ? 'dark' : 'light',
			'-t', 'scheme-${prefs.theme.scheme}',
			'-j', 'hex',
            '--contrast', Std.string(contrast),
		]);
		process.exitCode();
		process.close();
		if (!args.contains('--no-scheme-gen')) {
    		colorsJson.active = prefs.theme.scheme;
    		colorsJson.mode = prefs.theme.dark ? 'dark' : 'light';
		}

		if (isVideoWallpaper && FileSystem.exists(imageForColors))
			FileSystem.deleteFile(imageForColors);

		if (!args.contains('--no-scheme-gen')) {
    		File.saveContent(Globals.whiskerCSchemes, Json.stringify(colorsJson));
		}
		File.saveContent(Globals.whiskerUserPref, Json.stringify(prefs));
		Sys.println("wallpaper successfully changed!");
	}
}
