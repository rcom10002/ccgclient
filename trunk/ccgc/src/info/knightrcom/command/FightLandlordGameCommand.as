package info.knightrcom.command
{
	import info.knightrcom.event.FightLandlordGameEvent;

	public class FightLandlordGameCommand extends GameCommand
	{

		public function FightLandlordGameCommand(number:Number, signature:String):void
		{
			super(FightLandlordGameEvent.EVENT_TYPE, signature);
			this.number=number;
		}

		public static const GAME_JOIN_MATCHING_QUEUE:FightLandlordGameCommand=new FightLandlordGameCommand(1241418439031, "GAME_JOIN_MATCHING_QUEUE");
		public static const GAME_START:FightLandlordGameCommand=new FightLandlordGameCommand(1241418447968, "GAME_START");
		public static const GAME_SETTING:FightLandlordGameCommand=new FightLandlordGameCommand(1241418452421, "GAME_SETTING");
		public static const GAME_SETTING_FINISH:FightLandlordGameCommand=new FightLandlordGameCommand(1241418456562, "GAME_SETTING_FINISH");
		public static const GAME_BRING_OUT:FightLandlordGameCommand=new FightLandlordGameCommand(1241418459796, "GAME_BRING_OUT");
		public static const GAME_WIN:FightLandlordGameCommand=new FightLandlordGameCommand(1241418465156, "GAME_WIN");
		public static const GAME_WIN_AND_END:FightLandlordGameCommand=new FightLandlordGameCommand(1241418470984, "GAME_WIN_AND_END");
		public static const GAME_BOMB:FightLandlordGameCommand=new FightLandlordGameCommand(1242181074828, "GAME_BOMB");
		public static const GAME_SETTING_UPDATE_FINISH:FightLandlordGameCommand=new FightLandlordGameCommand(1271584990593, "GAME_SETTING_UPDATE_FINISH");
	}
}
