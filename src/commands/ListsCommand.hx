package commands;
import sys.io.Process;
import sys.io.File;
import haxe.Json;
import sys.FileSystem;
import claw.Command;

class ListsCommand implements Command {
	public var name:String = "list";
	public var description:String = "get list of something";
	public var arguments:Array<String> = ['type'];

	public function new() {}

	public function execute(args:Array<String>) {
		if (args.length == 0)
			throw "type is missing [wallpapers]";

		var imageExts = ["png", "jpg", "jpeg", "webp", "bmp", "gif", "tif", "tiff", "ico"];
		var videoExts = ["mp4", "mkv", "webm", "avi", "mov", "flv", "wmv", "m4v"];

		switch (args[0]) {
			case "wallpapers":
				if (!FileSystem.exists(Globals.userWallDir) || !FileSystem.isDirectory(Globals.userWallDir))
					throw "wallpaper directory at " + Globals.userWallDir + " doesn't exist or isn't a folder";

				for (wp in FileSystem.readDirectory(Globals.userWallDir)) {
					var ext = wp.split(".").pop().toLowerCase();
					if (imageExts.contains(ext) || videoExts.contains(ext))
						Sys.println('${Globals.userWallDir}/$wp');
				}
			default:
				throw "unknown list type '" + args[0] + "'";
		}
	}
}
