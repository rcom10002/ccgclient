package info.knightrcom.event {

    public class GameEvent extends AbstractEvent {

        public function GameEvent(type:String, incomingData:String = null) {
            super(type, incomingData);
        }

        // 事件类型定义开始
        public static const GAME_STARTED:String = "GAME_STARTED";
        public static const GAME_FIRST_PLAY:String = "GAME_FIRST_PLAY";
        public static const GAME_WAIT:String = "GAME_WAIT";
        public static const GAME_CREATE:String = "GAME_CREATE";
        public static const GAME_SETTING_UPDATE:String = "GAME_SETTING_UPDATE";
        public static const GAME_SETTING_OVER:String = "GAME_SETTING_OVER";
        public static const GAME_BRING_OUT:String = "GAME_BRING_OUT";
        public static const GAME_INTERRUPTED:String = "GAME_INTERRUPTED";
        public static const GAME_WINNER_PRODUCED:String = "GAME_WINNER_PRODUCED";
        public static const GAME_OVER:String = "GAME_OVER";
        // 事件类型定义结束
    }
}
