package info.knightrcom.event {

    public class Red5GameEvent extends GameEvent {

        public static const EVENT_TYPE:uint = 2;

        /**
         *
         * @param type
         * @param incomingData
         *
         */
        public function Red5GameEvent(type:String, incomingData:String = null) {
            super(EVENT_TYPE + type, incomingData);
        }

    }
}
