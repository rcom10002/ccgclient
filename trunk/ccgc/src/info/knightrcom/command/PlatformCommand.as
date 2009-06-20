package info.knightrcom.command {
    import info.knightrcom.event.PlatformEvent;

    public class PlatformCommand extends AbstractCommand {

        public function PlatformCommand(number:Number, signature:String):void {
            super(PlatformEvent.EVENT_TYPE, signature);
            this.number = number;
        }

        public static const PLATFORM_REQUEST_ENVIRONMENT:PlatformCommand = new PlatformCommand(1238634834343, "PLATFORM_REQUEST_ENVIRONMENT");
    }
}
