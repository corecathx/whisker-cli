package commands;

import claw.Command;
import sys.io.Process;
import sys.FileSystem;
import sys.io.File;

class ScreenCommand implements Command {
	public var name:String = "screen";
	public var description:String = "screen related utilities";
	public var arguments:Array<String> = ["freeze", "capture", "--region=x,y_WxH", "--copy", "--source=path"];

	public function new() {}

	public function execute(args:Array<String>) {
		if (args.length > 0 && args[0] == "freeze") {
			executeFreeze(args);
			return;
		}

		executeCapture(args);
	}

	private function executeFreeze(args:Array<String>) {
		var startTime = Sys.time();
		var now = Date.now();
		var timestamp = '${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}';
		var outputPath = '/tmp/whisker_freeze_${timestamp}.png';

		var proc = new Process("grim", ["-t", "png", "-l", "0", outputPath]);
		var exitCode = proc.exitCode();
		proc.close();

		if (exitCode != 0)
			throw "grim failed with exit code " + exitCode;

		if (!FileSystem.exists(outputPath))
			throw "freeze failed";

		var duration = Sys.time() - startTime;
		Sys.stderr().writeString('freeze took ${Math.round(duration * 1000)}ms\n');
		Sys.println(outputPath);
	}

	private function executeCapture(args:Array<String>) {
		var now = Date.now();
		var timestamp = '${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}';
		var outputPath = '${Globals.userCaptureDir}/screenshot_${timestamp}.png';

		if (FileSystem.exists(Globals.userCaptureDir) && !FileSystem.isDirectory(Globals.userCaptureDir))
			throw Globals.userCaptureDir + " is not a directory";

		if (!FileSystem.exists(Globals.userCaptureDir))
			FileSystem.createDirectory(Globals.userCaptureDir);

		var region:String = null;
		var copyToClipboard = false;
		var sourcePath:String = null;

		for (arg in args) {
			if (StringTools.startsWith(arg, "--region="))
				region = arg.substr("--region=".length);
			else if (arg == "--copy")
				copyToClipboard = true;
			else if (StringTools.startsWith(arg, "--source="))
				sourcePath = arg.substr("--source=".length);
		}

		if (sourcePath != null && FileSystem.exists(sourcePath) && region != null) {
			var parts = region.split("_");
			var coords = parts[0].split(",");
			var size = parts[1].split("x");
			var x = Std.parseInt(coords[0]);
			var y = Std.parseInt(coords[1]);
			var w = Std.parseInt(size[0]);
			var h = Std.parseInt(size[1]);

			var proc = new Process("ffmpeg", ["-i", sourcePath, "-vf", 'crop=${w}:${h}:${x}:${y}', "-y", outputPath]);
			var exitCode = proc.exitCode();
			proc.close();

			if (exitCode != 0)
				throw "ffmpeg failed to crop image";

			if (StringTools.startsWith(sourcePath, "/tmp/whisker_freeze_")) {
				try {
					FileSystem.deleteFile(sourcePath);
				} catch (e:Dynamic) {
					Sys.stderr().writeString('warning: failed to delete temp file\n');
				}
			}
		} else {
			if (region != null) {
				var formattedRegion = region.split("_").join(" ");
				var proc = new Process("grim", ["-g", formattedRegion, outputPath]);
				proc.exitCode();
				proc.close();
			} else {
				var proc = new Process("grim", [outputPath]);
				proc.exitCode();
				proc.close();
			}
		}

		if (!FileSystem.exists(outputPath))
			throw "screenshot not created";

		if (copyToClipboard) {
			var imgData = File.getBytes(outputPath);
			var wlcopy = new Process("wl-copy", ["--type", "image/png"]);
			wlcopy.stdin.writeBytes(imgData, 0, imgData.length);
			wlcopy.stdin.close();
			wlcopy.close();
			Sys.println('$outputPath (copied to clipboard)');
		} else {
			Sys.println(outputPath);
		}
	}

	private static function pad(n:Int):String {
		return (n < 10) ? '0$n' : '$n';
	}
}
