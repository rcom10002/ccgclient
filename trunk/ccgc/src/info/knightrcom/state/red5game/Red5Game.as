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
        public static const prioritySequence:String = "V3,V4,VV,V6,V7,V8,V9,V10,VJ,VQ,VK,VA,V2,V5,VX,VY";
        private static const RED5:String = "1V5";
        private static const RED5_PAIR:String = "1V5,1V5";
        
        /** 操作动作名称  */
        /** 重选 */
        public static const OPTR_RESELECT:int = 0;
        /** 不要 */
        public static const OPTR_GIVEUP:int = 1;
        /** 提示 */
        public static const OPTR_HINT:int = 2;
        /** 出牌 */
        public static const OPTR_DISCARD:int = 3;
        
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
		 * 扑克牌排序算法
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
         * 验证发牌规则，分为两种验证：首发、接牌
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
        public static function isSingleStyle(boutCards:String):Boolean {
            var ptn:RegExp = /^[0-4]V([^,]+)$/;
            return ptn.test(boutCards);
        }
        
        /**
         *
         * 同张，至少要有两张值一样的牌，成倍且不成顺子
         *
         * @param boutCards
         * @return
         *
         */
        public static function isSeveralFoldStyle(boutCards:String):Boolean {
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
        public static function isStraightStyle(boutCards:String):Boolean {
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
         * 取得倍数，适用于单调、倍数牌、顺子
         * 
         * @param boutCards 当前打出的牌 
         * @return
         *
         */
        public static function getMultiple(boutCards:String):int {
            // 去花色
            var resultCards:String = (boutCards + ",").replace(/\b\dV/g, "V");
            // 去重复项目
            resultCards = (resultCards).replace(/(V[^,]+,)\1*/g, "$1");
            return (boutCards + ",").replace(/\b\dV/g, "V").length / resultCards.length;
        }
        
        /**
         *
         * 取得顺子长度
         * 
         * @param boutCards 当前打出的牌 
         * @return
         *
         */
        public static function getStraightLength(boutCards:String):int {
            return boutCards.split(",").length / getMultiple(boutCards);
        }
        
        /**
         * 对子、三同张、四同张 …… N同张
         * 
         * @param multiple >= 2
         * @param myCards
         * @param boutCards
         * 
         * @return an array of an array
         * 
         */
        public static function grabMultiple(multiple:int, myCards:Array, boutCards:Array = null):Array {
            var resultArrayArray:Array = new Array();
            // 按照给定的序列倍数扩大确定下来的样式
            var extStyle:String = "";
            while (multiple-- > 0) {
                extStyle += "$1";
            }
            multiple = extStyle.length / 2;
            // 去花色，并在结尾添加一个逗号
            var myCardsString:String = (myCards.join(",") + ",").replace(/\dV/g, "V");
            // 去除特殊数据"5 X Y"
            myCardsString = myCardsString.replace(/V[5XY],/g, "");
            // 将超过指定倍数的每个样式的牌的个数都缩小至指定的倍数
            myCardsString = myCardsString.replace(new RegExp("(V[^,]*,)\\1{" + (multiple - 1) + ",}", "g"), extStyle);
            var matchedCardsArray:Array = myCardsString.match(new RegExp("(V[^,]*,)\\1{" + (multiple - 1) + "}", "g"));
            for each (var eachCardsString:String in matchedCardsArray) {
                eachCardsString = eachCardsString.replace(/,$/, "");
                var eachCardsArray:Array = eachCardsString.split(",");
                resultArrayArray.push(eachCardsArray);
            }
            // 处理草五
            myCardsString = (myCards.join(",") + ",").replace(/\dV[^5,]*,/g, ""); // 去除五以外的牌
            myCardsString = myCardsString.replace(/1V5,/g, ""); // 去除红五
            if (myCardsString.replace(/,$/, "").split(",").length >= multiple) {
                var my5seqWithoutHeart5:Array = new Array(multiple);
                for (var i:int = 0; i < multiple; i++) {
                    my5seqWithoutHeart5[i] = "V5";
                }
                resultArrayArray.push(my5seqWithoutHeart5);
            }
            // 处理大小王与红五
            if (multiple == 2) {
                if (myCards.join(",").indexOf("0VX,0VX") > -1) {
                    // 小王
                    resultArrayArray.push(new Array("0VX", "0VX"));
                }
                if (myCards.join(",").indexOf("0VY,0VY") > -1) {
                    // 大王
                    resultArrayArray.push(new Array("0VY", "0VY"));
                }
                if (myCards.join(",").indexOf("1V5,1V5") > -1) {
                    // 红五
                    resultArrayArray.push(new Array("1V5", "1V5"));
                }
            }
            return resultArrayArray;
        }
        
        /**
         * 四连顺、五连顺
         * 对子三连顺、对子四连顺、对子五连顺
         * 三同张三连顺、三同张四连顺、三同张五连顺
         * 四同张三连顺
         * 
         * @param multiple >= 1
         * @param numSeq >= 3
         * @param myCards
         * @param boutCards
         * 
         * @return an array of an array
         * 
         */
        public static function grabSequence(multiple:int, numSeq:int, myCards:Array, boutCards:Array = null):Array {
            var resultArrayArray:Array = new Array();
            var i:int = 0;
            // 1.去花色，并在结尾添加一个逗号
            var myCardsString:String = (myCards.join(",") + ",").replace(/\dV/g, "V");
            // 2.去除无效数据"2 5 X Y"
            myCardsString = myCardsString.replace(/V[25XY],/g, "");
            // 3.去除重复项
            myCardsString = myCardsString.replace(/(V[^,]*,)\1{1,}/g, "$1");
            if (myCardsString.replace(/,$/, "").split(",").length < numSeq) {
                // 牌值样式的个数比要求的序列个数少
                return resultArrayArray;
            }
            // 确定组合样式
            var testStyleArray:Array = new Array();
            switch (numSeq) {
                case 5:
                    // 五张连
                    testStyleArray.push("V10,VJ,VQ,VK,VA,");
                    break;
                case 4:
                    testStyleArray.push("V10,VJ,VQ,VK,", "VJ,VQ,VK,VA,");
                    // 四张连
                    break;
                case 3:
                    testStyleArray.push("V10,VJ,VQ,", "VJ,VQ,VK,", "VQ,VK,VA,");
                    // 三张连
                    break;
            }
            // 按照给定的序列倍数扩大确定下来的样式
            var extStyle:String = "";
            while (multiple-- > 0) {
                extStyle += "$1";
            }
            multiple = extStyle.length / 2;
            for (i = 0; i < testStyleArray.length; i++) {
                var testStyle:String = testStyleArray[i].toString().replace(/(V[^,]*,)/g, extStyle);
                testStyleArray[i] = testStyle;
            }
            // 将已经构造出来的，可能出现的样式，应用到玩家手中的牌中
            // 去花色去无效数据"2 5 X Y"
            myCardsString = (myCards.join(",") + ",").replace(/\dV/g, "V").replace(/V[25XY],/g, "");
            // 将超过指定倍数的每个样式的牌的个数都缩小至指定的倍数
            myCardsString = myCardsString.replace(new RegExp("(V[^,]*,)\\1{" + (multiple - 1) + ",}", "g"), extStyle);
            for (i = 0; i < testStyleArray.length; i++) {
                if (myCardsString.indexOf(testStyleArray[i]) > -1) {
                } else {
                    // 去除不满足条件
                    testStyleArray[i] = null;
                }
            }
            // 整理数据，将null内容过滤掉
            for each (var eachStyle:String in testStyleArray) {
                if (eachStyle) {
                    resultArrayArray.push(eachStyle.replace(/,$/, "").split(","));
                }
            }
            return resultArrayArray;
        }
        
        /** 对子 */
        public static const TIPA_MUTIPLE2:int = 101;
        /** 三同张 */
        public static const TIPA_MUTIPLE3:int = 102;
        /** 四同张 */
        public static const TIPA_MUTIPLE4:int = 103;
        /** 五同张 */
        public static const TIPA_MUTIPLE5:int = 104;
        /** 六同张 */
        public static const TIPA_MUTIPLE6:int = 105;
        /** 七同张 */
        public static const TIPA_MUTIPLE7:int = 106;
        /** 八同张 */
        public static const TIPA_MUTIPLE8:int = 107;
        
        /** 四连顺 */
        public static const TIPB_SEQ4:int = 201;
        /** 五连顺 */
        public static const TIPB_SEQ5:int = 202;
        /** 对子三连顺 */
        public static const TIPB_DOUBLE_SEQ3:int = 203;
        /** 对子四连顺 */
        public static const TIPB_DOUBLE_SEQ4:int = 204;
        /** 对子五连顺 */
        public static const TIPB_DOUBLE_SEQ5:int = 205;
        
        /** 三同张三连顺 */
        public static const TIPC_TRIPLE_SEQ3:int = 301;
        /** 三同张四连顺 */
        public static const TIPC_TRIPLE_SEQ4:int = 302;
        /** 三同张五连顺 */
        public static const TIPC_TRIPLE_SEQ5:int = 303;
        /** 四同张三连顺 */
        public static const TIPC_FOURFOLD_SEQ3:int = 304;
        
        /**
         * 所有提示种类
         */
        private static const allTipIds:Array = new Array(TIPA_MUTIPLE2, TIPA_MUTIPLE3, TIPA_MUTIPLE4, 
            TIPA_MUTIPLE5, TIPA_MUTIPLE6, TIPA_MUTIPLE7, TIPA_MUTIPLE8, TIPB_SEQ4, TIPB_SEQ5, 
            TIPB_DOUBLE_SEQ3, TIPB_DOUBLE_SEQ4, TIPB_DOUBLE_SEQ5, TIPC_TRIPLE_SEQ3, TIPC_TRIPLE_SEQ4, 
            TIPC_TRIPLE_SEQ5, TIPC_FOURFOLD_SEQ3);

        /**
         * 提示暂存容器
         */
        private static var tipsHolder:Object = new Object();
        
        /**
         * 
         * 将所有的可能的牌型放入提示暂存容器中
         * 
         * @param myCards
         * 
         */
        public static function refreshTips(myCards:String):void {
            var allTips:Object = grabTips(myCards);
            for each (var eachId:int in allTipIds) {
                tipsHolder[eachId] = allTips[eachId];
            }
            //			tipsHolder[TIPA_MUTIPLE2] = {STATUS : -1, TIPS : grabMultiple(2, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE3] = {STATUS : -1, TIPS : grabMultiple(3, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE4] = {STATUS : -1, TIPS : grabMultiple(4, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE5] = {STATUS : -1, TIPS : grabMultiple(5, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE6] = {STATUS : -1, TIPS : grabMultiple(6, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE7] = {STATUS : -1, TIPS : grabMultiple(7, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE8] = {STATUS : -1, TIPS : grabMultiple(8, myCards.split(","))};
            //
            //			tipsHolder[TIPB_SEQ4] = {STATUS : -1, TIPS : grabSequence(1, 4, myCards.split(","))};
            //			tipsHolder[TIPB_SEQ5] = {STATUS : -1, TIPS : grabSequence(1, 5, myCards.split(","))};
            //			tipsHolder[TIPB_DOUBLE_SEQ3] = {STATUS : -1, TIPS : grabSequence(2, 3, myCards.split(","))};
            //			tipsHolder[TIPB_DOUBLE_SEQ4] = {STATUS : -1, TIPS : grabSequence(2, 4, myCards.split(","))};
            //			tipsHolder[TIPB_DOUBLE_SEQ5] = {STATUS : -1, TIPS : grabSequence(2, 5, myCards.split(","))};
            //
            //			tipsHolder[TIPC_TRIPLE_SEQ3] = {STATUS : -1, TIPS : grabSequence(3, 3, myCards.split(","))};
            //			tipsHolder[TIPC_TRIPLE_SEQ4] = {STATUS : -1, TIPS : grabSequence(3, 4, myCards.split(","))};
            //			tipsHolder[TIPC_TRIPLE_SEQ5] = {STATUS : -1, TIPS : grabSequence(3, 5, myCards.split(","))};
            //			tipsHolder[TIPC_FOURFOLD_SEQ3] = {STATUS : -1, TIPS : grabSequence(4, 3, myCards.split(","))};
        }
        
        /**
         * 
         * 从当前玩家手中的牌中组合出所有可能的牌型
         * 
         * @param myCards
         * @return 
         * 
         */
        public static function grabTips(myCards:String):Object {
            var tempTipsHolder:Object = new Object();
            tempTipsHolder[TIPA_MUTIPLE2] = {STATUS : -1, TIPS : grabMultiple(2, myCards.split(","))};
            tempTipsHolder[TIPA_MUTIPLE3] = {STATUS : -1, TIPS : grabMultiple(3, myCards.split(","))};
            tempTipsHolder[TIPA_MUTIPLE4] = {STATUS : -1, TIPS : grabMultiple(4, myCards.split(","))};
            tempTipsHolder[TIPA_MUTIPLE5] = {STATUS : -1, TIPS : grabMultiple(5, myCards.split(","))};
            tempTipsHolder[TIPA_MUTIPLE6] = {STATUS : -1, TIPS : grabMultiple(6, myCards.split(","))};
            tempTipsHolder[TIPA_MUTIPLE7] = {STATUS : -1, TIPS : grabMultiple(7, myCards.split(","))};
            tempTipsHolder[TIPA_MUTIPLE8] = {STATUS : -1, TIPS : grabMultiple(8, myCards.split(","))};
            
            tempTipsHolder[TIPB_SEQ4] = {STATUS : -1, TIPS : grabSequence(1, 4, myCards.split(","))};
            tempTipsHolder[TIPB_SEQ5] = {STATUS : -1, TIPS : grabSequence(1, 5, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ3] = {STATUS : -1, TIPS : grabSequence(2, 3, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ4] = {STATUS : -1, TIPS : grabSequence(2, 4, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ5] = {STATUS : -1, TIPS : grabSequence(2, 5, myCards.split(","))};
            
            tempTipsHolder[TIPC_TRIPLE_SEQ3] = {STATUS : -1, TIPS : grabSequence(3, 3, myCards.split(","))};
            tempTipsHolder[TIPC_TRIPLE_SEQ4] = {STATUS : -1, TIPS : grabSequence(3, 4, myCards.split(","))};
            tempTipsHolder[TIPC_TRIPLE_SEQ5] = {STATUS : -1, TIPS : grabSequence(3, 5, myCards.split(","))};
            tempTipsHolder[TIPC_FOURFOLD_SEQ3] = {STATUS : -1, TIPS : grabSequence(4, 3, myCards.split(","))};
            return tempTipsHolder;
        }
        
        /**
         * 
         * 按用户的选择来进行循环选择备用牌
         * 
         * @param optrIndex
         * @return 
         * 
         */
        public static function nextTipCards(optrIndex:int):Array {
            var tipHolder:Object = tipsHolder[optrIndex];
            if (tipHolder.TIPS.length == 0) {
                return null;
            }
            tipHolder.STATUS = tipHolder.STATUS + 1;
            if (tipHolder.STATUS == tipHolder.TIPS.length) {
                tipHolder.STATUS = 0;
            }
            return (tipHolder.TIPS as Array)[tipHolder.STATUS].toString().split(",");
        }
        
        /**
         * 
         * 智能提示，不负责牌型校验，只是针对已经打出的合法的牌型，从备选牌中选出合适的对策牌
         * 
         * @param myCards 当前玩家手中的牌
         * @param boutCards 最后一次打出的牌
         * @param enableFoolish 是否采用笨蛋判断法，如果采用，只对明显的大牌作出放弃，否则会根据己方的牌来作出最合理的判断
		 * 
		 * @return
         */
        public static function getBrainPowerTip(myCards:Array, boutCards:Array, enableFoolish:Boolean = true):Array {
            var boutCardsString:String = null;
			if (boutCards) {
				boutCardsString = boutCards.join(",");
			}
            var myCardsString:String = myCards.join(",") + ",";
			if (!boutCardsString) {
				// 启用首次发票提示功能、发牌提示从单张、同张、顺子，每种牌型的
				var allTipIdsReversedEdition:Array = allTipIds.slice(0, allTipIds.length);
				for each (var eachId:String in allTipIdsReversedEdition) {
					for each (var eachTip:Array in tipsHolder[eachId].TIPS as Array) {
						if (new RegExp("^\\d" + eachTip[0] + "$").test(myCards[0])) {
							return myCards[0];
						}
					}
				}
				return myCardsString.split(/,/g)[0];
			}
            // 当前玩家手中牌数比要压制的牌数少时
            if (myCards && boutCards && (myCards.length < boutCards.length)) {
                return null;
            }
            // 三张草五
            if (new RegExp("^[234]V5(,[234]V5){2,}$").test(boutCardsString)) {
                return null;
            }
            // 封顶龙儿
            if (isStraightStyle(boutCardsString) && /\dVA/.test(boutCards[boutCards.length - 1])) {
                return null;
            }
            // 单双红五
            if (boutCardsString.indexOf("1V5") > -1) {
                return null;
            }
            // 七张二
            if (new RegExp("^(\\dV2,){7}$").test(boutCardsString + ",")) {
                return null;
            }
            if (enableFoolish) {
                return new Array();
            }
            if (isSingleStyle(boutCardsString)) {
                // 单张判断
                // 去花色
                boutCardsString = boutCardsString.replace(/^\dV/g, "V");
                // 去红五去花色
                myCardsString = myCardsString.replace(/1V5,/g, "").replace(/\dV/g, "V");
                // 是否有比打出牌大的牌在手中
                var myLastCard:String = myCardsString.replace(/^(.*,)?(\w+),$/, "$2");
                // 比较除了红五以外的牌
                if (prioritySequence.indexOf(myLastCard.replace(/\dV/, "V")) <= prioritySequence.indexOf(boutCardsString)) {
                    // 有红五则返回红五
                    if (myCards.join(",").indexOf("1V5") > -1) {
                        return new Array("1V5");
                    }
                    return null;
                }
                if (myCardsString.length - myCardsString.replace(/V/g, "").length == 1) {
                    // 剩下最后一张牌的情况下
                    return myCards;
                }
                // 单张优先，判断是否有比打出牌大的单张
                // 完全去除重复的项目，不保留任何内容
                var singleCard:String = null;
                var mySingleCardsString:String = myCardsString.replace(/(V[^,]*,)\1{1,}/g, ""); // 只保留单张牌
                mySingleCardsString = mySingleCardsString.replace(/,$/, "");
                for each (singleCard in mySingleCardsString.split(",")) {
                    if (prioritySequence.indexOf(singleCard) > prioritySequence.indexOf(boutCardsString)) {
                        return new Array(singleCard);
                    }
                }
                // 判断是否有比打出牌大的非单张
                var removeSingleCardPattern:RegExp = new RegExp(mySingleCardsString.replace(/,/g, "|"), "g");
                myCardsString = myCardsString.replace(removeSingleCardPattern, "").replace(",{2,}", ",");
                for each (singleCard in myCardsString.replace(/(V[^,]*,)\1{1,}/g, "$1").replace(/,{2,}/g, ",").replace(/,$/, "").split(",")) {
                    if (mySingleCardsString.indexOf(singleCard) > -1) {
                        continue;
                    }
                    if (prioritySequence.indexOf(singleCard) > prioritySequence.indexOf(boutCardsString)) {
                        return new Array(singleCard);
                    }
                }
            } else {
                var allTips:Object = grabTips(myCardsString.replace(/,$/, ""));
                var multiple:int = getMultiple(boutCardsString);
                var multipleId:int = -1;
                var targetTips:Array = null;
                var boutValue:String = null;
                var eachTargetTip:Array = null;
                var tempTargeTip:String = null;
                if (isSeveralFoldStyle(boutCardsString)) {
                    // 成倍且不成顺子
                    multipleId = 99 + multiple;
                    targetTips = allTips[multipleId].TIPS as Array;
                    boutValue = boutCardsString.replace(/^\d|,.*$/g, ""); // 去花色重复项
                    // 是否有比打出牌大的牌在手中
                    if (targetTips.length > 0) {
                        for each (eachTargetTip in targetTips) {
                            tempTargeTip = eachTargetTip.join(",").replace(/^\d|,.*$/g, ""); // 去花色重复项
                            if (prioritySequence.indexOf(tempTargeTip) > prioritySequence.indexOf(boutValue)) {
                                return eachTargetTip;
                            }
                        }
                    }
                    // 有红五则返回红五
                    if (multiple == 2 && myCardsString.indexOf("1V5,1V5") > -1) {
                        return "1V5,1V5".split(",");
                    }
                } else {
                    // 顺子，不含五连顺
                    var stlength:int = getStraightLength(boutCardsString);
                    multipleId = -1;
                    if (multiple == 1 && stlength == 4) {
                        // 四连顺 
                        multipleId = TIPB_SEQ4;
                    }
                    if (multiple == 2 && stlength == 3) {
                        // 对子三连顺
                        multipleId = TIPB_DOUBLE_SEQ3;
                    }
                    if (multiple == 2 && stlength == 4) {
                        // 对子四连顺
                        multipleId = TIPB_DOUBLE_SEQ4;
                    }
                    if (multiple == 3 && stlength == 3) {
                        // 三同张三连顺
                        multipleId = TIPC_TRIPLE_SEQ3;
                    }
                    if (multiple == 3 && stlength == 4) {
                        // 三同张四连顺
                        multipleId = TIPC_TRIPLE_SEQ4;
                    }
                    if (multiple == 4 && stlength == 3) {
                        // 四同张三连顺
                        multipleId = TIPC_FOURFOLD_SEQ3;
                    }
                    targetTips = allTips[multipleId].TIPS as Array;
                    // 将手中顺子的首位与打出牌的首位比较
                    if (targetTips.length > 0) {
                        for each (eachTargetTip in targetTips) {
                            var boutFirst:String = boutCards[0].replace(/\dV/, "V");
                            var targetFirst:String = eachTargetTip[0];
                            if (prioritySequence.indexOf(boutFirst) < prioritySequence.indexOf(targetFirst)) {
                                return eachTargetTip;
                            }
                        }
                    }
                }
            }
            return null;
        }

		/**
		 * 根据现有牌，按照顺子、同张、单张的优先顺序组合出唯一的牌型<br>
		 * 最大化顺子、同张，使剩余牌最少，尽量保证一次性出最多的牌
         * 
         * 基本牌型分析(格式为=>总牌数: 同张数 * 顺子长度)
         * 15: 5 * 3, 3 * 5 => 2种情况
         * 12: 4 * 3, 3 * 4 => 2种情况
         * 10: 2 * 5        => 1种情况
         * 9:  3 * 3        => 1种情况
         * 8:  2 * 4        => 1种情况
         * 6:  2 * 3        => 1种情况
         * 5:  1 * 5        => 1种情况
         * 4:  1 * 4        => 1种情况
         * 
         * 牌型组合分析
         * ----------------------------
         * 张数|组合数量|组合样式|
         * 15   (4) 5 * 3, 3 * 5, 3 * 3 + 2 * 3, 2 * 3 + 1 * 4 + 1 * 5
         * 14   (3) 2 * 5 + 1 * 4, 3 * 3 + 1 * 5, 2 * 4 + 2 * 3
         * 13   (2) 3 * 3 + 1 * 4, 2 * 4 + 1 * 5
         * 12   (4) 4 * 3, 3 * 4, 2 * 4 + 1 * 4, 2 * 3 + 2 * 3
         * 11   (1) 2 * 3 + 1 * 5
         * 10   (2) 2 * 5, 2 * 3 + 1 * 4
         * 9    (2) 1 * 4, 1 * 5
         * 8    (2) 1 * 4, 1 * 4
         * 6    (1) 2 * 3
         * 5    (1) 1 * 5
         * 4    (1) 1 * 4
         * 
		 * @param myCards
		 * @return 
		 * 
		 */
		public static function analyzeCandidateCards(myCards:Array):Array {
			var allStyles:Object = [{multiple: 3, numSeq: 5, key: TIPC_TRIPLE_SEQ5}, // 三同张五连顺
                                    {multiple: 4, numSeq: 3, key: TIPC_FOURFOLD_SEQ3}, // 四同张三连顺
									{multiple: 3, numSeq: 4, key: TIPC_TRIPLE_SEQ4}, // 三同张四连顺
									{multiple: 3, numSeq: 3, key: TIPC_TRIPLE_SEQ3}, // 三同张五连顺
									{multiple: 2, numSeq: 5, key: TIPB_DOUBLE_SEQ5}, // 对子五连顺
									{multiple: 2, numSeq: 4, key: TIPB_DOUBLE_SEQ4}, // 对子四连顺
									{multiple: 2, numSeq: 3, key: TIPB_DOUBLE_SEQ3}, // 对子三连顺，可能有两套
									{multiple: 1, numSeq: 5, key: TIPB_SEQ5}, // 五连顺
									{multiple: 1, numSeq: 4, key: TIPB_SEQ4}, // 四连顺，可能有两套
									{multiple: 8, key: TIPA_MUTIPLE8}, // 八同张
									{multiple: 7, key: TIPA_MUTIPLE7}, // 七同张，可能有两套
									{multiple: 6, key: TIPA_MUTIPLE6}, // 六同张，可能有两套
									{multiple: 5, key: TIPA_MUTIPLE5}, // 五同张，可能有三套
									{multiple: 4, key: TIPA_MUTIPLE4}, // 四同张，可能有三套
									{multiple: 3, key: TIPA_MUTIPLE3}, // 三同张，可能有五套
									{multiple: 2, key: TIPA_MUTIPLE2}];// 对子，可能有七套
            var i:int = 0;
            var eachCard:String = null;
			var myCardsString:String = myCards.join(",");
			var myCardsArray:Array = myCards.slice(0, myCards.length);
			var myUniqueCardsStyleArray:Array = new Array();
			for each (var eachStyle:* in allStyles) {
				if (eachStyle.numSeq) {
					// 获取顺子备选方案
					myUniqueCardsStyleArray.push(grabSequence(eachStyle.multiple, eachStyle.numSeq, myCardsArray));
                    // 扩展顺子，JQK=>10JQK, JQKA, 10JQKA
                    // TODO
				} else {
					// 获取同张备选方案
					myUniqueCardsStyleArray.push(grabMultiple(eachStyle.multiple, myCardsArray));
				}
				// 查找已使用过的牌
				var cardsToDelete:Array = new Array();
				var cardsInStyle:String = null;
				var uniqueCardsStyle:Array = myUniqueCardsStyleArray[myUniqueCardsStyleArray.length - 1];
				if (eachStyle.numSeq && uniqueCardsStyle && uniqueCardsStyle.length > 0) {
					// 顺子的情况
					uniqueCardsStyle = uniqueCardsStyle[uniqueCardsStyle.length - 1];
					for each (eachCard in myCardsArray) {
						cardsInStyle = uniqueCardsStyle[i];
						if (eachCard.replace(/\d/, "") == cardsInStyle || eachCard == cardsInStyle) {
							cardsToDelete.push(eachCard);
							i++;
						}
					}
				} else if (uniqueCardsStyle && uniqueCardsStyle.length > 0) {
					// 同张的情况
					for each (var eachCardsInStyle:Array in uniqueCardsStyle) {
						i = 0;
						for each (eachCard in myCardsArray) {
							cardsInStyle = eachCardsInStyle[i];
							if (eachCard.replace(/\d/, "") == cardsInStyle || eachCard == cardsInStyle) {
								cardsToDelete.push(eachCard);
								i++;
							}
						}
					}
				} else {
					myUniqueCardsStyleArray.pop();
					continue;
				}
				// 删除已使用过的牌
				for each (eachCard in cardsToDelete) {
					var startIndex:int = myCardsArray.indexOf(eachCard);
					myCardsArray.splice(startIndex, 1);
				}
			}
			for (i = 0; i < myCardsArray.length; i++) {
				// 去花色
				if ("0VX,0VY,1V5".indexOf(myCardsArray[i].toString()) > -1) {
					break;
				}
				myCardsArray[i] = myCardsArray[i].toString().replace(/\dV/, "V");
			}
			if (myCardsArray.length > 0) {
				myUniqueCardsStyleArray.push(new Array());
			}
			for each (eachCard in myCardsArray) {
				myUniqueCardsStyleArray[myUniqueCardsStyleArray.length - 1].push([eachCard]);
			}
			return myUniqueCardsStyleArray;
		}
    }
}
