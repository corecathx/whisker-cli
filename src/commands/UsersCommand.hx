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
	public static function wallpaper(args:Array<String>) {
		var command = new UsersCommand();
		command.initialCheck('pkexec ' + Sys.programPath() + ' users ' + args.join(' '));
		command.setWallpaper(args);
	}
	public function setWallpaper(args:Array<String>) {
		if (args.length < 3)
			throw "missing wallpaper path argument";

		if (!FileSystem.exists(args[2]))
			throw "wallpaper path does not exist";

		var destWallpaperPath = Globals.whiskerGreeterWallpaperDir + "/" + args[0] + ".png";
		File.copy(args[2], destWallpaperPath);
		Sys.println("copied wallpaper to " + destWallpaperPath);
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
				setWallpaper(args);

			default:
				throw "unknown data type argument '" + args[1] + "', expected <icon, wallpaper>";
		}
	}

	public function initialCheck(customCommand:String = "") {
		if (!Utils.isRoot()) {
			var command = customCommand != "" ? customCommand : 'pkexec ' + Sys.programPath() + ' ' + Sys.args().join(' ');
			Sys.println("this command requires root privileges, relaunching with pkexec...");
			Sys.println(">> " + command);
			Sys.command(command);
			Sys.exit(0);
		}
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
