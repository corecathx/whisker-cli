package;

@:publicFields
class Globals {
    static var userHomeDir:String = Sys.getEnv("HOME");
	static var userWallDir:String = userHomeDir + "/Pictures/wallpapers";

	static var userCaptureDir:String = userHomeDir + "/Pictures/screenshots";
	static var userRecordsDir:String = userHomeDir + "/Videos/screenrecords";

	static var whiskerConfigDir:String = userHomeDir + "/.config/whisker";
	static var whiskerLocalDir:String = userHomeDir + "/.local/share/whisker";

	static var whiskerLockFile:String = "/tmp/whisker.lck";
	static var whiskerWelcomeLockFile:String = "/tmp/whisker-welcome.lck";

	static var whiskerQsFolder:String = "/usr/share/whisker";
	static var whiskerUserPref:String = whiskerConfigDir + "/preferences.json";
	static var whiskerCSchemes:String = whiskerLocalDir + "/schemes.json";

	// the path where whisker stores its hyprland integration files
	// which later injects it to user's hyprland config
	static var whiskerHyprlandConfig:String = whiskerLocalDir + "/whisker-hyprland.conf";

}
