package info.knightrcom.event {
    import flash.events.Event;
    
    import info.knightrcom.util.Logger;

    public class AbstractEvent extends Event {

        public var incomingData:String;

        public function AbstractEvent(type:String, incomingData:String = null) {
            super(type, false, false);
            this.incomingData = incomingData;
            Logger.debug(this + ": " + type + "," + incomingData);
        }

    }
}
