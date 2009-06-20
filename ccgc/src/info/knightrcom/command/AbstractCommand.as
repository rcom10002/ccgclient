package info.knightrcom.command {

    public class AbstractCommand {
        public var type:uint;
        public var number:Number;
        public var signature:String;

        public function AbstractCommand(type:uint, signature:String) {
            this.type = type;
            this.signature = signature;
        }
    }
}