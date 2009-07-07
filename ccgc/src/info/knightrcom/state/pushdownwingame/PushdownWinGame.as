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

//        /** VV仅作为占位符使用，因5不能作为顺子的组成部分，VV不会与任何内容匹配，所以3、4也就不可能成为顺子的一部分 */
//        private static const prioritySequence:String = "V3,V4,VV,V6,V7,V8,V9,V10,VJ,VQ,VK,VA,V2,V5,VX,VY";
//        private static const RED5:String = "1V5";
//        private static const RED5_PAIR:String = "1V5,1V5";

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
        	return -1;
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
                return isStartRuleFollowed(currentBout);
            }
            // 接牌判断
            return isBoutRuleFollowed(currentBout, previousBout);
        }

        /**
         *
         * 首次发牌时进行校验
         *
         * @param currentBout
         * @return
         *
         */
        private static function isStartRuleFollowed(currentBout:String):Boolean {
            return isSingleStyle(currentBout) || isSeveralFoldStyle(currentBout) || isStraightStyle(currentBout);
        }

        /**
         *
         * 将前次牌序内容与本次将要打出的牌序内容进行校验
         *
         * @param currentBout
         * @param previousBout
         * @return
         *
         */
        private static function isBoutRuleFollowed(currentBout:String, previousBout:String):Boolean {
        	return false;
        }

        /**
         *
         * 单调
         *
         * @param boutCards
         * @return
         *
         */
        private static function isSingleStyle(boutCards:String):Boolean {
            var ptn:RegExp = /^[0-4]V([^,]+)$/;
            return ptn.test(boutCards);
        }

        /**
         *
         * 成倍且不成顺子
         *
         * @param boutCards
         * @return
         *
         */
        private static function isSeveralFoldStyle(boutCards:String):Boolean {
			return false;
        }

        /**
         *
         * 顺子
         *
         * @param boutCards
         * @return
         *
         */
        private static function isStraightStyle(boutCards:String):Boolean {
            var ptn:RegExp = /^.*V[25XY].*$/;
            if (ptn.test(boutCards)) {
                // 2、5、王不能作为顺子的内容
                return false;
            }
            // 去花色
            var resultCards:String = (boutCards + ",").replace(/\b\dV/g, "V");
            // 去重复项目
            resultCards = (resultCards).replace(/(V[^,]+,)\1*/g, "$1");
            // 倍数验证，防止个别牌的倍数与其他牌的倍数不一致
            if ((boutCards + ",").replace(/\b\dV/g, "V").length % resultCards.length == 0) {
                // 倍数全相同时，判断是否满足最小序列的条件，比如JQKA单倍时，至少要四张
                // 比如JQK双倍时，至少要三张；比如JQ三倍时，至少要两张
                var multiple:int = (boutCards + ",").replace(/\b\dV/g, "V").length / resultCards.length;
                if (multiple == 1) {
                    // 单牌顺子
                    if (resultCards.replace(/,$/, "").split(",").length < 4) {
                        return false;
                    }
                } else if (multiple > 1) {
                    // 多倍数的顺子
                    if (resultCards.replace(/,$/, "").split(",").length < 3) {
                        return false;
                    }
                } else {
                    throw Error("顺子处理出错！");
                }
                // 间隔值判断，相邻的牌必须连续
                // return prioritySequence.indexOf(resultCards) > -1;
                return false;
            } else {
                // 不能整除代表牌中有的倍数有问题
                return false;
            }
        }

        /**
         *
         * @param boutCards
         * @return
         *
         */
        private static function getMultiple(boutCards:String):int {
            // 去花色
            var resultCards:String = (boutCards + ",").replace(/\b\dV/g, "V");
            // 去重复项目
            resultCards = (resultCards).replace(/(V[^,]+,)\1*/g, "$1");
            return (boutCards + ",").replace(/\b\dV/g, "V").length / resultCards.length;
        }

    }
}