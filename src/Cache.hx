package;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

class Cache {
    static var cacheDir:String = Sys.getEnv("HOME") + "/.cache/whisker";

    public static function read(name:String):Dynamic {
        var path = getPath(name);

        if (!FileSystem.exists(path))
            return null;

        try {
            return Json.parse(File.getContent(path));
        } catch (e:Dynamic) {
            return null;
        }
    }

    public static function write(name:String, value:Dynamic):Bool {
        try {
            if (!FileSystem.exists(cacheDir))
                FileSystem.createDirectory(cacheDir);

            var path = getPath(name);
            var tempPath = path + ".tmp";

            File.saveContent(tempPath, Json.stringify(value, null, "  "));
            FileSystem.rename(tempPath, path);
            return true;
        } catch (e:Dynamic) {
            return false;
        }
    }

    static function getPath(name:String):String {
        return cacheDir + "/" + name + ".json";
    }
}