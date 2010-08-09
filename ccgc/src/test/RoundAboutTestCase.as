package test
{
    import info.knightrcom.state.red5game.Red5Game;

    public class RoundAboutTestCase
    {		
        [Before]
        public function setUp():void
        {
        }
        
        [After]
        public function tearDown():void
        {
        }
        
        [BeforeClass]
        public static function setUpBeforeClass():void
        {
        }
        
        [AfterClass]
        public static function tearDownAfterClass():void
        {
        }
        
        [Test]
        public function testSample():void {
            var dummyTips:Array = [
                [["V10"],["VK"],["0VX"],["1V5"]],
                [["VJ","VJ","VQ","VQ","VK","VK"]]
            ];
            dummyTips = [
                [["V10"],["0VX"],["1V5"]],
                [["VK","VK"],["V5","V5"]],
                [["V2","V2","V2"]],
                [["VJ","VJ","VQ","VQ","VK","VK"]]
            ];
            dummyTips = [
                [["VK"],["1V5"]],
                [["VQ","VQ"]]
            ];
            var result:* = testRoundabout(dummyTips, tipCount(dummyTips));
            trace(result);
        }

        private function isInvincible(tipCards:Array, x:Boolean = false):Boolean {
            if (tipCards.toString().match(/10|[JQKA]/)) {
                return false;
            }
            return true;
        }

        /**
         * 当前剩余牌型个数
         * 
         * @param dummyTips
         * @return 
         */
        private function tipCount(dummyTips:Array = null):int {
            var count:int = 0;
            for each (var eachItems:Array in dummyTips) {
                count += eachItems.length;
            }
            return count;
        }

        /**
         * 
         * 统计出所有的无敌大牌与小牌，让大牌与小牌配对
         * 
         * @param dummyTips  所有提示牌型
         * @param myTipCount 玩家当前手中的牌型个数
         * @return 当没有可用的摆渡策略时，返回null，否则返回摆渡策略结果
         */
        private function testRoundabout(dummyTips:Array, myTipCount:int):Object {
            if (myTipCount < 3) {
                return null;
            }
            // 整理提示牌型，数组形式为：[【V10】,【V5】],[【VJ,VJ】],[【V10,VJ,VQ,VK】]
            var xxx:Object = {
                invincible: [],
                vincible: [],
                invincibleSeq: [],
                vincibleSeq: [],
                maxLengthVincible: [] // 牌数最多的非顺子牌型
            };
            // 大小牌归类
            for each (var eachTips:Array in dummyTips) {
                for each (var tipCards:Array in eachTips) {
                    if (isInvincible(tipCards, false)) {
                        // 无敌大牌
                        if (Red5Game.isStraightStyle(tipCards.join(","))) {
                            (xxx.invincibleSeq as Array).push(tipCards);
                        } else {
                            (xxx.invincible as Array).push(tipCards);
                        }
                    } else {
                        // 非无敌大牌
                        if (Red5Game.isStraightStyle(tipCards.join(","))) {
                            (xxx.vincibleSeq as Array).push(tipCards);
                        } else {
                            (xxx.vincible as Array).push(tipCards);
                            // 设置牌数最多的非顺子牌型
                            if (xxx.maxLengthVincible) {
                                xxx.maxLengthVincible = xxx.maxLengthVincible.length < tipCards.length ? tipCards : xxx.maxLengthVincible;
                            } else {
                                xxx.maxLengthVincible = tipCards;
                            }
                        }
                    }
                }
            }
            if (xxx.vincibleSeq.length > 1) {
                // 存在一种以上的非无敌顺子大牌
                return null;
            }
            if (xxx.vincibleSeq.length == 1) {
                // 存在一种顺子非无敌大牌
                xxx.hasSeqTail = true;
            }
            if (tipCount(xxx.invincible) < tipCount(xxx.vincible)) {
                // 当无敌大牌总和大于无敌小牌总和时，需要最后一个出牌数最多的小牌
                xxx.hasVincibleTail = true;
            }
            if (xxx.hasSeqTail && xxx.hasVincibleTail) {
                // 需要最后出顺子小牌和非无敌大牌时
                return null;
            }
            if (xxx.hasVincibleTail && (tipCount(xxx.invincible) < tipCount(xxx.vincible) - xxx.maxLengthVincible.length)) {
                // 需要最后一个出非无敌大牌，且无敌大牌个数的总和小于无敌小牌个数的总和与牌数最多的小牌的个数差时
                return null;
            }
            
            // 组合摆渡对儿，即相同牌型的一个非无敌大牌对应一个无敌大牌
            if (xxx.hasVincibleTail) {
                // 从xxx的非无敌大牌中，去除牌数最多的非无敌大牌
                (xxx.vincible as Array).splice((xxx.vincible as Array).indexOf(xxx.maxLengthVincible), 1);
            }
            xxx.discardCards = testMatch(xxx);
            // 补充尾牌
            if (xxx.discardCards) {
                var tailCards:Array = null;
                if (xxx.hasVincibleTail) {
                    (xxx.discardCards as Array).push(xxx.maxLengthVincible);
                } else if (xxx.hasSeqTail) {
                    (xxx.discardCards as Array).push(xxx.vincibleSeq[0]);
                }
            }
            xxx.discardIndex = 0;
            return xxx.discardCards ? xxx : null;
        }
        
        /**
         *  // 整理提示牌型，数组形式为：["V10","V5","VJ,VJ"],["V10,VJ,VQ,VK"],["1V5,1V5"]
         *  var xxx:Object = {
         *      invincible: [],
         *      vincible: [],
         *      invincibleSeq: [],
         *      vincibleSeq: [],
         *      maxLengthVincible: [] // 牌数最多的非顺子牌型
         *  };
         * @param xxx
         * @return 
         * 
         */
        private function testMatch(xxx:Object):Array {
            // 筛选非无敌大牌(不包含顺子)
            var tempVincibleArray:Array = [];
            // 处理小牌
            for each (var eachVincible:Array in (xxx.vincible as Array)) {
                tempVincibleArray.push(eachVincible);
            }
            // 将对子及同张的无敌大牌继续拆分成多个张数更少的牌型
            var tempInvincibleArray:Array = [];
            for each (var eachInvincible:Array in (xxx.invincible as Array)) {
                if (/^V(10|[JQKA])$/.test(eachInvincible[0]) || eachInvincible.length == 1) {
                    // 跳过单张或是以10、J、Q、K、A开头的牌
                    tempInvincibleArray.push(eachInvincible);
                    continue;
                }
                // 开始拆分
                if ("1V5,1V5,0VX,0VX,0VY,0VY".indexOf("," + eachInvincible[0].toString()) > -1) {
                    // 对红五或对大王或对小王
                    if (eachInvincible.toString().indexOf("0VX") > -1 && isInvincible(["0VX"], false)) {
                        tempInvincibleArray.push(["0VX"]);
                        tempInvincibleArray.push(["0VX"]);
                    } else if (eachInvincible.toString().indexOf("0VY") > -1 && isInvincible(["0VY"], false)) {
                        tempInvincibleArray.push(["0VY"]);
                        tempInvincibleArray.push(["0VY"]);
                    } else if (eachInvincible.toString().indexOf("1V5") > -1) {
                        tempInvincibleArray.push(["1V5"]);
                        tempInvincibleArray.push(["1V5"]);
                    } else {
                        tempInvincibleArray.push(eachInvincible);
                    }
                } else if (eachInvincible[0].toString().indexOf("V5") > -1) {
                    // 草五
                    if (eachInvincible.length <= 3 && isInvincible(["V5"], false)) {
                        eachInvincible.forEach(function(item:*, index:int, array:Array):void {
                            tempInvincibleArray.push(["V5"]);
                        });
                    } else if (eachInvincible.length > 3 && isInvincible(["V5", "V5"], false)) {
                        // 四张或更多草五时
                        switch (eachInvincible.length) {
                            case 4:
                                tempInvincibleArray.push(["V5", "V5"]);
                                tempInvincibleArray.push(["V5", "V5"]);
                                break;
                            case 5:
                                tempInvincibleArray.push(["V5", "V5"]);
                                tempInvincibleArray.push(["V5", "V5", "V5"]);
                                break;
                            case 6:
                                tempInvincibleArray.push(["V5", "V5"]);
                                if (isInvincible(["V5"], false)) {
                                    tempInvincibleArray.push(["V5"]);
                                    tempInvincibleArray.push(["V5", "V5", "V5"]);
                                } else {
                                    tempInvincibleArray.push(["V5", "V5"]);
                                    tempInvincibleArray.push(["V5", "V5"]);
                                }
                                break;
                        }
                    } else {
                        tempInvincibleArray.push(eachInvincible);
                    }
                } else if (false) {
                    // TODO 暂时不拆分2，如果拆分，拆成3张+X张，X可能为vincible
                    //                    // 2
                    //                    if (isInvincible(["0VX"], false)) {
                    //                        
                    //                    }
                } else {
                    tempInvincibleArray.push(eachInvincible);
                }
            }
            // 考虑效率问题，暂时只处理张数在【6】以内的无敌大牌
            if (tempInvincibleArray.length > 6) {
                return null;
            }
            // 开始进行大牌与小牌进行配对
            var invincibleLengthArray:Array = [];
            var vincibleLengthArray:Array = [];
            // 按长度对大牌和小牌进行归类，以便后期处理使用
            var invincibleItemsLengthMap:Array = [];
            var vincibleItemsLengthMap:Array = [];
            for each (var eachInvincibleItems:Array in tempInvincibleArray) {
                invincibleLengthArray.push(eachInvincibleItems.length);
                // 按长度进行归类
                if (!invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)]) {
                    invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)] = [];
                }
                (invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)] as Array).push(eachInvincibleItems);
            }
            for each (var eachVincibleItems:Array in tempVincibleArray) {
                vincibleLengthArray.push(eachVincibleItems.length);
                // 按长度进行归类
                if (!vincibleItemsLengthMap["L" + String(eachVincibleItems.length)]) {
                    vincibleItemsLengthMap["L" + String(eachVincibleItems.length)] = [];
                }
                (vincibleItemsLengthMap["L" + String(eachVincibleItems.length)] as Array).push(eachVincibleItems);
            }
//            var sortFunc:Function = function (cards1:Array, cards2:Array):int {
//                if (cards1.length > cards2.length) {
//                    return 1;
//                } else if (cards1.length < cards2.length) {
//                    return -1
//                }
//                return 0;
//            };
            invincibleLengthArray = invincibleLengthArray.sort(Array.NUMERIC);
            vincibleLengthArray = vincibleLengthArray.sort(Array.NUMERIC);
            
            // 拼凑辅助性小牌与无敌大牌的字符串
            /*
            var pieces:Array = [];
            var tempVincibleString:String = null;
            var tempinvincibleString:String = null;
            tempVincibleArray.forEach(function(item:*, index:int, array:Array):void {
            pieces.push((item as Array).toString());
            });
            tempVincibleString = pieces.join(";");
            pieces = [];
            tempInvincibleArray.forEach(function(item:*, index:int, array:Array):void {
            pieces.push((item as Array).toString());
            });
            tempinvincibleString = pieces.join(";");
            */
            // 生成摆渡方案，组合形式为：2,=2,1,2,=3,3,=3,1,4,=5,1
            // 其中以“=”为前缀的代表小牌的牌型，不带“=”的代表大牌的牌型，这些牌型可以从vincibleItemsLengthMap和invincibleItemsLengthMap中找到
            var discardOrderArray:Array = testAllCases(invincibleLengthArray, vincibleLengthArray);
            // 将匹配的内容进行处理，TODO合并
            if (discardOrderArray && discardOrderArray.length > 0) {
                discardOrderArray = discardOrderArray.toString().split(/(?<==\d),/g);
                var thisVincible:String = null; // 当前正在参与配对的小牌，可能需要分解的
                var finalDiscardCards:Array = []; // 保存计算好的出牌顺序，形式为小牌,大牌(,小牌,大牌)
                for each (var eachDiscardOrder:String in discardOrderArray) {
                    // 利用取得的拆分方案，对现有的无敌大牌，小牌进行拆分组合
                    // eachDiscardOrder为一个组合方案或是天外天
                    var invincibleStyle:String = "";
                    for each (var eachOrder:String in eachDiscardOrder.split(",")) {
                        if (eachOrder.charAt(0) == "=") {
                            // 放入小牌
                            var valueParts:Array = (vincibleItemsLengthMap["L" + eachOrder.replace(/=/, "")] as Array).shift();
                            for (var i:int = invincibleStyle.length - 1; i >=0 ; i--) {
                                finalDiscardCards.splice(i, 0, valueParts.slice(0, invincibleStyle.charAt(i)));
                            }
                            invincibleStyle = "";
                        } else {
                            // 放入大牌
                            if (eachDiscardOrder.indexOf("=") == -1) {
                                finalDiscardCards.push((invincibleItemsLengthMap["L" + eachOrder] as Array).shift());
                            } else {
                                finalDiscardCards.unshift((invincibleItemsLengthMap["L" + eachOrder] as Array).shift());
                            }
                            invincibleStyle += eachOrder;
                        }
                    }
                }
                return finalDiscardCards;
            } else {
                return null;
            }
        }
        
        /**
         * 根据给定的大牌牌型和小牌牌型，让大小牌配对，匹配不上的大牌不做处理。<br />
         * 小牌的牌数总和小于大牌的牌数总和。
         * 
         * @param invincibleArray 无敌大牌
         * @param vincibleArray   送死小牌
         * @param filters         辅助参数，可以忽略
         * @param singleFilter    辅助参数，可以忽略
         * @param finalResults    辅助参数，可以忽略
         * @return Array 1,2,=3,2,2,=4,1,4,=5
         * 
         */
        private function testAllCases(invincibleLengthArray:Array, vincibleLengthArray:Array, finalResults:Array = null, filters:String = "", singleFilter:String = ""):Array {
            var tempItems:Array = null;
            var discardOrder:Array = [];
            if (!finalResults) {
                finalResults = [];
            }
            if (filters.length == 0) {
                tempItems = invincibleLengthArray;
                if (!tempItems) {
                    return null;
                }
            } else {
                tempItems = invincibleLengthArray.toString().replace(new RegExp("[" + singleFilter + "]"), "").replace(/,{2,}/g, ",").replace(/^,|,$/g, "").split(",");
            }
            if (tempItems[0].toString().length == 0) {
                finalResults.push(filters);
                return null;
            }
            for (var i:int = 0; i < tempItems.length; i++) {
                if (int(filters.charAt(0)) > vincibleLengthArray[0]) {
                    break;
                }
                testAllCases(tempItems, vincibleLengthArray, finalResults, filters + tempItems[i], tempItems[i]);
            }
            if (filters.length == 0) {
                // 摆独匹配
                for each (var eachItem:String in finalResults) {
                    var sumValue:int = 0;
                    i = 0;
                    tempItems = eachItem.split("");
                    for each (eachItem in tempItems) {
                        sumValue += int(eachItem);
                        discardOrder.push(int(eachItem));
                        if (sumValue == vincibleLengthArray[i]) {
                            discardOrder.push("=" + sumValue);
                            sumValue = 0;
                            i++;
                        } else if (sumValue > vincibleLengthArray[i]) {
                            discardOrder = [];
                            break;
                        }
                    }
                    if (i == vincibleLengthArray.length) {
                        tempItems = discardOrder;
                        return tempItems;
                    }
                }
            }
            return null;
        }
    }
}