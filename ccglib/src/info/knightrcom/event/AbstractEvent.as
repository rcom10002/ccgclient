package info.knightrcom.event {
    import flash.events.Event;

    public class AbstractEvent extends Event {
        public var incomingData:String;

        public function AbstractEvent(type:String, incomingData:String = null) {
            super(type, false, false);
            this.incomingData = incomingData;
            trace("事件名称[" + typeof(this) + "]：" + type + "\n事件内容：" + incomingData);
        }

    }
}
