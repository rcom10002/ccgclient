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
		public static const DIRECTION_DOWN:uint = 100;
		public static const DIRECTION_RIGHT:uint = 200;
		public static const DIRECTION_UP:uint = 300;
		public static const DIRECTION_LEFT:uint = 400;

		/** 操作动作名称，参考地址 http://en.wikipedia.org/wiki/Mahjong */
		/** 胡牌 */
		public static const OPTR_WIN:uint = 0;
		/** 杠 */
		public static const OPTR_KONG:uint = 1;
		/** 碰 */
		public static const OPTR_PONG:uint = 2;
		/** 吃 */
		public static const OPTR_CHOW:uint = 3;
		/** 放弃 */
		public static const OPTR_GIVEUP:uint = 4;
		/** 摸牌 */
		public static const OPTR_RAND:uint = 5;

        /**
         * 对服务器端洗牌后分配的尚未排序过的麻将进行排序
         *
         * @param mahjongs 格式为逗号分隔的麻将值
         * @return
         *
         */
        public static function sortMahjongs(mahjongs:String):Array {
            var mahjongArray:Array = mahjongs.split(",");
            mahjongArray.sort(mahjongSorter);
            return mahjongArray;
        }

        /**
         *
         * @param mahjong1
         * @param mahjong2
         * @return
         *
         */
        private static function mahjongSorter(mahjong1:String, mahjong2:String):int {
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
        }

        /**
         * 
         * 胡牌判断
         * 
         * @param dealedMahjong
         * @param mahjongOfPlayers
         * @param excludedIndex
         * @return 胡牌玩家索引
         * 
         */
        public static function isWin(dealedMahjong:String, mahjongOfPlayers:Array, excludedIndex:int):int {
            return -1; // 正确结果需加0
        }

        /**
         * 
         * 杠牌判断
         * 
         * @param dealedMahjong
         * @param mahjongOfPlayers
         * @param excludedIndex
         * @return 杠牌玩家索引
         * 
         */
        public static function isKong(dealedMahjong:String, mahjongOfPlayers:Array, excludedIndex:int):int {
//            for (var index:int = 0; index < mahjongOfPlayers.length; index++) {
//            	if (index == excludedIndex) {
//            		continue;
//            	}
//            	var currentMahjongs:String = (mahjongOfPlayers[index] as Array).join(",");
//            	var oldLen:int = currentMahjongs.length;
//            	var newLen:int = currentMahjongs.replace(new RegExp(dealedMahjong), "").length;
//            	if ((oldLen - newLen) / dealedMahjong.length == 3) {
//            		return index;
//            	}
//            }
            return -1; // 正确结果需加10
        }

        /**
         * 
         * 碰牌判断
         * 
         * @param dealedMahjong
         * @param mahjongOfPlayers
         * @param excludedIndex
         * @return 碰牌玩家索引
         * 
         */
        public static function isPong(dealedMahjong:String, mahjongOfPlayers:Array, excludedIndex:int):int {
//            for (var index:int = 0; index < mahjongOfPlayers.length; index++) {
//            	if (index == excludedIndex) {
//            		continue;
//            	}
//            	var currentMahjongs:String = (mahjongOfPlayers[index] as Array).join(",");
//            	var oldLen:int = currentMahjongs.length;
//            	var newLen:int = currentMahjongs.replace(new RegExp(dealedMahjong), "").length;
//            	if ((oldLen - newLen) / dealedMahjong.length == 2) {
//            		return index;
//            	}
//            }
            return -1; // 正确结果需加20
        }

        /**
         * 
         * 吃牌判断
         * 
         * @param dealedMahjong 当前打出的牌
         * @param currentMahjongs 当前玩家手中的牌
         * @return 
         * 
         */
        public static function isChow(dealedMahjong:String, currentMahjongs:Array):Boolean {
//        	var strValue:String = dealedMahjong.replace(/[WBT]/, "");
//        	var strColor:String = dealedMahjong.replace(/\d/, "");
//        	if (!new RegExp("^[2-8]$").test(strValue)) {
//        		// 牌值在2至9之间才能进行吃牌操作
//        		return -1;
//        	}
//        	var intValue:int = int(strValue);
//        	var headdealedMahjong:String = strColor + (intValue - 1);
//        	var taildealedMahjong:String = strColor + (intValue + 1);
//        	if (currentMahjongs.indexOf(headdealedMahjong) > 0 && currentMahjongs.indexOf(taildealedMahjong)) {
//        		return currentMahjongs.indexOf(dealedMahjong);
//        	}
            return false; // 正确结果需加30
        }

//		/**
//		 * 返回int类型数组中最大值
//		 * 
//		 * @param array
//		 * @return 
//		 * 
//		 */
//		public static function maxValue(array:Array):int
//		{
//			var mxm:int = array[0];
//			for (var i:int = 0; i < array.length; i++)
//			{
//				if (array[i] > mxm)
//				{
//					mxm = array[i];
//				}
//			}
//			return mxm;
//		}

    }
}