package info.knightrcom.command {
    import info.knightrcom.event.Red5GameEvent;

    public class Red5GameCommand extends GameCommand {

        public function Red5GameCommand(number:Number, signature:String):void {
            super(Red5GameEvent.EVENT_TYPE, signature);
            this.number = number;
        }

        public static const GAME_JOIN_MATCHING_QUEUE:Red5GameCommand = new Red5GameCommand(1238940125656, "GAME_JOIN_MATCHING_QUEUE");
        public static const GAME_START:Red5GameCommand = new Red5GameCommand(1238925835609, "GAME_START");
        public static const GAME_SETTING:Red5GameCommand = new Red5GameCommand(1239345902234, "GAME_SETTING");
        public static const GAME_SETTING_FINISH:Red5GameCommand = new Red5GameCommand(1239404641281, "GAME_SETTING_FINISH");
        public static const GAME_BRING_OUT:Red5GameCommand = new Red5GameCommand(1239177903375, "GAME_BRING_OUT");
        public static const GAME_WIN:Red5GameCommand = new Red5GameCommand(1239239884328, "GAME_WIN");
        public static const GAME_WIN_AND_END:Red5GameCommand = new Red5GameCommand(1239242003812, "GAME_WIN_AND_END");
        // public static const GAME_DEADLY7_EXTINCT8:Red5GameCommand = new Red5GameCommand(1239246703678, "GAME_DEADLY7_EXTINCT8");
    }
}
