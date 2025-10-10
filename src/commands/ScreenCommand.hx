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
        if (args.length == 0)
            throw "no action was provided [capture]";

        switch (args[0]) {
            case "capture":
                handleCapture(args);

            default:
                throw 'unknown action "${args[0]}"';
        }
    }

    private function handleCapture(args:Array<String>) {
        var now = Date.now();
        var timestamp = '${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}';
        var outputPath = '${Globals.userCaptureDir}/screenshot_${timestamp}.png';

        if (FileSystem.exists(Globals.userCaptureDir) && !FileSystem.isDirectory(Globals.userCaptureDir))
            throw Globals.userCaptureDir + " is not a directory";
        else
            FileSystem.createDirectory(Globals.userCaptureDir);

        var region:String = null;
        var copyToClipboard = false;

        for (arg in args) {
            if (StringTools.startsWith(arg, "--region="))
                region = arg.substr("--region=".length);
            else if (arg == "--copy")
                copyToClipboard = true;
        }

        try {
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

            if (!FileSystem.exists(outputPath))
                throw "grim failed to capture the screen.";

            if (copyToClipboard) {
                try {
                    var imgData = File.getBytes(outputPath);
                    var wlcopy = new Process("wl-copy", ["--type", "image/png"]);
                    wlcopy.stdin.writeBytes(imgData, 0, imgData.length);
                    wlcopy.stdin.close();
                    wlcopy.close();

                    Sys.println('$outputPath (also copied to clipboard)');
                } catch (e:Dynamic) {
                    throw 'failed to copy to clipboard -> $e';
                }
            } else {
                Sys.println('$outputPath');
            }
        } catch (e:Dynamic) {
            throw 'failed to execute grim -> $e';
        }
    }

    private static function pad(n:Int):String {
        return (n < 10) ? '0$n' : '$n';
    }
}
