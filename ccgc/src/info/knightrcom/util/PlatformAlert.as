package info.knightrcom.util {
    import component.PlatformAlertUI;

    import flash.display.DisplayObject;
    import flash.events.MouseEvent;

    import mx.controls.Button;
    import mx.core.Application;
    import mx.managers.PopUpManager;

    public class PlatformAlert {

        private static var platformAlertUI:PlatformAlertUI = new PlatformAlertUI();

        private static const PLATFORM_EVENT:String = "PlatformAlertEvent"

        /**
         *
         * @param msg
         * @param title
         * @param btns
         * @param closeHandler
         *
         */
        public static function show(msg:String, title:String = null, btns:Array = null, closeHandler:Function = null, defaultFocusIndex:int = 0):void {

            platformAlertUI = PlatformAlertUI(PopUpManager.createPopUp(Application.application as DisplayObject, PlatformAlertUI, true));
            platformAlertUI.msg.text = msg
            platformAlertUI.title.text = title
            PopUpManager.centerPopUp(platformAlertUI);

            if (closeHandler != null)
                platformAlertUI.addEventListener(PLATFORM_EVENT, closeHandler);

            var btn:Button = new Button();
            if (!btns || btns.length == 0) {
                btn.addEventListener(MouseEvent.CLICK, handleClick);
                btn.label = "OK";
                platformAlertUI.btns.addChild(btn)
            } else {
                for (var i:int = 0; i < btns.length; i++) {
                    if (btns[i] == null) {
                        continue;
                    }
                    btn = new Button();
                    btn.addEventListener(MouseEvent.CLICK, handleClick);
                    btn.label = btns[i];
                    btn.data = i;
                    platformAlertUI.btns.addChild(btn)
                }
            }
            Button(platformAlertUI.btns.getChildAt(defaultFocusIndex)).setFocus();
        }

        /**
         *
         * @param e
         *
         */
        private static function handleClick(e:MouseEvent):void {
            PopUpManager.removePopUp(platformAlertUI)
            platformAlertUI.dispatchEvent(new PlatformAlertEvent(PLATFORM_EVENT, String(Button(e.currentTarget).data)));
        }

    }
}