package test
{
    import flexunit.framework.Assert;
    
    public class EasyCodeTestCase
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
        public function testArrayForEach():void {
            var pieces:Array = [];
            ([["V10", "V10"], ["2VQ", "2VQ", "4VQ"], ["2V5", "3V5", "4V5"]] as Array).forEach(function(item:*, index:int, array:Array):void {
                pieces.push((item as Array).toString());
            });
            trace(pieces.join(";"));
            Assert.assertNotNull(pieces);
        }
        
        [Test]
        public function testRegExpLookAheadPattern():void {
            Assert.assertEquals("2,=2,1,2,=3,3,=3,1,4,=5,1".split(/(?<==\d),/g), 5);
        }
    }
}