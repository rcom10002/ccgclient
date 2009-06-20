package info.knightrcom.util {
    import flash.events.Event;

    public class PlatformAlertEvent extends Event {
        public var detail:String = "";

        public function PlatformAlertEvent(type:String, detail:String = "", bubbles:Boolean = false, cancelable:Boolean = false) {
            this.detail = detail;
            super(type, bubbles, cancelable);
        }

    }
}