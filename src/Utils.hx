package;

import sys.io.Process;
using StringTools;

class Utils {
    public static function getRandom(array:Array<Any>) {
        return array[Std.int(Math.random()*array.length)];
    }
    public static function runDetached(command:String) {
        var fullCmd = "nohup " + command + " >/dev/null 2>&1 & echo $!";
        var pidProc = new Process("/bin/sh", ["-c", fullCmd]);
        return pidProc;
    }
    public static function notify(appName:String, icon:String, title:String, text:String, ?timeout:Int = 5000):Void {
        try {
            var proc = new Process("gdbus", [
                "call", "--session",
                "--dest", "org.freedesktop.Notifications",
                "--object-path", "/org/freedesktop/Notifications",
                "--method", "org.freedesktop.Notifications.Notify",
                appName, "0", icon, title, text, "[]", "{}", Std.string(timeout)
            ]);
            proc.close();
        } catch (e:Dynamic) {
            trace("Failed to send notification: " + e);
        }
    }

    public static function getBatteryLevel():Int {
        try {
            var proc = new Process("sh", ["-c", "upower -i $(upower -e | grep BAT) | grep percentage | awk '{print $2}'"]);
            var output = proc.stdout.readAll().toString().trim();
            proc.close();
            if (output.endsWith("%")) output = output.substr(0, output.length - 1);
            return Std.parseInt(output);
        } catch (e:Dynamic) {
            return -1;
        }
    }

    public static function getBatteryStatus():String {
        try {
            var proc = new Process("sh", ["-c", "upower -i $(upower -e | grep BAT) | grep state | awk '{print $2}'"]);
            var output = proc.stdout.readAll().toString().trim();
            proc.close();
            return output != "" ? output : "Unknown";
        } catch (e:Dynamic) {
            return "Unknown";
        }
    }
}
