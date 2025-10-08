package commands;

import claw.App;
import claw.Command;

class NotifyCommand implements Command {
    public var name:String = "notify";
    public var description:String = "send notification";
    public var arguments:Array<String> = [];

    public function execute(args:Array<String>) {
        if (App.instance == null)
            throw "error: App instance is null.";
        Utils.notify(App.instance.name, Globals.whiskerQsFolder + "/logo.png", 'wawa', 'cat');
    }
}