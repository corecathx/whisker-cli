package commands;

import claw.App;
import claw.Command;

class NotifyCommand implements Command {
    public var name:String = "notify";
    public var description:String = "send notification";
    public var arguments:Array<String> = ['title', 'body'];

    public function new() { }

    public function execute(args:Array<String>) {
        if (App.instance == null)
            throw "[INTERNAL] App instance is null.";
        if (args.length == 0)
            throw "missing arguments [title, body]";
        if (args.length == 1)
            throw "missing arguments [body]";
        Utils.notify(App.instance.name, Globals.whiskerQsFolder + "/logo.png", args[0], args[1]);
    }
}
