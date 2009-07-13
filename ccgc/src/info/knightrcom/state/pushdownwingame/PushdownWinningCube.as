package info.knightrcom.state.pushdownwingame
{

	public class PushdownWinningCube
	{
		/**
		 * 
		 * @param mahjongs
		 * @param initSeq
		 * 
		 */
		public function PushdownWinningCube(mahjongs:Array, initSeq:String = null):void
		{
			this.mahjongs = mahjongs;
			this.initSeq = this.mahjongs.join(",");
			walkAllWays();
		}

		public var pongCube:PushdownWinningCube;

		public var eyeCube:PushdownWinningCube;

		public var chowCube:PushdownWinningCube;

		public var parentCube:PushdownWinningCube;

		private var mahjongs:Array;

		private var initSeq:String;

		private var currentTrack:String;

		private function walkAllWays():void {
			var oldLen = currentTrack.length;
			if (oldLen == 0) {
				// TODO 完成胡牌路径
			}
			// 碰
			if (currentTrack.replace(/^(\w+),\1,\1/, "").length <> oldLen) {
				this.pongCube = new PushdownWinningCube(mahjongs.slice(3));
			}
			// 对子
			if (currentTrack.replace(/^(\w+),\1/, "").length <> oldLen) {
				this.eyeCube = new PushdownWinningCube(mahjongs.slice(2));
			}
			// 顺子
			if (currentTrack.replace(/^([WBT])\d,\1\d,\1\d/, "").length <> oldLen) {
				var mahjongValue0:int = int(mahjongs[0].toString().replace("[WBT]", ""));
				var mahjongValue1:int = int(mahjongs[1].toString().replace("[WBT]", ""));
				var mahjongValue2:int = int(mahjongs[2].toString().replace("[WBT]", ""));
				if ((mahjongValue0 + 1 == mahjongValue1) && (mahjongValue1 + 1 == mahjongValue2)) {
					this.chowCube = new PushdownWinningCube(mahjongs.slice(2));
				}
			}
			// 非碰、对子、顺子的情况
			// TODO 完成胡牌路径
		}

		/**
		 *
		 * @param dealedMahjong
		 * @param mahjongOfPlayers
		 * @param excludedIndex
		 * @return
		 *
		 */
		private function createPong(mahjongOfPlayers:Array):Boolean
		{
			// 找刻子
			// 找对子
			// 找顺子
			return false;
		}

		/**
		 *
		 * @param dealedMahjong
		 * @param mahjongOfPlayers
		 * @param excludedIndex
		 * @return
		 *
		 */
		private function createChow(mahjongOfPlayers:Array):Boolean
		{
			// 找刻子
			// 找对子
			// 找顺子
			return false;
		}

		/**
		 *
		 * @param dealedMahjong
		 * @param mahjongOfPlayers
		 * @param excludedIndex
		 * @return
		 *
		 */
		private function createEye(mahjongOfPlayers:Array):Boolean
		{
			// 找刻子
			// 找对子
			// 找顺子
			return false;
		}

		/**
		 *
		 * @return
		 *
		 */
		private function toWinPath():String
		{
			return null;
		}
	}
}
