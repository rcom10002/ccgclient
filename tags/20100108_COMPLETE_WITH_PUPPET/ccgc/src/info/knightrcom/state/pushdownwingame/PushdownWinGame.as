package info.knightrcom.state.pushdownwingame {

    import component.MahjongButton;

    /**
     *
     * 方法中所有的参数形式均为 (([1-9][WBT]|EAST|SOUTH|WEST|NORTH|RED|GREEN|WHITE),)*
     * 并且是已经排好顺序
     *
     */
    public class PushdownWinGame {

        public function PushdownWinGame() {
        }

        /** 优先顺序：东南西北中发白万饼条 */
		private static const prioritySequence:String="EAST,SOUTH,WEST,NORTH,RED,GREEN,WHITE,W1,W2,W3,W4,W5,W6,W7,W8,W9,B1,B2,B3,B4,B5,B6,B7,B8,B9,T1,T2,T3,T4,T5,T6,T7,T8,T9";

		/** 玩家处于牌桌的方向 */
		public static const DIRECTION_DOWN:int = 100;
		public static const DIRECTION_RIGHT:int = 200;
		public static const DIRECTION_UP:int = 300;
		public static const DIRECTION_LEFT:int = 400;

		/** 操作动作名称，参考地址 http://en.wikipedia.org/wiki/Mahjong */
		/** 胡 */
		public static const OPTR_WIN:int = 0;
		/** 杠 */
		public static const OPTR_KONG:int = 1;
		/** 碰 */
		public static const OPTR_PONG:int = 2;
		/** 吃 */
		public static const OPTR_CHOW:int = 3;
		/** 弃 */
		public static const OPTR_GIVEUP:int = 4;
		/** 摸 */
		public static const OPTR_RAND:int = 5;

		/** 以当前玩家索引为基准点算起，可以进行操作的玩家优先顺序 */
		public static const OPTR_PLAYER_INDEX_PRIORITY:Array = new Array(
			new Array(1, 2, 3), // 一号玩家发牌时
			new Array(2, 3, 0), // 二号玩家发牌时
			new Array(3, 0, 1), // 三号玩家发牌时
			new Array(0, 1, 2)  // 四号玩家发牌时
		);

        /**
         * 对服务器端洗牌后分配的尚未排序过的麻将进行排序
         *
         * @param mahjongs 格式为逗号分隔的麻将值
         * @return
         *
         */
        public static function sortMahjongs(mahjongs:String):Array {
            return mahjongs.split(",").sort(function (mahjong1:String, mahjong2:String):int {
                if (mahjong1 == mahjong2) {
                    // 相同时
                    return 0;
                }
                // 实现排序功能
                var pri1:int = prioritySequence.indexOf(mahjong1.replace(/^[0-4]/, ""));
                var pri2:int = prioritySequence.indexOf(mahjong2.replace(/^[0-4]/, ""));
                // 值比较
                if (pri1 > pri2) {
                    return 1;
                } else if (pri1 < pri2) {
                    return -1;
                }
                return 0;
            });
        }

        /**
         * 对服务器端洗牌后分配的尚未排序过的麻将进行排序
         *
         * @param mahjongArray
         * @return
         *
         */
        public static function sortMahjongButtons(mahjongButtonArray:Array):Array {
            return mahjongButtonArray.sort(function (mahjong1:MahjongButton, mahjong2:MahjongButton):int {
                if (mahjong1.value == mahjong2.value) {
                    // 相同时
                    return 0;
                }
                // 实现排序功能
                var pri1:int = prioritySequence.indexOf(mahjong1.value);
                var pri2:int = prioritySequence.indexOf(mahjong2.value);
                // 值比较
                if (pri1 > pri2) {
                    return 1;
                } else if (pri1 < pri2) {
                    return -1;
                }
                return 0;
            });
        }

		/**
		 *
		 * 胡牌判断<br>
		 *
		 *　　1．和牌的基本牌型<br>
		 *　　（1）11、123、123、123、123<br>
		 *　　（2）11、123、123、123、111（1111，下同）<br>
		 *　　（3）11、123、123、111、111<br>
		 *　　（4）11、123、111、111、111．<br>
		 *　　（5）11、111、111、111、111．<br>
		 *　　2．和牌的特殊牌型 - 该规则暂不适用<br>
		 *　　（1）11、11、11、11、11、11、11（七对：由7个对子组成和牌）<br>
		 *　　（2）1、1、1、1、1、1、1、1、1、1、1、1、11（十三幺：由3种序数牌的一、九牌，7种字牌及其中一对作将组成的和牌）<br>
		 *　　（3）1、1、1、1、1、1、1、1、1、1、1、1、1、1、（全不靠：由单张3种花色147、258、369不能错位的序数牌及东南西北中发白中的任何14张牌组成的没有将牌的和牌）<br>
		 *
		 *   （注：1=单张，11=将、对子，111=刻子，1111=杠，123=顺子；有多种胡法时，只取得分最高的一种。）<br>
		 *
		 * @param dealedMahjong
		 * @param mahjongOfPlayers
		 * @param excludedIndex
		 * @return 胡牌玩家索引
		 *
		 */
		public static function isWin(dealedMahjong:String, mahjongOfPlayers:Array, excludedIndex:String):int
		{
			// TODO 特殊牌型处理
			var winResultsLengthes:Array = null;
			var index:int = -1;
			var mahjongs:Array = null;
			// FIXME 暂时关闭以下三项胡牌规则
//			// 七对
//            for (index = 0; index < mahjongOfPlayers.length; index++) {
//            	if (index == excludedIndex) {
//            		continue;
//            	}
//				mahjongs = (mahjongOfPlayers[index] as Array).slice(0);
//				mahjongs.push(dealedMahjong);
//				if (/^((,\\w+)\\2){7}$/.test("," + PushdownWinGame.sortMahjongs(mahjongs.join(",")).join(","))) {
//            	}
//				winCube.walkAllRoutes();
//				winResults[index] = winCube.winningRoutes;
//				winResultsLength[index] = winCube.winningRoutes.length;
//            }
//			// 十三幺
//			
//			// 全不靠
//			
			// 常规牌型处理
			winResultsLengthes = new Array();
            for (index = 0; index < mahjongOfPlayers.length; index++) {
            	if (excludedIndex.indexOf(index.toString()) > -1) {
            		continue;
            	}
            	var currentMahjongs:String = (mahjongOfPlayers[index] as Array).join(",") + "," + dealedMahjong;
				var winCube:PushdownWinningCube = new PushdownWinningCube(sortMahjongs(currentMahjongs).join(","));
				winCube.walkAllRoutes();
				winResultsLengthes[index] = winCube.winningRoutes.length;
            }
            // 确定可以胡牌的玩家
            index = lookupWinner(winResultsLengthes, excludedIndex);
			return index > -1 ? index : -1; // 正确结果需加0
		}

		/**
		 * 
		 * 从胡牌结果中找出胡牌优先权最大的玩家，并返回其索引值
		 * 
		 * @param exeResultsLengthes
		 * @param excludedIndex
		 * @return 
		 * 
		 */
		private static function lookupWinner(exeResultsLengthes:Array, excludedIndex:String):int {
			// 取得发牌玩家索引
			var currentIndex:int = int(excludedIndex.charAt(0));
			// 返回操作结果不为空并且最接近指定玩家的那个玩家的索引
			for each (var playerIndex:int in (OPTR_PLAYER_INDEX_PRIORITY[currentIndex] as Array)) {
				if (excludedIndex.indexOf(playerIndex.toString()) > -1) {
					continue;
				}
				if (exeResultsLengthes[playerIndex] > 0) {
					return playerIndex;
				}
			}
			return -1;
		}

        /**
         * 
         * 当前玩家根据其他玩家出牌内容，进行杠牌判断
         * 
         * @param dealedMahjong
         * @param mahjongOfPlayers
         * @param excludedIndex
         * @return 杠牌玩家索引
         * 
         */
        public static function isKong(dealedMahjong:String, mahjongOfPlayers:Array, excludedIndex:String):int {
            for (var index:int = 0; index < mahjongOfPlayers.length; index++) {
            	if (excludedIndex.indexOf(index.toString()) > -1) {
            		continue;
            	}
            	var currentMahjongs:String = (mahjongOfPlayers[index] as Array).join(",");
            	if (sortMahjongs(currentMahjongs).join(",").indexOf(dealedMahjong + "," + dealedMahjong + "," + dealedMahjong) > -1) {
            		return index + OPTR_KONG * 10;
            	}
            }
            return -1; // 正确结果需加10
        }

        /**
         * 
         * 当前玩家根据其他玩家出牌内容，进行碰牌判断
         * 
         * @param dealedMahjong
         * @param mahjongOfPlayers
         * @param excludedIndex
         * @return 碰牌玩家索引
         * 
         */
        public static function isPong(dealedMahjong:String, mahjongOfPlayers:Array, excludedIndex:String):int {
            for (var index:int = 0; index < mahjongOfPlayers.length; index++) {
            	if (excludedIndex.indexOf(index.toString()) > -1) {
            		continue;
            	}
            	var currentMahjongs:String = (mahjongOfPlayers[index] as Array).join(",");
            	if (sortMahjongs(currentMahjongs).join(",").indexOf(dealedMahjong + "," + dealedMahjong) > -1) {
            		return index + OPTR_KONG * 20;
            	}
            }
            return -1; // 正确结果需加20
        }

        /**
         * 
         * 当前玩家根据其他玩家出牌内容，进行吃牌判断
         * 
         * @param dealedMahjong 当前打出的牌
         * @param currentMahjongs 当前玩家手中的牌
         * @return 
         * 
         */
        public static function isChow(dealedMahjong:String, currentMahjongs:Array):Boolean {
        	if (!new RegExp("^.\\d$").test(dealedMahjong)) {// TODO 左中右均可吃牌
        		// 牌值在2至8之间才能进行吃牌操作 
        		return false;
        	}
        	var color:String = dealedMahjong.charAt(0);
        	var value:int = int(dealedMahjong.charAt(1));
        	var headHeadDealedMahjong:String = color + (value - 2);
        	var headDealedMahjong:String = color + (value - 1);
        	var tailDealedMahjong:String = color + (value + 1);
        	var tailTailDealedMahjong:String = color + (value + 2);
        	var result:Boolean = false;
        	result ||= (currentMahjongs.indexOf(headDealedMahjong) > -1 && currentMahjongs.indexOf(tailDealedMahjong) > -1); // 中间吃
        	result ||= (currentMahjongs.indexOf(headHeadDealedMahjong) > -1 && currentMahjongs.indexOf(headDealedMahjong) > -1); // 右侧吃
        	result ||= (currentMahjongs.indexOf(tailDealedMahjong) > -1 && currentMahjongs.indexOf(tailTailDealedMahjong) > -1); // 左侧吃
            return result;
        }

		/**
		 * 
		 * 在摸牌过程中，判断是否可以自摸胡牌
		 * 
		 * @param currentMahjongs
		 * @return 
		 * 
		 */
		public static function canWinNow(currentMahjongs:Array):Boolean {
			// 计算所有可能胡牌的路径
			var mahjongs:Array = currentMahjongs.slice(0);
			var cube:PushdownWinningCube = new PushdownWinningCube(sortMahjongs(mahjongs.join(",")).join(","));
			cube.walkAllRoutes();
			// 提取正确的胡牌路径
			return cube.winningRoutes.length > 0;
		}

		/**
		 * 
		 * 在摸牌过程中，判断是否可以杠
		 * 
		 * @param randMahjong 当前玩家摸到的牌
		 * @param currentMahjongs 当前玩家手中的牌
		 * @param daisMahjongs 当前玩家亮出的牌，包括杠、碰、吃牌型
		 * @return 
		 * 
		 */
		public static function canKongNow(randMahjong:String, currentMahjongs:Array, daisMahjongs:String):Boolean {
		    var canKong:Boolean = false;
		    // 明杠
			var oldLength:int = currentMahjongs.join(",").length;
			var newLength:int = currentMahjongs.join(",").replace(new RegExp(randMahjong, "g"), "").length;
			canKong ||= ((oldLength - newLength) == randMahjong.length * 4);
			// 暗杠
			canKong ||= (daisMahjongs.indexOf("#,#,#".replace(/#/g, randMahjong)) > -1);
			return canKong;
		}
    }
}
