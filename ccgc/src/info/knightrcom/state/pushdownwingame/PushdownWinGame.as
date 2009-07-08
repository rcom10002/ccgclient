package info.knightrcom.state.pushdownwingame {

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

		/** 操作动作，参考地址 http://en.wikipedia.org/wiki/Mahjong */
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
         * @param mahjongs
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
         * 严重发牌规则，分为两种验证：首发、接牌
         *
         * @param previousBout
         * @param currentBout
         * @return
         *
         */
        public static function isRuleFollowed(currentBout:String, previousBout:String = null):Boolean {
            if (previousBout == null) {
                // 首次发牌判断
                return false;
            }
            // 接牌判断
            return false;
        }

		public static function add():void {
			
		}
    }
}