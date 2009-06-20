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
					displayName="1分";
					break;
				case TWO_RUSH:
					displayName="2分";
					break;
				case THREE_RUSH:
					displayName="3分";
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
			return ["不叫", "1分", "2分", "3分"];
		}

		/**
		 * 有人选择1分
		 *
		 * @return
		 *
		 */
		public static function getRushStyle():Array
		{
			return ["不叫", null, "2分", "3分"];
		}

		/**
		 * 有人选择2分
		 *
		 * @return
		 *
		 */
		public static function getDeadlyRushStyle():Array
		{
			return ["不叫", null, null, "3分"];
		}

	}
}
