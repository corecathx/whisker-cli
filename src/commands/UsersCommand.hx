package commands;

import sys.io.File;
import sys.FileSystem;
import claw.Command;

class UsersCommand implements Command {
	public var name:String = "users";
	public var description:String = "configure a user data for usage in whisker";
	public var arguments:Array<String> = ['username', '<icon, wallpaper>'];

    public function new() {}

	public static function run(args:Array<String>) {
		var command = new UsersCommand();
		command.execute(args);
	}

	public function execute(args:Array<String>) {
		initialCheck();

		if (args.length == 0)
			throw "missing username argument";

		if (!Utils.userExists(args[0]))
			throw "user does not exist";

		if (args.length < 2)
			throw "missing data type argument <icon, wallpaper>";

		switch (args[1]) {
			case "icon":
				if (args.length < 3)
					throw "missing icon path argument";

				if (!FileSystem.exists(args[2]))
					throw "icon path does not exist";

				var destIconPath = Globals.whiskerGreeterAvatarDir + "/" + args[0] + ".png";
				File.copy(args[2], destIconPath);
				Sys.println("copied icon to " + destIconPath);

			case "wallpaper":
				if (args.length < 3)
					throw "missing wallpaper path argument";

				if (!FileSystem.exists(args[2]))
					throw "wallpaper path does not exist";

				var destWallpaperPath = Globals.whiskerGreeterWallpaperDir + "/" + args[0] + ".png";
				File.copy(args[2], destWallpaperPath);
				Sys.println("copied wallpaper to " + destWallpaperPath);

			default:
				throw "unknown data type argument '" + args[1] + "', expected <icon, wallpaper>";
		}
	}

	function initialCheck() {
		if (!Utils.isRoot()) 
			throw "this command requires root privileges, please run with sudo";
		if (!FileSystem.exists(Globals.whiskerGreeterDir)) {
            Sys.println("greeter dir not found, creating directory... " + '(${Globals.whiskerGreeterDir})');
            FileSystem.createDirectory(Globals.whiskerGreeterDir);
		}
		if (!FileSystem.exists(Globals.whiskerGreeterAvatarDir)) {
            Sys.println("greeter avatar dir not found, creating directory... " + '(${Globals.whiskerGreeterAvatarDir})');
            FileSystem.createDirectory(Globals.whiskerGreeterAvatarDir);
		}
		if (!FileSystem.exists(Globals.whiskerGreeterWallpaperDir)) {
            Sys.println("greeter wallpaper dir not found, creating directory... " + '(${Globals.whiskerGreeterWallpaperDir})');
            FileSystem.createDirectory(Globals.whiskerGreeterWallpaperDir);
		}
	}
}
