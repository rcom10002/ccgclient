package test
{
    import flexunit.framework.Assert;
    
    import info.knightrcom.state.pushdownwingame.PushdownWinningCube;
    
    public class MahjongBasicWinStyleTest
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
        public function testGet_winningRoutes():void
        {
            var cube:PushdownWinningCube = new PushdownWinningCube("EAST,EAST,W1,W2,W3,B1,B1,B5,B6,B7,T3,T4,T5");
            cube.walkAllRoutes();
            Assert.assertNotNull(cube.winningRoutes);
            cube = new PushdownWinningCube("EAST,EAST,W1,W2,W2,W3,W3,W4,T3,T4,T5,T5,T5");
            cube.walkAllRoutes();
            Assert.assertNotNull(cube.winningRoutes);
        }
    }
}