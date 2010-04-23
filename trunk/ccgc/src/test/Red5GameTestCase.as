package test
{
    import flexunit.framework.Assert;
    
    import info.knightrcom.state.red5game.Red5Game;
    
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