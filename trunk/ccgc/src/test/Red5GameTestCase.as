package test
{
    import flexunit.framework.Assert;
    
    import info.knightrcom.state.red5game.Red5Game;
    
    import mx.controls.Alert;
    
    public class Red5GameTestCase
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

        public static function isInvincible(a:Object, b:Object):Boolean {
            return false;
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
        public static function testMatch(xxx:Object):Array {
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
            var invincibleItems:Array = [];
            var vincibleItems:Array = [];
            // 按长度对大牌和小牌进行归类，以便后期处理使用
            var invincibleItemsLengthMap:Array = [];
            var vincibleItemsLengthMap:Array = [];
            for each (var eachInvincibleItems:Array in tempInvincibleArray) {
                invincibleItems.push(eachInvincibleItems.length);
                // 按长度进行归类
                if (!invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)]) {
                    invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)] = [];
                }
                (invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)] as Array).push(eachInvincibleItems);
            }
            for each (var eachVincibleItems:Array in tempVincibleArray) {
                vincibleItems.push(eachVincibleItems.length);
                // 按长度进行归类
                if (!vincibleItemsLengthMap["L" + String(eachVincibleItems.length)]) {
                    vincibleItemsLengthMap["L" + String(eachVincibleItems.length)] = [];
                }
                (vincibleItemsLengthMap["L" + String(eachVincibleItems.length)] as Array).push(eachVincibleItems);
            }
            vincibleItems = vincibleItems.sort(Array.NUMERIC);
            invincibleItems = invincibleItems.sort(Array.NUMERIC);
            var tempVincibleString:String = null;
            var tempinvincibleString:String = null;
            // 拼凑辅助性小牌与无敌大牌的字符串
            var pieces:Array = [];
            tempVincibleArray.forEach(function(item:*, index:int, array:Array):void {
                pieces.push((item as Array).toString());
            });
            tempVincibleString = pieces.join(";");
            pieces = [];
            tempInvincibleArray.forEach(function(item:*, index:int, array:Array):void {
                pieces.push((item as Array).toString());
            });
            tempinvincibleString = pieces.join(";");
            // 生成摆渡方案，组合形式为：2,=2,1,2,=3,3,=3,1,4,=5,1
            // 其中以“=”为前缀的代表小牌的牌型，不带“=”的代表大牌的牌型，这些牌型可以从vincibleItemsLengthMap和invincibleItemsLengthMap中找到
            var discardOrderArray:Array = findAllCases(invincibleItems, vincibleItems);
            // 将匹配的内容进行处理，TODO合并
            if (discardOrderArray && discardOrderArray.length > 0) {
                discardOrderArray = discardOrderArray.toString().split(/(?<==\d),/g);
                var thisVincible:String = null; // 当前正在参与配对的小牌，可能需要分解的
                var finalDiscardCards:Array = []; // 保存计算好的出牌顺序，形式为小牌,大牌(,小牌,大牌)
                for each (var eachDiscardOrder:String in discardOrderArray) {
                    // 利用取得的拆分方案，对现有的无敌大牌，小牌进行拆分组合
                    // eachDiscardOrder为一个组合方案或是天外天
                    for each (var eachOrder:String in eachDiscardOrder.split(",")) {
                        if (eachOrder.charAt(0) == "=") {
                            // 处理小牌，将标识变量重置为空
                            thisVincible = null;
                            continue;
                        } else {
                            // 处理无敌大牌
                            if (!thisVincible && eachDiscardOrder.indexOf("=") > -1) {
                                // 根据小牌的个数来进行定位并删除
                                thisVincible = ((vincibleItemsLengthMap["L" + eachOrder] as Array).shift() as Array)[0];
                            }
                            // 放入小牌
                            if (thisVincible) {
                                finalDiscardCards.push(new Array(eachOrder).toString().replace(/,/g, thisVincible + ",").concat(thisVincible).split(","));
                            }
                            // 放入大牌
                            finalDiscardCards.push((invincibleItemsLengthMap["L" + eachOrder] as Array).shift());
                        }
                    }
                }
                return finalDiscardCards;
            } else {
                return null;
            }
        }

        /**
         * 
         * @param invincibleItems
         * @param vincibleItems
         * @param filters
         * @param singleFilter
         * @param finalResults
         * @return 
         * 
         */
        public static function findAllCases(invincibleItems:Array, vincibleItems:Array, finalResults:Array = null, filters:String = "", singleFilter:String = ""):Array {
            var tempItems:Array = null;
            var discardOrder:Array = [];
            if (!finalResults) {
                finalResults = [];
            }
            if (filters.length == 0) {
                tempItems = invincibleItems;
                if (!tempItems) {
                    return null;
                }
            } else {
                tempItems = invincibleItems.toString().replace(new RegExp("[" + singleFilter + "]"), "").replace(/,{2,}/g, ",").replace(/^,|,$/g, "").split(",");
            }
            if (tempItems[0].toString().length == 0) {
                finalResults.push(filters);
                return null;
            }
            for (var i:int = 0; i < tempItems.length; i++) {
                if (int(filters.charAt(0)) > vincibleItems[0]) {
                    break;
                }
                findAllCases(tempItems, vincibleItems, finalResults, filters + tempItems[i], tempItems[i]);
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
                        if (sumValue == vincibleItems[i]) {
                            discardOrder.push("=" + sumValue);
                            sumValue = 0;
                            i++;
                        } else if (sumValue > vincibleItems[i]) {
                            discardOrder = [];
                            break;
                        }
                    }
                    if (i == vincibleItems.length) {
                        tempItems = discardOrder;
                        return tempItems;
                    }
                }
            }
            return null;
        }

        [Test]
        public function testMe():void
        {
//            Assert.assertNotNull([["V10", "V10"], ["2VQ", "2VQ", "4VQ"], ["2V5", "3V5", "4V5"]].join(";"));
//            Assert.assertNotNull(findAllCases([1, 1, 1, 2, 2, 3, 4], [2, 3, 3, 5]));
            Assert.assertNotNull(findAllCases([1], [1, 2]));
        }
//        [Test]
//        public function testAnalyzeCandidateCards():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence1():void
//        {
//            var myCards:Array = "V10,V10,VJ,VJ,VQ,VQ,VK,VA".split(",");
//            Red5Game.analyzeMultipleSequence(myCards);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence2():void
//        {
//            var myCards:Array = "V10,V10,VJ,VJ,VQ,VQ,VK,VK,VA".split(",");
//            Red5Game.analyzeMultipleSequence(myCards);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence3():void
//        {
//            var myCards:Array = "V10,VJ,VJ,VJ,VQ,VQ,VQ,VK,VK,VK,VA".split(",");
//            Red5Game.analyzeMultipleSequence(myCards);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence4():void
//        {
//            var myCards:Array = "V10,V10,V10,VJ,VJ,VJ,VQ,VQ,VQ,VK,VK,VK,VA,VA".split(",");
//            Red5Game.analyzeMultipleSequence(myCards);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence5():void
//        {
//            var myCards:Array = "V10,V10,VJ,VJ,VJ,VJ,VQ,VQ,VQ,VQ,VK,VK,VK,VK,VA".split(",");
//            Red5Game.analyzeMultipleSequence(myCards);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence6():void
//        {
//            var myCards:Array = "V10,V10,VJ,VJ,VJ,VJ,VQ,VQ,VQ,VQ,VK,VK,VK,VK,VA,VA,VA".split(",");
//            Red5Game.analyzeMultipleSequence(myCards);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence7():void
//        {
//            var myCards:Array = "V10,VJ,VJ,VQ,VQ,VK,VK,VA".split(",");
//            Red5Game.analyzeMultipleSequence(myCards);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence8():void
//        {
//            var myCards:Array = "V10,V10,VJ,VJ,VQ,VQ,VQ,VK,VK,VK".replace(/V/g, "1V").split(",");
//            var result:Object = Red5Game.analyzeCandidateCards(myCards);
//            trace(result);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence9():void
//        {
//            var myCards:Array = "1V10,2V10,3V10,4V10,1VJ,2VJ,3VJ,1VK,2VK,3VK,4VK,1V2,2V5,2V5,0VY".split(",");
//            var result:Object = Red5Game.analyzeCandidateCards(myCards);
//            trace(result);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence10():void
//        {
//            var myCards:Array = "1V10,2V10,1VJ,2VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,3VA,4VA,1V2,2V5,2V5,0VY".split(",");
//            var result:Object = Red5Game.analyzeCandidateCards(myCards);
//            trace(result);
//            myCards = "1V10,2V10,1VJ,2VJ,2VJ,4VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,2V5,2V5,0VY".split(",");
//            result = Red5Game.analyzeCandidateCards(myCards);
//            trace(result);
//            myCards = "1V10,2V10,1VJ,2VJ,2VJ,4VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,3VA,2V5,0VY".split(",");
//            result = Red5Game.analyzeCandidateCards(myCards);
//            trace(result);
//        }
//        
//        [Test]
//        public function testAnalyzeMultipleSequence11():void
//        {
//            var myCards:Array = "1V10,2V10,2V10,1VJ,2VJ,2VJ,3VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,3VA,4VA".split(",");
//            var result:Object = Red5Game.analyzeCandidateCards(myCards);
//            trace(result);
//            myCards = "1V10,2V10,4V10,1VJ,2VJ,2VJ,4VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,1VA,2V5,2V5,0VY".split(",");
//            result = Red5Game.analyzeCandidateCards(myCards);
//            trace(result);
//            myCards = "1V10,2V10,1VJ,2VJ,2VJ,4VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,3VA,2V5,0VY".split(",");
//            result = Red5Game.analyzeCandidateCards(myCards);
//            trace(result);
//        }
//        
        [Test]
        public function testAnalyzeMultipleSequence12():void
        {
            var myCards:Array = new Array(
                "1V10,2V10,1VJ,2VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,3VA,4VA,2V2,2V5,1V5",
                "4V5,4VJ,4VK,3VJ,0VX,3V5,4VA,3VK,3VQ,3VA,3V2,1VK,0VX,3V10,4VA",
                "1V2,2VK,2V10,0VY,3VJ,3V2,2VA,4V10,2VJ,4V2,4VK,2V5,4VQ,1VQ,4V2",
                "1VA,2VK,4V5,3VK,2V2,3V5,3V10,1VJ,2V10,2V2,4V10,2VQ,1VK,4VJ,1V10",
                "1V10,1VJ,2VJ,1VQ,2VQ,3VQ,4VQ,1VA,2VA,3VA,1V2,2V5,0VY,1V5,1V5"
            );
            for each (var eachCards:String in myCards) {
                var eachCardsArray:Array = Red5Game.sortPokers(eachCards);
                var result:Array = Red5Game.analyzeCandidateCards(eachCardsArray);
                trace(result);
                Assert.assertTrue(result.toString().split(",").length == 15);
            }
        }
        
//        [Test]
//        public function testGetBrainPowerTip():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testGetMultiple():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testGetStraightLength():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testGrabMultiple():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testGrabSequence():void
//        {
//            var results:Array = Red5Game.analyzeSequence("2V10,1VJ,1VJ,2VJ,2VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,3VK,3VK,2VA,3VA".split(","));
//            // var results:Array = Red5Game.grabSequence(2, 3, "1V10,1V10,2VJ,2VJ,3VQ,3VQ,4VQ,4VQ,1VK,2VK,3VA,3VA".split(","));
//            for each (var eachResult:Array in results) {
//                trace(eachResult.join(","));
//            }
//        }
//        
//        [Test]
//        public function testGrabTips():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testIsRuleFollowed():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testIsSeveralFoldStyle():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testIsSingleStyle():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testIsStraightStyle():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testNextTipCards():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testRed5Game():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testRefreshTips():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
//        
//        [Test]
//        public function testSortPokers():void
//        {
//            Assert.fail("Test method Not yet implemented");
//        }
    }
}