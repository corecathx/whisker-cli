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
		try {
			if (args.length > 0 && args[0] == "freeze") {
				executeFreeze(args);
				return;
			}
			executeCapture(args);
		} catch (e:Dynamic) {
			Sys.stderr().writeString('error: ${e}\n');
			Sys.exit(1);
		}
	}

	private function executeFreeze(args:Array<String>) {
		var startTime = Sys.time();
		var now = Date.now();
		var timestamp = '${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}';
		var outputPath = '/tmp/whisker_freeze_${timestamp}.png';

		var proc:Process = null;
		try {
			proc = new Process("grim", ["-t", "png", "-l", "0", outputPath]);
		} catch (e:Dynamic) {
			throw "failed to start grim: ${e}. is grim installed?";
		}

		var exitCode = proc.exitCode();
		proc.close();

		if (exitCode != 0)
			throw "grim failed with exit code ${exitCode}";

		if (!FileSystem.exists(outputPath))
			throw "freeze failed: output file not created at ${outputPath}";

		var duration = Sys.time() - startTime;
		Sys.stderr().writeString('freeze took ${Math.round(duration * 1000)}ms\n');
		Sys.println(outputPath);
	}

	private function executeCapture(args:Array<String>) {
		var now = Date.now();
		var timestamp = '${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}';
		var outputPath = '${Globals.userCaptureDir}/screenshot_${timestamp}.png';

		if (FileSystem.exists(Globals.userCaptureDir) && !FileSystem.isDirectory(Globals.userCaptureDir))
			throw "${Globals.userCaptureDir} is not a directory";

		if (!FileSystem.exists(Globals.userCaptureDir)) {
			try {
				FileSystem.createDirectory(Globals.userCaptureDir);
			} catch (e:Dynamic) {
				throw "failed to create directory ${Globals.userCaptureDir}: ${e}";
			}
		}

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
			if (!FileSystem.exists(sourcePath))
				throw "source image not found: ${sourcePath}";

			var parts = region.split("_");
			if (parts.length != 2)
				throw "invalid region format, expected: x,y_WxH";

			var coords = parts[0].split(",");
			var size = parts[1].split("x");

			if (coords.length != 2 || size.length != 2)
				throw "invalid region format, expected: x,y_WxH";

			var x = Std.parseInt(coords[0]);
			var y = Std.parseInt(coords[1]);
			var w = Std.parseInt(size[0]);
			var h = Std.parseInt(size[1]);

			if (x == null || y == null || w == null || h == null)
				throw "invalid region coordinates or dimensions";

			if (w <= 0 || h <= 0)
				throw "invalid region dimensions: width and height must be positive";

			var proc:Process = null;
			try {
				proc = new Process("ffmpeg", ["-i", sourcePath, "-vf", 'crop=${w}:${h}:${x}:${y}', "-y", outputPath]);
			} catch (e:Dynamic) {
				throw "failed to start ffmpeg: ${e}. is ffmpeg installed?";
			}

			var exitCode = proc.exitCode();
			proc.close();

			if (exitCode != 0)
				throw "ffmpeg failed to crop image (exit code ${exitCode})";

			if (StringTools.startsWith(sourcePath, "/tmp/whisker_freeze_")) {
				try {
					FileSystem.deleteFile(sourcePath);
				} catch (e:Dynamic) {
					Sys.stderr().writeString('warning: failed to delete temp file ${sourcePath}\n');
				}
			}
		} else {
			var grimArgs = region != null ? ["-g", region.split("_").join(" "), outputPath] : [outputPath];

			var proc:Process = null;
			try {
				proc = new Process("grim", grimArgs);
			} catch (e:Dynamic) {
				throw "failed to start grim: ${e}. is grim installed?";
			}

			var exitCode = proc.exitCode();
			proc.close();

			if (exitCode != 0)
				throw "grim failed with exit code ${exitCode}";
		}

		if (!FileSystem.exists(outputPath))
			throw "screenshot not created at ${outputPath}";

		if (copyToClipboard) {
			try {
				var imgData = File.getBytes(outputPath);
				var wlcopy = new Process("wl-copy", ["--type", "image/png"]);
				wlcopy.stdin.writeBytes(imgData, 0, imgData.length);
				wlcopy.stdin.close();
				wlcopy.close();
				Sys.println('${outputPath} (copied to clipboard)');
			} catch (e:Dynamic) {
				throw "failed to copy to clipboard: ${e}. is wl-copy installed?";
			}
		} else {
			Sys.println(outputPath);
		}
	}

	private static function pad(n:Int):String {
		return (n < 10) ? '0$n' : '$n';
	}
}
