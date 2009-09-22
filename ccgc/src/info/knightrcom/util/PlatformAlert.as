package info.knightrcom.util {
    import component.PlatformAlertUI;
    
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import mx.controls.Button;
    import mx.core.Application;
    import mx.managers.PopUpManager;

    public class PlatformAlert {

        private static var platformAlertUI:PlatformAlertUI = null;

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
            platformAlertUI = new PlatformAlertUI();
            platformAlertUI = PlatformAlertUI(PopUpManager.createPopUp(Application.application as DisplayObject, PlatformAlertUI, true));
            platformAlertUI.msg.text = msg
            platformAlertUI.title.text = title
            PopUpManager.centerPopUp(platformAlertUI);

            if (closeHandler != null) {
                ListenerBinder.bind(platformAlertUI, PLATFORM_EVENT, closeHandler);
            }

            var btn:Button = new Button();
            if (!btns || btns.length == 0) {
                ListenerBinder.bind(btn, MouseEvent.CLICK, handleClick);
                btn.label = "OK";
                platformAlertUI.btns.addChild(btn)
            } else {
                for (var i:int = 0; i < btns.length; i++) {
                    if (btns[i] == null) {
                        continue;
                    }
                    btn = new Button();
                    ListenerBinder.bind(btn, MouseEvent.CLICK, handleClick);
                    btn.label = btns[i];
                    btn.data = i;
                    platformAlertUI.btns.addChild(btn)
                }
            }
            Button(platformAlertUI.btns.getChildAt(defaultFocusIndex)).setFocus();
            var timer:Timer = new Timer(500, 10);
            timer["waitSec"] = 10;
            ListenerBinder.bind(timer, TimerEvent.TIMER, function (e:TimerEvent):void {
            	timer["waitSec"] -= 1;
            	platformAlertUI.title.text = platformAlertUI.title.text.replace(/\(\d*\)$/, "") + "(" + (timer["waitSec"]) + ")";
            });
            ListenerBinder.bind(timer, TimerEvent.TIMER_COMPLETE, function (e:TimerEvent):void {
            	(btns[0] as Button).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            	PopUpManager.removePopUp(platformAlertUI);
            });
        }

        /**
         *
         * @param e
         *
         */
        private static function handleClick(e:MouseEvent):void {
            PopUpManager.removePopUp(platformAlertUI);
            platformAlertUI.dispatchEvent(new PlatformAlertEvent(PLATFORM_EVENT, String(Button(e.currentTarget).data)));
        }

    }
}