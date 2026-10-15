package commands;

import claw.Command;
import haxe.Http;
import haxe.Json;

class VersionCommand implements Command {
    public var name:String = "version";
    public var description:String = "outputs current whisker version";
    public var arguments:Array<String> = ["--check-update"];

    public function new() {}

    public function execute(args:Array<String>) {
        Sys.println('whisker ${Whisker.VERSION} (${Whisker.COMMIT})');

        if (!args.contains("--check-update")) return;

        var response:String = null;
        var error:String = null;
        var http = new Http(Globals.githubCompareApiURL + Whisker.COMMIT + "...main");

        http.setHeader("User-Agent", "Whisker-CLI");
        http.onData = data -> response = data;
        http.onError = message -> error = message;
        http.request(false);

        if (error != null || response == null) {
            Sys.println("failed to check for updates.");
            if (error != null) Sys.println(error);
            return;
        }

        try {
            var result:Dynamic = Json.parse(response);
            var commits:Array<Dynamic> = result.commits;
			commits.reverse();

            Sys.println("");
            Sys.println('found ${commits.length} updates:');

            for (commit in commits) {
                var hash:String = commit.sha;
                var message:String = commit.commit.message;
                message = message.split("\n")[0];

                Sys.println('  ${hash.substr(0, 7)} - ${message}');
            }
        } catch (e:Dynamic) {
            Sys.println("failed to parse GitHub response.");
        }
    }
}