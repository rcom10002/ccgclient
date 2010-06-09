package test
{
    import flexunit.framework.Assert;
    
    import mx.collections.ArrayCollection;
    
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
        
        [Test]
        public function testAllCasesVersion1():void {
            var samples:Array = 'A,B,C,D,E'.split(",");
            var allCases:Array = [];
            for (var i:int = 0; i < samples.length; i++) {
                allCases[i] = [];
                for (var j:int = 0; j < samples.length; j++) {
                    allCases[i][j] = (i == j) ? samples[i] : samples[i] + samples[j];
                    // trace(allCases[i][j]);
                }
            }
            var allFinalCases:Array = [];
            var triedCases:Array = [];
            var line:int = 1;
            for (i = 0; i < samples.length; i++) {
                var finalResult:String = allCases[0][i];
                while (line < samples.length) {
                    for (j = 0; j < samples.length; j++) {
                        finalResult += "," + allCases[line][j];
                    }
                    line++;
                }
                trace(finalResult);
                line = 1;
            }
        }
        
        [Test]
        public function testAllCasesVersion2():void {
            var samples:Array = 'A,B,C,D,E'.split(",");
            var isCircle:String = samples.toString();
            var absPos:int = samples.length - 2;
            var relPos:int = 0;
            var index:int = 0;
            var target:String = null;
            var count:int = 0;
            var results:Array = [];
            while (true) {
                count += samples.length * 2;
                for (index = samples.length - 1; index > 0; index--) {
                    target = samples[index - 1];
                    samples[index - 1] = samples[index];
                    samples[index] = target;
                    results.push(samples.toString());
                }
                // moving element is in first place
                relPos = absPos-- + 1;
                target = samples[relPos - 1];
                samples[relPos - 1] = samples[relPos];
                samples[relPos] = target;
                results.push(samples.toString());
                absPos = (absPos == 0 ? samples.length - 2 : absPos);
                if (samples.toString() == isCircle) {
                    break;
                }
                for (index = 0; index < samples.length - 1; index++) {
                    target = samples[index + 1];
                    samples[index + 1] = samples[index];
                    samples[index] = target;
                    results.push(samples.toString());
                }
                // moving element is in last place
                relPos = absPos--;
                target = samples[relPos - 1];
                samples[relPos - 1] = samples[relPos];
                samples[relPos] = target;
                results.push(samples.toString());
                absPos = (absPos == 0 ? samples.length - 2 : absPos);
                if (samples.toString() == isCircle) {
                    break;
                } 
            }
            
            trace(results);
        }
        
        [Test]
        public function testAllCasesVersion3():void {
//            var samples:Array = 'A'.split(",");
//            var samples:Array = 'A,B'.split(",");
//            var samples:Array = 'A,B,C'.split(",");
//            var samples:Array = 'A,B,C,D'.split(",");
            var samples:Array = 'A,B,C,D,E'.split(",");
            var results:Array = [];
            var finalResults:Array = [];
trace(new Date());
            for each (var sample:String in samples) {
                // sample stands for each element
                if (results.length == 0) {
                    results.push([sample]);
                    continue;
                }
                for (var i:int = 0; i < results.length; i++) {
                    for (var pos:int = 0; pos <= results[i].length; pos++) {
                        var resultAC:ArrayCollection = new ArrayCollection(results[i].toString().split(","));
                        resultAC.addItemAt(sample, pos);
                        finalResults.push(resultAC.toArray());
                    }
                }
                results = finalResults;
                finalResults = [];
            }
trace(new Date());
            trace(results.length);
        }
        
        [Test]
        public function testAllCasesVersion4():void {
            var vincibleLengthArray:Array = [1, 2, 2, 4];
            var invincibleLengthArray:Array = [1, 1, 2, 2, 3];
            
        }
        
    }
}
