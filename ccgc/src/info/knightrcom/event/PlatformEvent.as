package info.knightrcom.event {
    import flash.events.Event;

    public class PlatformEvent extends AbstractEvent {
        public static const EVENT_TYPE:uint = 0;

        public function PlatformEvent(type:String, incomingData:String = null) {
            super(type, incomingData);
        }

        // 通信事件类型定义开始
        public static const SERVER_CONNECTED:String = "SERVER_CONNECTED";
        public static const SERVER_DISCONNECTED:String = "SERVER_DISCONNECTED";
        public static const SERVER_SESSION_TIMED_OUT:String = "SERVER_SESSION_TIMED_OUT";
        public static const SERVER_IO_ERROR:String = "SERVER_IO_ERROR";
        public static const SERVER_SECURITY_ERROR:String = "SERVER_SECURITY_ERROR";

        // 应用事件类型定义开始
        public static const PLATFORM_ENVIRONMENT_INIT:String = "PLATFORM_ENVIRONMENT_INIT";
        public static const PLATFORM_MESSAGE_BROADCASTED:String = "PLATFORM_MESSAGE_BROADCASTED";
    }
}