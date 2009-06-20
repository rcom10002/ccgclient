package info.knightrcom.state.red5game {

    /**
     *
     * 方法中所有的参数形式均为 \dV([2-9JQKAXY]|10)(,\dV([2-9JQKAXY]|10))*
     * 并且是已经排好顺序
     *
     */
    public class Red5Game {

        public function Red5Game() {
        }

        /** VV仅作为占位符使用，因5不能作为顺子的组成部分，VV不会与任何内容匹配，所以3、4也就不可能成为顺子的一部分 */
        private static const prioritySequence:String = "V3,V4,VV,V6,V7,V8,V9,V10,VJ,VQ,VK,VA,V2,V5,VX,VY";
        private static const RED5:String = "1V5";
        private static const RED5_PAIR:String = "1V5,1V5";

        /**
         * 对服务器端洗牌后分配的尚未排序过的扑克进行排序
         *
         * @param cards
         * @return
         *
         */
        public static function sortPokers(cards:String):Array {
            var cardArray:Array = cards.split(",");
            cardArray.sort(cardSorter);
            return cardArray;
        }

        /**
         *
         * @param card1
         * @param card2
         * @return
         *
         */
        private static function cardSorter(card1:String, card2:String):int {
            if (card1 == card2) {
                // 值与花色都相同时
                return 0;
            } else if ("1V5" == card1) {
                // 第一张牌为红五时
                return 1;
            } else if ("1V5" == card2) {
                // 第二张牌为红五时
                return -1;
            }
            // 实现排序功能
            var pri1:int = prioritySequence.indexOf(card1.replace(/^[0-4]/, ""));
            var pri2:int = prioritySequence.indexOf(card2.replace(/^[0-4]/, ""));
            // 值比较
            if (pri1 > pri2) {
                return 1;
            } else if (pri1 < pri2) {
                return -1;
            }
            // 值相同时，进行花色比较
            if (card1.charAt(0) > card2.charAt(0)) {
                return 1;
            } else if (card1.charAt(0) < card2.charAt(0)) {
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
            // 牌数一致
            if (previousBout.split(",").length != currentBout.split(",").length) {
                return false;
            }
            if ((isSingleStyle(previousBout) && isSingleStyle(currentBout))) {
                // 符合样式规则后，验证大小规则
                if (RED5 == previousBout) {
                    // 前张牌为红五时，不能出牌
                    return false;
                } else if (RED5 == currentBout) {
                    // 前张牌为非红五时，本张牌为红五时，可出牌
                    return true;
                }
                currentBout = currentBout.replace(/^[0-4]/, "");
                previousBout = previousBout.replace(/^[0-4]/, "");
                return prioritySequence.indexOf(currentBout) > prioritySequence.indexOf(previousBout);
            } else if (isSeveralFoldStyle(previousBout) && isSeveralFoldStyle(currentBout)) {
                if (RED5_PAIR == previousBout) {
                    // 前张牌为双红五时，不能出牌
                    return false;
                } else if (RED5_PAIR == currentBout) {
                    // 前张牌非双红五，本张牌为双红五时，可出牌
                    return true;
                } else if (currentBout.indexOf(RED5) > -1) {
                    // 以上两种情况之外发现红五与其他牌同时使用时，不能通过验证
                    return false;
                }
                // 符合样式规则后，验证大小规则
                currentBout = currentBout.replace(/^[0-4](V[^,]+).*$/, "$1");
                previousBout = previousBout.replace(/^[0-4](V[^,]+).*$/, "$1");
                return prioritySequence.indexOf(currentBout) > prioritySequence.indexOf(previousBout);
            } else if (isStraightStyle(previousBout) && isStraightStyle(currentBout)) {
                if (currentBout.indexOf(RED5) > -1) {
                    // 发现红五与其他牌同时使用时，不能通过验证
                    return false;
                }
                // 判断倍数是否相同
                if (getMultiple(currentBout) != getMultiple(previousBout)) {
                    return false;
                }
                // 符合倍数规则后，验证顺子的大小规则，只判断首牌即可
                currentBout = currentBout.replace(/^[0-4]([^,]+).*$/, "$1");
                previousBout = previousBout.replace(/^[0-4]([^,]+).*$/, "$1");
                return prioritySequence.indexOf(currentBout) > prioritySequence.indexOf(previousBout);
                ;
            } else {
                // 其它所有的错误样式
                return false;
            }
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
            if (RED5_PAIR == boutCards) {
                // 双红五时
                return true;
            } else if (boutCards.indexOf(RED5) > -1) {
                // 红五只能与红五使用，不允许与其他牌同时使用
                return false;
            }
            var ptn:RegExp = /^[0-4]V([^,]+)(,[0-4]V\1)+$/;
            return ptn.test(boutCards);
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
                return prioritySequence.indexOf(resultCards) > -1;
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