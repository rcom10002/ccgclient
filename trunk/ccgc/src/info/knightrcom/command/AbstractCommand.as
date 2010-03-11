package info.knightrcom.command {

    public class AbstractCommand {
        public var type:int;
        public var number:Number;
        public var signature:String;

        public function AbstractCommand(type:int, signature:String) {
            this.type = type;
            this.signature = signature;
        }
    }
}