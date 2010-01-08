package info.knightrcom.event {

    public class QiongWinGameEvent extends GameEvent {

        public static const EVENT_TYPE:uint = 5;

        /**
         *
         * @param type
         * @param incomingData
         *
         */
        public function QiongWinGameEvent(type:String, incomingData:String = null) {
            super(EVENT_TYPE + type, incomingData);
        }

    }
}
