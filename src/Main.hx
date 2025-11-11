package;

import commands.*;
import haxe.Timer;
import haxe.Exception;
import sys.io.Process;
import sys.io.File;
import sys.FileSystem;
import claw.App;

using StringTools;
/**
 * Whisker CLI thing
 */
class Main {
	static var _startTime:Float = Timer.stamp();

	static function main() {
		var args = Sys.args();

		var customFolderIndex = args.indexOf("-p");
		if (customFolderIndex != -1 && customFolderIndex + 1 < args.length) {
			Globals.whiskerQsFolder = args[customFolderIndex + 1];
			args.splice(customFolderIndex, 2);
		}
		var app:App = new App();
		app.name = 'whisker';
		app.desc = 'a helper script for whisker shell';
		app.version = "0.5";
		app.addCommand(new ShellCommand());
		app.addCommand(new IntegrationCommand());
		app.addCommand(new PreferencesCommand());
		app.addCommand(new WallpapersCommand());
		app.addCommand(new ScreenCommand());
		app.addCommand(new NotifyCommand());
		app.addCommand(new ListsCommand());
		app.addCommand(new WawaCommand());
		app.addCommand(new WelcomeCommand());
		app.addCommand(new IpcCommand());

		app.run();
	}
}
