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
	public var arguments:Array<String> = ["stop", "restart", "--stdout"];

	public function new() {}

	function isProcessAlive(pid:String):Bool {
		try {
			var p = new Process("kill", ["-0", pid]);
			p.close();
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	function stopShell():Void {
		if (!FileSystem.exists(Globals.whiskerLockFile)) {
			Sys.println("whisker shell is not running.");
			return;
		}

		var lock:LockFile = Json.parse(File.getContent(Globals.whiskerLockFile));

		if (isProcessAlive(lock.pid)) {
			try {
				var p = new Process("kill", [lock.pid]);
				p.close();
			} catch (e:Dynamic) {
				Sys.println("failed to stop whisker shell.");
				return;
			}
		}

		FileSystem.deleteFile(Globals.whiskerLockFile);
		Sys.println("whisker shell stopped!");
	}

	public function execute(args:Array<String>) {
		var showStdout = args.contains("--stdout");
		var isStop = args.length > 0 && args[0] == "stop";
		var isRestart = args.length > 0 && args[0] == "restart";

		if (isStop || isRestart) {
			stopShell();
			if (isStop)
				return;
		}

		if (!isRestart && FileSystem.exists(Globals.whiskerLockFile)) {
			var lock:LockFile = Json.parse(File.getContent(Globals.whiskerLockFile));
			if (isProcessAlive(lock.pid)) {
				Sys.println("whisker is already running!");
				return;
			} else {
				FileSystem.deleteFile(Globals.whiskerLockFile);
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
					while (true)
						Sys.println(proc.stdout.readLine());
				} catch (e:Dynamic) {}

				proc.exitCode();
				proc.close();
			} else {
				var pid = Utils.runDetached('quickshell -p "${Globals.whiskerQsFolder}"').stdout.readLine();

				var lock:LockFile = {
					pid: pid,
					folder: Globals.whiskerQsFolder
				};
				File.saveContent(Globals.whiskerLockFile, Json.stringify(lock));

				Sys.println("whisker shell successfully running! (PID: " + pid + ")");
			}
		} catch (e:Dynamic) {
			Sys.println("failed to start whisker shell.");
		}
	}
}
