package info.knightrcom.event {

    public class PushdownWinGameEvent extends GameEvent {

        public static const EVENT_TYPE:uint = 2;

        /**
         *
         * @param type
         * @param incomingData
         *
         */
        public function PushdownWinGameEvent(type:String, incomingData:String = null) {
            super(EVENT_TYPE + type, incomingData);
        }

    }
}
