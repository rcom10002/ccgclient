package info.knightrcom.command {
    import info.knightrcom.event.PlayerEvent;

    public class PlayerCommand extends AbstractCommand {

        public function PlayerCommand(number:Number, signature:String):void {
            super(PlayerEvent.EVENT_TYPE, signature);
            this.number = number;
        }

        public static const LOGIN_SIGN_IN:PlayerCommand = new PlayerCommand(1238634889125, "LOGIN_SIGN_IN");
        public static const LOBBY_ENTER_ROOM:PlayerCommand = new PlayerCommand(1238634910671, "LOBBY_ENTER_ROOM");
        public static const LOBBY_LEAVE_ROOM:PlayerCommand = new PlayerCommand(1238634918281, "LOBBY_LEAVE_ROOM");


    }
}
