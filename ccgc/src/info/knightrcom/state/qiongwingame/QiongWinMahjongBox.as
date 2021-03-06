package info.knightrcom.state.qiongwingame
{

	public class QiongWinMahjongBox
	{
		public function QiongWinMahjongBox()
		{
		    this.mjOnTable = new Array();
		}

		/**
		 * 当前玩家们手中的麻将
		 */
		private var mjOfPlayers:Array = new Array(4);

		/**
		 * 当前玩家们手中的麻将
		 */
		private var mjOfDais:Array = new Array(new Array(), new Array(), new Array(), new Array());

		/**
		 * 尚未使用过的麻将
		 */
		private var mjSpared:Array;

		/**
		 * 已经打出的麻将
		 */
		private var mjOnTable:Array;

		/**
		 *
		 * @param mahjongsOfPlayers
		 *
		 */
		public function set mahjongsOfPlayers(mahjongsOfPlayers:Array):void
		{
			for (var i:int = 0; i < mahjongsOfPlayers.length; i++) {
			    this.mjOfPlayers[i] = mahjongsOfPlayers[i].toString().split(",");
			}
		}

		/**
		 *
		 * @param mahjongSpared
		 *
		 */
		public function set mahjongsSpared(mahjongSpared:Array):void
		{
			this.mjSpared = mahjongSpared;
		}

		/**
		 *
		 * @param mahjongsOnTable
		 *
		 */
		public function set mahjongsOnTable(mahjongsOnTable:Array):void
		{
			this.mjOnTable = mahjongsOnTable;
		}

		/**
		 *
		 * @return
		 *
		 */
		public function get mahjongsOfPlayers():Array
		{
			return this.mjOfPlayers;
		}

		/**
		 *
		 * @return
		 *
		 */
		public function get mahjongsOfDais():Array
		{
			return this.mjOfDais;
		}

		/**
		 *
		 * @return
		 *
		 */
		public function get mahjongsSpared():Array
		{
			return this.mjSpared;
		}

		/**
		 *
		 * @return
		 *
		 */
		public function get mahjongsOnTable():Array
		{
			return this.mjOnTable;
		}

		/**
		 * 
		 * 随机出牌
		 * 
		 */
		public function randomMahjong():String {
		    if (mjSpared.length == 0) {
		        return null;
		    }
			// 未使用牌中选出第一张牌
			return this.mjSpared.shift();
		}

		/**
		 * 
		 * 将玩家操作过的牌移除()
		 * 
		 * @param index
		 * @param mahjongValues 吃碰杠牌的组合
		 * @return 
		 * 
		 */
		public function moveMahjongToDais(index:int, mahjongValues:String):Array {
			for each (var eachMahjong:String in mahjongValues.split(",")) {
		    	// 从玩家手中删除牌序中含有的牌
				var mjIndex:int = (mjOfPlayers[index] as Array).indexOf(eachMahjong);
				if (mjIndex < 0) {
				    trace("WARNING: THERE IS A NEGATIVE INDEX FOUND WHEN MOVE A MAHJONG TO THE DAIS!")
				    continue;
				}
				(mjOfPlayers[index] as Array).splice(mjIndex, 1);
    			// 为玩家添加被操作牌
				(mjOfDais[index] as Array).push(eachMahjong);
			}
			return mjOfDais[index] as Array;
		}

		/**
		 * 
		 * 为玩家添加手牌(杠牌也需要调用该方法)
		 * 
		 * @param index
		 * @param mahjongValue
		 * @return 
		 * 
		 */
		public function importMahjong(index:int, mahjongValue:String):Array {
			(mjOfPlayers[index] as Array).push(mahjongValue);
			return mjOfPlayers[index] as Array;
		}

		/**
		 * 
		 * 从玩家手牌中删除指定的牌
		 * 
		 * @param index
		 * @param mahjongValue
		 * @return 
		 * 
		 */
		public function exportMahjong(index:int, mahjongValue:String):Array {
			// 从玩家手中的牌删除打出的牌
			var targetPos:int = (mjOfPlayers[index] as Array).indexOf(mahjongValue);
			if (targetPos < 0) {
			    return null;
			}
			(mjOfPlayers[index] as Array).splice(targetPos, 1);
			return mjOfPlayers[index] as Array;
		}

		/**
		 * 
		 * 将玩家打出的牌添加到桌面
		 * 
		 * @param mahjongValue
		 * 
		 */
		public function discardMahjong(mahjongValue:String):void {
			// 向桌面的麻将中添加新打出的牌
			this.mjOnTable.push(mahjongValue);
		}
	}
}
