package info.knightrcom.event {
    import flash.events.Event;

    public class PlayerEvent extends AbstractEvent {
        public static const EVENT_TYPE:uint = 1;

        public function PlayerEvent(type:String, incomingData:String = null) {
            super(type, incomingData);
        }

        // 事件类型定义开始
        public static const LOGIN_SUCCESS:String = "LOGIN_SUCCESS";
        public static const LOGIN_ERROR_USERNAME_OR_PASSWORD:String = "LOGIN_ERROR_USERNAME_OR_PASSWORD";
        public static const LOGIN_USER_ALREADY_ONLINE:String = "LOGIN_USER_ALREADY_ONLINE";
        public static const LOGIN_MAX_CONNECTION_LIMIT:String = "LOGIN_MAX_CONNECTION_LIMIT";
        public static const LOBBY_ENTER_ROOM:String = "LOBBY_ENTER_ROOM";
        public static const LOBBY_LEAVE_ROOM:String = "LOBBY_LEAVE_ROOM";
    }
}
