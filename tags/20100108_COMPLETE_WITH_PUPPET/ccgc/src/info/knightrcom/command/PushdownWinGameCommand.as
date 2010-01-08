package info.knightrcom.command {
    import info.knightrcom.event.PushdownWinGameEvent;

    public class PushdownWinGameCommand extends GameCommand {

        public function PushdownWinGameCommand(number:Number, signature:String):void {
            super(PushdownWinGameEvent.EVENT_TYPE, signature);
            this.number = number;
        }

        public static const GAME_JOIN_MATCHING_QUEUE:PushdownWinGameCommand = new PushdownWinGameCommand(1238940125656, "GAME_JOIN_MATCHING_QUEUE");
        public static const GAME_START:PushdownWinGameCommand = new PushdownWinGameCommand(1238925835609, "GAME_START");
        public static const GAME_SETTING:PushdownWinGameCommand = new PushdownWinGameCommand(1239345902234, "GAME_SETTING");
        public static const GAME_SETTING_FINISH:PushdownWinGameCommand = new PushdownWinGameCommand(1239404641281, "GAME_SETTING_FINISH");
        public static const GAME_BRING_OUT:PushdownWinGameCommand = new PushdownWinGameCommand(1239177903375, "GAME_BRING_OUT");
        public static const GAME_WIN:PushdownWinGameCommand = new PushdownWinGameCommand(1239239884328, "GAME_WIN");
        public static const GAME_WIN_AND_END:PushdownWinGameCommand = new PushdownWinGameCommand(1239242003812, "GAME_WIN_AND_END");
    }
}
