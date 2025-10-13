package commands;

import sys.io.Process;
import sys.io.File;
import haxe.Json;
import Typedefs.LockFile;
import sys.FileSystem;
import claw.Command;

class WelcomeCommand implements Command {
	public var name:String = "welcome";
	public var description:String = "show welcome screen";
	public var arguments:Array<String> = ['--stdout'];

	public function new() {}

	public function execute(args:Array<String>) {
		if (!FileSystem.exists(Globals.whiskerLockFile))
			throw "whisker shell not running. use `shell` first.";

		if (FileSystem.exists(Globals.whiskerLockFile)) {
			var lock:LockFile = Json.parse(File.getContent(Globals.whiskerLockFile));
			Globals.whiskerQsFolder = lock.folder;
		}
		Globals.whiskerQsFolder += '/welcome.qml';
		var showStdout:Bool = args.contains("--stdout");
		if (args.length > 0 && args[0] == "stop") {
			if (FileSystem.exists(Globals.whiskerWelcomeLockFile)) {
				var lock:LockFile = Json.parse(File.getContent(Globals.whiskerWelcomeLockFile));
				var pid = lock.pid;
				Globals.whiskerQsFolder = lock.folder;
				try {
					var p = new Process("kill", [pid]);
					p.close();
					FileSystem.deleteFile(Globals.whiskerWelcomeLockFile);
					Sys.println("welcome screen stopped!");
				} catch (e:Dynamic) {
					Sys.println("failed to stop welcome screen.");
				}
			} else
				Sys.println("welcome screen is not running.");
			return;
		}
		if (FileSystem.exists(Globals.whiskerWelcomeLockFile)) {
			var whiskerLock:LockFile = Json.parse(File.getContent(Globals.whiskerWelcomeLockFile));
			var proc = new Process("ps", ["aux"]);
			var output:String = "";
			try {
				while (true)
					output += proc.stdout.readLine() + "\n";
			} catch (e:Dynamic) {}
			proc.exitCode();
			proc.close();

			if (output.contains(whiskerLock.pid)) {
				Sys.println("welcome screen is already running!");
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
				File.saveContent(Globals.whiskerWelcomeLockFile, Json.stringify(lock));

				Sys.println("done (PID: " + pid + ")");
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
				File.saveContent(Globals.whiskerWelcomeLockFile, Json.stringify(lock));

				Sys.println("done (PID: " + pid + ")");
			}
		} catch (e:Dynamic) {}
	}
}
