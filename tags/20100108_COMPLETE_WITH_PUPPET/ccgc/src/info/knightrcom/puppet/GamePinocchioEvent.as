package info.knightrcom.puppet
{
	import info.knightrcom.event.AbstractEvent;

	public class GamePinocchioEvent extends AbstractEvent
	{
		
		public static const GAME_START:String = "GAME_START";
		
		public static const GAME_SETTING:String = "GAME_SETTING";
		
		public static const GAME_BOUT:String = "GAME_BOUT";

		public static const GAME_END:String = "GAME_END";

		private var _incoming:String = null;

		private var _tag:Object = null;
		
		public function GamePinocchioEvent(type:String, incomingData:String, tagInfo:* = null)
		{
			super(type, incomingData);
			this._tag = tagInfo;
		}

		public function get tag():Object {
			return this._tag;
		}
	}
}
