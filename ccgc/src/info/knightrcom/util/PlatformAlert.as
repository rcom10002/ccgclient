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

        private static var timer:Timer = null;

        /**
         *
         * @param msg
         * @param title
         * @param btns
         * @param closeHandler
         *
         */
        public static function show(msg:String, title:String = null, btns:Array = null, closeHandler:Function = null, defaultFocusIndex:int = 0):void {
            // 创建UI对象
            platformAlertUI = new PlatformAlertUI();
            platformAlertUI = PlatformAlertUI(PopUpManager.createPopUp(Application.application as DisplayObject, PlatformAlertUI, true));
            platformAlertUI.msg.text = msg
            platformAlertUI.title.text = title

            // 注册关闭事件
            if (closeHandler != null) {
                ListenerBinder.bind(platformAlertUI, PLATFORM_EVENT, closeHandler);
            }

            // 添加动作按钮
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
                    btn.setStyle("textRollOverColor", "#000000");
                    platformAlertUI.btns.addChild(btn)
                }
            }

            // 设置默认焦点
            Button(platformAlertUI.btns.getChildAt(defaultFocusIndex)).setFocus();

            // 设置动态标题
            timer = new Timer(1000, 10);
            ListenerBinder.bind(timer, TimerEvent.TIMER, function (e:TimerEvent):void {
            	platformAlertUI.title.text = "(" + (10 - timer.currentCount) + ")";
            });
            ListenerBinder.bind(timer, TimerEvent.TIMER_COMPLETE, function (e:TimerEvent):void {
            	(platformAlertUI.btns.getChildAt(0) as Button).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            	// PopUpManager.removePopUp(platformAlertUI);
            });
            timer.start();

            // 显示UI画面
            PopUpManager.centerPopUp(platformAlertUI);
        }

        /**
         *
         * @param e
         *
         */
        private static function handleClick(e:MouseEvent):void {
            if (timer != null) {
                timer.stop();
                timer = null;
            }
            PopUpManager.removePopUp(platformAlertUI);
            platformAlertUI.dispatchEvent(new PlatformAlertEvent(PLATFORM_EVENT, String(Button(e.currentTarget).data)));
        }

    }
}