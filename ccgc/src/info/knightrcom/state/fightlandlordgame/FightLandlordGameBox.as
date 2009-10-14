package info.knightrcom.state.fightlandlordgame
{
	public class FightLandlordGameBox
	{
		public function FightLandlordGameBox()
		{
		}

		/**
		 * 当前玩家们手中的牌
		 */
		private var _cardsOfPlayers:Array = new Array(4);

		/**
		 *
		 * @param cardsOfPlayers
		 *
		 */
		public function set cardsOfPlayers(initCardsOfPlayers:Array):void
		{
			for (var i:int = 0; i < initCardsOfPlayers.length; i++) {
			    this._cardsOfPlayers[i] = initCardsOfPlayers[i].toString().split(",");
			}
		}

		/**
		 *
		 * @return
		 *
		 */
		public function get cardsOfPlayers():Array
		{
			return this._cardsOfPlayers;
		}

		/**
		 * 
		 * 从玩家手牌中删除指定的牌
		 * 
		 * @param index
		 * @param cardValue
		 * @return 
		 * 
		 */
		public function exportPoker(index:int, cardValue:String):Array {
			// 从玩家手中的牌删除打出的牌
			var targetPos:int = (_cardsOfPlayers[index] as Array).indexOf(cardValue);
			if (targetPos < 0) {
			    return null;
			}
			(_cardsOfPlayers[index] as Array).splice(targetPos, 1);
			return _cardsOfPlayers[index] as Array;
		}
	}
}