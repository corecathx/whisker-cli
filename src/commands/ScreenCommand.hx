package commands;

import claw.Command;
import sys.io.Process;
import sys.FileSystem;
import sys.io.File;

class ScreenCommand implements Command {
    public var name:String = "screen";
    public var description:String = "screen related utilities";
    public var arguments:Array<String> = ["capture", "--region=x,y_WxH", "--copy"];

    public function new() {}

    public function execute(args:Array<String>) {
        var now = Date.now();
        var timestamp = '${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}';
        var outputPath = '${Globals.userCaptureDir}/screenshot_${timestamp}.png';

        if (FileSystem.exists(Globals.userCaptureDir) && !FileSystem.isDirectory(Globals.userCaptureDir))
            throw Globals.userCaptureDir + " is not a directory";
        else
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

        try {
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
        } catch (e:Dynamic) {
            throw 'screenshot failed -> $e';
        }
    }

    private static function pad(n:Int):String {
        return (n < 10) ? '0$n' : '$n';
    }
}
