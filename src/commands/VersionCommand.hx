package commands;

import claw.Command;
import haxe.Http;
import haxe.Json;

class VersionCommand implements Command {
	public var name:String = "version";
	public var description:String = "outputs current whisker version";
	public var arguments:Array<String> = ["--check-update", "--json", "--force"];

	static inline var CACHE_TTL:Float = 30 * 60 * 1000;

	public function new() {}

	public function execute(args:Array<String>) {
		var json = args.contains("--json");
		var checkUpdate = args.contains("--check-update") || json;

		if (!json)
			Sys.println('whisker ${Whisker.VERSION} (${Whisker.COMMIT})');

		if (!checkUpdate)
			return;

		var cached:Dynamic = Cache.read("githubCompare");
		var cachedUpdates:Array<Dynamic> = cached != null ? Reflect.field(cached, "updates") : null;
		var fetchedAt:Float = 0;
		var force = args.contains("--force");

		if (cached != null && Reflect.hasField(cached, "fetchedAt"))
			fetchedAt = Std.parseFloat(Std.string(Reflect.field(cached, "fetchedAt")));

		if (!force && cachedUpdates != null && fetchedAt > 0 && Date.now().getTime() - fetchedAt < CACHE_TTL) {
			outputUpdates(cachedUpdates, json, true);
			return;
		}

		var response:String = null;
		var error:String = null;
		var status:Int = 0;
		var http = new Http(Globals.githubCompareApiURL + Whisker.COMMIT + "...main");

		http.setHeader("User-Agent", "Whisker-CLI");
		http.onData = data -> response = data;
		http.onError = message -> error = message;
		http.onStatus = code -> status = code;

		try {
			http.request(false);
		} catch (e:Dynamic) {
			error = Std.string(e);
		}

		if (error != null || status >= 400 || response == null) {
			if (error == null)
				error = status >= 400 ? 'GitHub API returned HTTP ${status}.' : "No response received from GitHub.";

			outputError(error, cachedUpdates, json);
			return;
		}

		try {
			var result:Dynamic = Json.parse(response);

			if (Reflect.hasField(result, "message")) {
				error = Reflect.field(result, "message");
				outputError(error, cachedUpdates, json);
				return;
			}

			var updates:Array<Dynamic> = Reflect.field(result, "commits");

			if (updates == null)
				throw "GitHub response does not contain a commits array.";

			updates.reverse();

			Cache.write("githubCompare", {
				fetchedAt: Date.now().getTime(),
				updates: updates
			});

			outputUpdates(updates, json, false);
		} catch (e:Dynamic) {
			outputError('Failed to parse GitHub response: ${Std.string(e)}', cachedUpdates, json);
		}
	}

	function outputError(error:String, cachedUpdates:Array<Dynamic>, json:Bool):Void {
		if (cachedUpdates != null) {
			if (json) {
				printJson(cachedUpdates, error, true);
			} else {
				Sys.println("failed to check for updates; using cached data.");
				Sys.println(error);
				printUpdates(cachedUpdates);
			}
			return;
		}

		if (json) {
			printJson([], error);
		} else {
			Sys.println("failed to check for updates.");
			Sys.println(error);
		}
	}

	function outputUpdates(updates:Array<Dynamic>, json:Bool, cached:Bool):Void {
		if (json) {
			printJson(updates, null, cached);
			return;
		}

		if (cached)
			Sys.println("using cached update information.");

		printUpdates(updates);
	}

	function printUpdates(updates:Array<Dynamic>):Void {
		Sys.println("");
		Sys.println('found ${updates.length} updates:');

		for (commit in updates) {
			var hash:String = commit.sha;
			var message:String = commit.commit.message;
			message = message.split("\n")[0];

			Sys.println('  ${hash.substr(0, 7)} - ${message}');
		}
	}

	function printJson(updates:Array<Dynamic>, ?error:String, cached:Bool = false):Void {
		var result:Dynamic = {
			version: Whisker.VERSION,
			commit: Whisker.COMMIT,
			updates: updates
		};

		if (error != null)
			Reflect.setField(result, "error", error);

		if (cached)
			Reflect.setField(result, "cached", true);

		Sys.println(Json.stringify(result, null, "  "));
	}
}
