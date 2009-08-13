package info.knightrcom.command {
    import info.knightrcom.event.QiongWinGameEvent;

    public class QiongWinGameCommand extends GameCommand {

        public function QiongWinGameCommand(number:Number, signature:String):void {
            super(QiongWinGameEvent.EVENT_TYPE, signature);
            this.number = number;
        }

        public static const GAME_JOIN_MATCHING_QUEUE:QiongWinGameCommand = new QiongWinGameCommand(1238940125656, "GAME_JOIN_MATCHING_QUEUE");
        public static const GAME_START:QiongWinGameCommand = new QiongWinGameCommand(1238925835609, "GAME_START");
        public static const GAME_SETTING:QiongWinGameCommand = new QiongWinGameCommand(1239345902234, "GAME_SETTING");
        public static const GAME_SETTING_FINISH:QiongWinGameCommand = new QiongWinGameCommand(1239404641281, "GAME_SETTING_FINISH");
        public static const GAME_BRING_OUT:QiongWinGameCommand = new QiongWinGameCommand(1239177903375, "GAME_BRING_OUT");
        public static const GAME_WIN:QiongWinGameCommand = new QiongWinGameCommand(1239239884328, "GAME_WIN");
        public static const GAME_WIN_AND_END:QiongWinGameCommand = new QiongWinGameCommand(1239242003812, "GAME_WIN_AND_END");
    }
}
