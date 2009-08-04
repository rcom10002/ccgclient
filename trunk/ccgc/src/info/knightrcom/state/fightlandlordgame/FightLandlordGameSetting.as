package info.knightrcom.state.fightlandlordgame
{
	import mx.formatters.SwitchSymbolFormatter;

	/**
	 *
	 * 斗地主开局游戏设置
	 *
	 */
	public class FightLandlordGameSetting
	{

		public function FightLandlordGameSetting()
		{
		}

		public static const NO_RUSH:int=0;

		public static const ONE_RUSH:int=1;

		public static const TWO_RUSH:int=2;

		public static const THREE_RUSH:int=3;

		public static function getDisplayName(fightlandlordGameSetting:int):String
		{
			var displayName:String=null;
			switch (fightlandlordGameSetting)
			{
				case NO_RUSH:
					displayName="不叫";
					break;
				case ONE_RUSH:
					displayName="青龙";
					break;
				case TWO_RUSH:
					displayName="白虎";
					break;
				case THREE_RUSH:
					displayName="朱雀";
					break;
				default:
					throw Error("游戏设置参数错误！");
			}
			return displayName;
		}

		/**
		 * 无人选择设置
		 *
		 * @return
		 *
		 */
		public static function getNoRushStyle():Array
		{
			return ["不叫", "青龙", "白虎", "朱雀"];
		}

		/**
		 * 有人选择青龙
		 *
		 * @return
		 *
		 */
		public static function getRushStyle():Array
		{
			return ["不叫", null, "白虎", "朱雀"];
		}

		/**
		 * 有人选择白虎
		 *
		 * @return
		 *
		 */
		public static function getDeadlyRushStyle():Array
		{
			return ["不叫", null, null, "朱雀"];
		}

	}
}
