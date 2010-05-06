package info.knightrcom.util
{
    import mx.formatters.DateFormatter;

    public class Logger
    {
        public function Logger()
        {
        }

        private static var dateFormmater:DateFormatter = new DateFormatter();
        
        /**
         * 
         * @param obj
         * 
         */
        public static function debug(obj:*):void {
            print(obj, "DEBUG =>");
        }
        
        /**
         * 
         * @param obj
         * 
         */
        public static function warn(obj:*):void {
            print(obj, "WARN  =>");
        }
        
        /**
         * 
         * @param obj
         * 
         */
        public static function info(obj:*):void {
            print(obj, "INFO  =>");
        }
        
        /**
         * 
         * @param obj
         * @param model
         * @return 
         * 
         */
        public static function print(obj:*, model:String = null):String {
            dateFormmater.formatString = "YYYY-MM-DD JJ:NN:SS";
            var logText:String = "[" + dateFormmater.format(new Date()) + "] " + (model ? model.concat(" ") : "") + obj;
            trace(logText);
            return logText;
        }
    }
}
