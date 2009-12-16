package info.knightrcom.util
{
    import mx.formatters.DateFormatter;

    public class Logger
    {
        public function Logger()
        {
        }

        private static var dateFormmater:DateFormatter = new DateFormatter();
        
        public static function debug(obj:*):void {
            print(obj, "DEBUG =>");
        }
        
        public static function warn(obj:*):void {
            print(obj, "WARN  =>");
        }
        
        public static function info(obj:*):void {
            print(obj, "INFO  =>");
        }
        
        public static function print(obj:*, model:String):void {
            dateFormmater.formatString = "YYYY-MM-DD JJ:NN:SS";
            trace("[" + dateFormmater.format(new Date()) + "] " + model + " " + obj);
        }
    }
}
