package;

import claw.App;
import commands.*;
import haxe.Timer;

/**
 * Whisker CLI thing.
 */
class Main {
	static var _startTime:Float = Timer.stamp();

	static function main():Void {
		var args:Array<String> = Sys.args();

		var customFolderIndex:Int = args.indexOf("-p");

		if (customFolderIndex != -1 && customFolderIndex + 1 < args.length) {
			Globals.whiskerQsFolder = args[customFolderIndex + 1];
			args.splice(customFolderIndex, 2);
		}

		var app:App = new App();

		app.name = "whisker";
		app.desc = "cli for whisker shell";
		app.version = "0.6";

		// shell
		app.addCommand(new ShellCommand());
		app.addCommand(new WallpaperCommand());
		app.addCommand(new ScreenCommand());
		app.addCommand(new NotifyCommand());
		app.addCommand(new IpcCommand());

		// configuration
		app.addCommand(new PreferencesCommand());
		app.addCommand(new UsersCommand());
		app.addCommand(new IntegrationCommand());

		// utilities
		app.addCommand(new ListsCommand());
		app.addCommand(new ColorCommand());
		app.addCommand(new WelcomeCommand());
		app.addCommand(new VersionCommand());

		// miscellaneous
		app.addCommand(new WawaCommand());

		app.run();
	}
}