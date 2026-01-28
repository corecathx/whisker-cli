package commands;

import sys.io.Process;
import sys.io.File;
import haxe.Json;
import Typedefs.LockFile;
import sys.FileSystem;
import claw.Command;

class ShellCommand implements Command {
	public var name:String = "shell";
	public var description:String = "start or stop whisker shell";
	public var arguments:Array<String> = ['stop', 'restart', '--stdout'];

    public function new() { }

	public function execute(args:Array<String>) {
		var showStdout:Bool = args.contains("--stdout");
		if (args.length > 0 && (args[0] == "stop" || args[0] == "restart")) {
			if (FileSystem.exists(Globals.whiskerLockFile)) {
				var lock:LockFile = Json.parse(File.getContent(Globals.whiskerLockFile));
				var pid = lock.pid;
				Globals.whiskerQsFolder = lock.folder;
				try {
					var p = new Process("kill", [pid]);
					p.close();
					FileSystem.deleteFile(Globals.whiskerLockFile);
					Sys.println("whisker shell stopped!");
				} catch (e:Dynamic) {
					Sys.println("failed to stop whisker shell.");
				}
			} else
				Sys.println("whisker shell is not running.");
			if (args[0] != 'restart')
    			return;
		}

		if (FileSystem.exists(Globals.whiskerLockFile)) {
			var whiskerLock:LockFile = Json.parse(File.getContent(Globals.whiskerLockFile));
			var proc = new Process("ps", ["aux"]);
			var output:String = "";
			try {
				while (true)
					output += proc.stdout.readLine() + "\n";
			} catch (e:Dynamic) {}
			proc.exitCode();
			proc.close();

			if (output.contains(whiskerLock.pid)) {
				Sys.println("whisker is already running!");
				return;
			}
		}

		try {
			if (showStdout) {
				var proc = new Process("quickshell", ["-p", Globals.whiskerQsFolder]);
				var pid = Std.string(proc.getPid());
				var lock:LockFile = {
					pid: pid,
					folder: Globals.whiskerQsFolder
				};
				File.saveContent(Globals.whiskerLockFile, Json.stringify(lock));

				Sys.println("whisker shell successfully running! (PID: " + pid + ")");
				try {
					while (true) {
						var line = proc.stdout.readLine();
						Sys.println(line);
					}
				} catch (e:Dynamic) {}
				proc.exitCode();
				proc.close();
			} else {
				var pid = Utils.runDetached("quickshell -p \"" + Globals.whiskerQsFolder + "\"").stdout.readLine();

				var lock:LockFile = {
					pid: pid,
					folder: Globals.whiskerQsFolder
				};
				File.saveContent(Globals.whiskerLockFile, Json.stringify(lock));

				Sys.println("whisker shell successfully running! (PID: " + pid + ")");
			}
		} catch (e:Dynamic) {
		}
	}
}
