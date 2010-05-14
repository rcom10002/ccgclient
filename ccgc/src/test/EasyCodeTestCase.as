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
        public function testArraySplit():void {
            Assert.assertEquals(['a', 'b'].toString().split(",").length, 2);
            trace("OK");
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
            Assert.assertEquals("2,=2,1,2,=3,3,=3,1,4,=5,1".split(/(?<==\d),/g).length, 5);
        }
        
        [Test]
        public function testArrayEvery():void {
            var isNumeric:Function = function (element:*, index:int, arr:Array):Boolean {
                return (element is Number);
            };

            var arr1:Array = new Array(1, 2, 4);
            var res1:Boolean = arr1.every(isNumeric);
            trace("isNumeric:", res1); // true
            
            var arr2:Array = new Array(1, 2, "ham");
            var res2:Boolean = arr2.every(isNumeric);
            trace("isNumeric:", res2); // false
        }

        [Test]
        public function testArraySome():void {
            var arr:Array = new Array();
            arr[0] = "one";
            arr[1] = "two";
            arr[3] = "four";
            var isUndefined:Function = function (element:*, index:int, arr:Array):Boolean {
                return (element == undefined);
            };
            var isUndef:Boolean = arr.some(isUndefined);
            if (isUndef) {
                trace("array contains undefined values: " + arr);
            } else {
                trace("array contains no undefined values.");
            }
        }
    }
}