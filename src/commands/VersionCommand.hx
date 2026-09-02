package commands;

import claw.Command;

class VersionCommand implements Command {
    public var name:String = "version";
	public var description:String = "outputs current whisker version";
	public var arguments:Array<String> = [];

    public function new() {}

	public function execute(args:Array<String>) {
        Sys.println('whisker ${Whisker.VERSION} (${Whisker.COMMIT})');
	}
}
