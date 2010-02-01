package info.knightrcom.state {
    import flash.display.StageDisplayState;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.external.ExternalInterface;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.event.PlatformEvent;
    import info.knightrcom.util.ListenerBinder;
    
    import mx.controls.Alert;
    import mx.core.Application;
    import mx.states.State;

    public class BaseStateManager extends AbstractStateManager {

        public static var currentLobbyId:String;

        public static var currentRoomId:String;

		public static var currentProfileId:String;

		public static var currentUserId:String;

        /**
         *
         * @param socketProxy
         * @param gameClient
         * @param myStage
         *
         */
        public function BaseStateManager(socketProxy:GameSocketProxy, myStage:State = null):void {
            super(socketProxy, myState);
        }

        /**
         *
         * @param event
         *
         */
        public function init(event:Event = null):void {
            if (!isInitialized()) {
                // 配置事件监听
                ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_CONNECTED, globalEventHandler);
                ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_SESSION_TIMED_OUT, globalEventHandler);
                ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_DISCONNECTED, globalEventHandler);
                ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_IO_ERROR, globalEventHandler);
                ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_SECURITY_ERROR, globalEventHandler);
                ListenerBinder.bind(socketProxy, PlatformEvent.PLATFORM_INSTANT_MESSAGE_BROADCASTED, globalEventHandler);
                ListenerBinder.bind(socketProxy, PlatformEvent.PLATFORM_CONSOLE_MESSAGE_BROADCASTED, globalEventHandler);
                // 全屏
    			ListenerBinder.bind(gameClient.btnScreenMode, MouseEvent.CLICK, toggleScreenMode);
                // 连接服务器
                // TODO DROP THIS LINE socketProxy.connect();
                // 设置初始化标识
                setInitialized(true);
            }

            // 切换画面状态
            gameClient.currentState = "LOGIN";
        }

        /**
         *
         * @param event
         *
         */
        public function globalEventHandler(event:PlatformEvent):void {
            switch (event.type) {
                case PlatformEvent.SERVER_CONNECTED:
                    // Alert.show("网络连接成功！", "信息");
                    break;
                case PlatformEvent.SERVER_SESSION_TIMED_OUT:
                    Alert.show("本次会话已经过期，请重新登录！", "信息", 4, gameClient, function():void {
                    	flash.external.ExternalInterface.call("location.reload", true);
                    });
                    break;
                case PlatformEvent.SERVER_DISCONNECTED:
                    Alert.show("网络连接已断开！", "错误", 4, gameClient, function():void {
                    	flash.external.ExternalInterface.call("location.reload", true);
                    });
                    break;
                case PlatformEvent.SERVER_IO_ERROR:
                    Alert.show("网络通信故障！", "错误", 4, gameClient, function():void {
                    	flash.external.ExternalInterface.call("location.reload", true);
                    });
                    break;
                case PlatformEvent.SERVER_SECURITY_ERROR:
                    Alert.show("网络通信安全设置有错误！", "错误", 4, gameClient, function():void {
                    	flash.external.ExternalInterface.call("location.reload", true);
                    });
                    break;
                case PlatformEvent.PLATFORM_INSTANT_MESSAGE_BROADCASTED:
                    // 显示系统消息
                    gameClient.txtSysNotification.text = event.incomingData;
                    gameClient.setChildIndex(gameClient.instantMessageTip, gameClient.numChildren - 1);
                    gameClient.instantMessageTip.visible = true;
                    break;
                case PlatformEvent.PLATFORM_CONSOLE_MESSAGE_BROADCASTED:
                    // 显示系统消息
                    if (gameClient.currentState == "LOBBY") {
                        gameClient.txtSysMessage.text += "系统消息：" + event.incomingData + "\n";
                    } else {
                    	Alert.show(event.incomingData, "系统消息B");
                    }
                    break;
            }
        }

		/**
		 * 
		 * @param event
		 * 
		 */
		private function toggleScreenMode(event:Event):void {
            try {
                switch (Application.application.stage.displayState) {
                    case StageDisplayState.FULL_SCREEN:
                        /* If already in full screen mode, switch to normal mode. */
                        Application.application.stage.displayState = StageDisplayState.NORMAL;
                        break;
                    default:
                        /* If not in full screen mode, switch to full screen mode. */
                        Application.application.stage.displayState = StageDisplayState.FULL_SCREEN;
                        break;
                }
            } catch (err:SecurityError) {
                // ignore
                Alert.show("Error occurs!\n" + err.message);
            }
		}

    }
}
