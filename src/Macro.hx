package;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class Macro {
	#if macro
	static function requireEnv(name:String):String {
		var value = Sys.getEnv(name);

		if (value == null || value.trim() == "") {
			Context.error(
				'Missing required environment variable: $name',
				Context.currentPos()
			);
		}

		return value;
	}
	#end

	public static macro function getVersion():Expr {
		return macro $v{requireEnv("WHISKER_VERSION")};
	}

	public static macro function getCommit():Expr {
		return macro $v{requireEnv("WHISKER_COMMIT")};
	}
}