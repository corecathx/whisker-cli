package claw;

class ClawHelpers {
    public static function padRight(str:String, length:Int):String
		return str + StringTools.rpad("", " ", Std.int(Math.max(0, length - str.length)));

	public static function prompt(question:String, accepts:Array<String>, defaultIndex:Int = 0):String {
		var lastAnswer:String = '';

		while (!accepts.contains(lastAnswer)) {
			var displayOptions = [];
			for (i in 0...accepts.length) {
				if (i == defaultIndex)
					displayOptions.push(accepts[i].toUpperCase());
				else
					displayOptions.push(accepts[i]);
			}

			Sys.print('$question [${displayOptions.join("/")}]: ');
			var answer:String = Sys.stdin().readLine();

			if (answer == "" && defaultIndex >= 0 && defaultIndex < accepts.length)
				lastAnswer = accepts[defaultIndex].toLowerCase();
			else
				lastAnswer = answer.toLowerCase();
		}

		return lastAnswer;
	}
}