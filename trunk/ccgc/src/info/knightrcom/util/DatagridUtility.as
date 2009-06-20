package info.knightrcom.util {

    import mx.core.UIComponent;


    public class DatagridUtility extends UIComponent {

        public function DatagridUtility() {
        }


        /**
         *
         * @param fieldName 要进行比较的dataField名称
         * @param compareType 要进行比较的数据类型 0: 数字。默认为数字比较。
         * @return
         *
         */
        public static function commonCompare(fieldName:String, compareType:int = 0):Function {
            if (compareType == 0) {
                return function (obj1:Object, obj2:Object):int {
                	var e4x1:XML = new XML(obj1);
                	var e4x2:XML = new XML(obj2);
                    var num:Number = Number(e4x1[fieldName]) - Number(e4x2[fieldName]);
                    return (num > 0) ? 1 : ((num < 0) ? -1 : 0);
                }
            } else {
            	return null;
            }
        }
    }
}

