package info.knightrcom.util {
    import flash.display.Loader;
    import flash.display.Stage;
    import flash.display.StageDisplayState;
    import flash.net.URLRequest;

    public class PlatformRepresentationUtil {

        public function PlatformRepresentationUtil():void {
        }

        public static function loadExternalSWF(stage:Stage, url:String):void {
            var request:URLRequest = new URLRequest(url);
            var loader:Loader = new Loader()
            loader.load(request);
            while (stage.numChildren > 0) {
                stage.removeChildAt(0);
            }
            stage.addChild(loader);
        }

        public static function toggleStageDisplayState(stage:Stage, displayState:String = null):void {
            try {
                if (displayState != null) {
                    stage.displayState = displayState;
                }
                switch (stage.displayState) {
                    case StageDisplayState.FULL_SCREEN:
                        /* If already in full screen mode, switch to normal mode. */
                        stage.displayState = StageDisplayState.NORMAL;
                        break;
                    default:
                        /* If not in full screen mode, switch to full screen mode. */
                        stage.displayState = StageDisplayState.FULL_SCREEN;
                        break;
                }
            } catch (err:SecurityError) {
                // ignore
            }
        }
    }
}