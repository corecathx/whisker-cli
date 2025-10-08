package commands;

import sys.io.File;
import haxe.Json;
import Typedefs.LockFile;
import sys.FileSystem;
import claw.Command;

class IpcCommand implements Command {
	public var name:String = "ipc";
	public var description:String = "call whisker's quickshell ipc";
	public var arguments:Array<String> = ['target', 'action'];

    public function new() {}

	public function execute(args:Array<String>) {
		if (!FileSystem.exists(Globals.whiskerLockFile)) {
			Sys.println("error: whisker shell not running. use `shell` first.");
			return;
		}
		if (FileSystem.exists(Globals.whiskerLockFile)) {
			var lock:LockFile = Json.parse(File.getContent(Globals.whiskerLockFile));
			Globals.whiskerQsFolder = lock.folder;
		}
		Utils.runDetached("qs -p " + Globals.whiskerQsFolder + " ipc call " + args.join(' '));
	}
}
