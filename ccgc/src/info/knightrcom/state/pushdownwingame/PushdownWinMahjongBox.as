package info.knightrcom.state.pushdownwingame
{

	public class PushdownWinMahjongBox
	{
		public function PushdownWinMahjongBox()
		{
		}
// mahjongsOfPlayers:Array, mahjongSpared:Array, mahjongsOnTable:Array
		/**
		 * 当前玩家们手中的麻将
		 */
		private var mjOfPlayers:Array;

		/**
		 * 尚未使用过的麻将
		 */
		private var mjSpared:Array;

		/**
		 * 已经打出的麻将
		 */
		private var mjOnTable:Array;

		/**
		 * 最后一次操作时的玩家索引
		 */
		private var lastPlayerIndex:int

		/**
		 *
		 * @param mahjongsOfPlayers
		 *
		 */
		public function set mahjongsOfPlayers(mahjongsOfPlayers:Array):void
		{
			this.mjOfPlayers=mahjongsOfPlayers;
		}

		/**
		 *
		 * @param mahjongSpared
		 *
		 */
		public function set mahjongsSpared(mahjongSpared:Array):void
		{
			this.mjSpared=mahjongSpared;
		}

		/**
		 *
		 * @param mahjongsOnTable
		 *
		 */
		public function set mahjongsOnTable(mahjongsOnTable:Array):void
		{
			this.mjOnTable=mahjongsOnTable;
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
		 * @return
		 *
		 */
		public function get lastIndex():int
		{
			return this.lastPlayerIndex;
		}

		/**
		 * 
		 * @param index
		 * 
		 */
		public function rand(index:int):String {
			this.lastPlayerIndex = index;
			// 未使用牌中选出第一张牌
			var dealedMj:String = this.mjSpared.shift();
			// 将选中的牌放入玩家牌中
			(mjOfPlayers[index] as Array).push(dealedMj);
			// 将玩家手中的牌进行排序
			mjOfPlayers[index] = PushdownWinGame.sortMahjongs((mjOfPlayers[index] as Array).join(","));
			return dealedMj;
		}

		/**
		 * 
		 * @param index
		 * @param dealedValue
		 * 
		 */
		public function deal(index:int, dealedValue:String):void {
			this.lastPlayerIndex = index;
			// 定位要打出的牌的索引
			var targetPos:int = (mjOfPlayers[index] as Array).indexOf(dealedValue);
			mjOfPlayers[index] = (mjOfPlayers[index] as Array).slice(targetPos, targetPos);
			// 向打出的麻将中添加新打出的牌
			this.mjOnTable.push(dealedValue);
		}
	}
}