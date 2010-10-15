package info.knightrcom.state.pushdownwingame
{

	public class PushdownWinMahjongBox
	{
		public function PushdownWinMahjongBox()
		{
		    this.mjOnTable = [];
		}

		/**
		 * 当前玩家们手中的麻将
		 */
		private var mjOfPlayers:Array = new Array(4);

		/**
		 * 当前玩家们亮出的麻将
		 */
		private var mjOfDais:Array = [[], [], [], []];

        /**
         * 当前玩家们亮出的麻将历史记录，以便胡牌时计算积分使用
         */
        private var mjOfDaisHistory:Array = [[], [], [], []];

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
        public function get mahjongsStringOfPlayers():String
        {
            var mahjongArr:Array = [];
            for each (var eachMahjongs:String in [this.mjOfPlayers[0].toString(), this.mjOfDais[0].toString(),
                                                  this.mjOfPlayers[1].toString(), this.mjOfDais[1].toString(),
                                                  this.mjOfPlayers[2].toString(), this.mjOfDais[2].toString(),
                                                  this.mjOfPlayers[3].toString(), this.mjOfDais[3].toString()]) {
                mahjongArr[mahjongArr.length] = PushdownWinGame.sortMahjongs(eachMahjongs);
            }
            return mahjongArr.join(";");
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
        public function get mahjongsOfDaisHistory():Array {
            return this.mjOfDaisHistory as Array;
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
		 * 从备选牌中随机出牌
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
		 * 按照玩家指定的牌序，将牌从玩家待发牌区域移到玩家亮牌区域
		 * 
		 * @param index 玩家索引值
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
            // 保留本次移动麻将个数的历史信息，以便拆分使用
            (mjOfDaisHistory[index] as Array).push(mahjongValues.split(",").length);
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
