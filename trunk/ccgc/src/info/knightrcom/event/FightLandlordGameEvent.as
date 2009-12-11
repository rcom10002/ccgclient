package info.knightrcom.event
{

	public class FightLandlordGameEvent extends GameEvent
	{

		public static const EVENT_TYPE:uint=3;
		/** 游戏设置完后追加的底牌处理事件 */
		public static const GAME_SETTING_UPDATE_FINISH:String="GAME_SETTING_UPDATE_FINISH";
		/** 游戏积分加倍事件 */
		public static const GAME_BOMB:String="GAME_BOMB";

		/**
		 *
		 * @param type
		 * @param incomingData
		 *
		 */
		public function FightLandlordGameEvent(type:String, incomingData:String=null)
		{
			super(EVENT_TYPE + type, incomingData);
		}

	}
}