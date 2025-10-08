package claw;

/**
 * Interface for Claw Commands.
 */
interface Command {
    /**
     * Command's name.
     */
    public var name:String;
    /**
     * Command's description
     */
    public var description:String;
    /**
     * Command's accepted arguments.
     */
    public var arguments:Array<String>;

    /**
     * Callback when the command gets executed.
     * @param args User defined arguments.
     */
    public function execute(args:Array<String>):Void;
}