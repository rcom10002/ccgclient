package info.knightrcom.state {
    import flash.display.StageDisplayState;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
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

        /**
         *
         * @param socketProxy
         * @param gameClient
         * @param myStage
         *
         */
        public function BaseStateManager(socketProxy:GameSocketProxy, gameClient:CCGameClient, myStage:State = null):void {
            super(socketProxy, gameClient, myState);
        }

        /**
         *
         * @param event
         *
         */
        public function init(event:Event = null):void {
            // 配置事件监听
            ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_CONNECTED, globalEventHandler);
            ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_SESSION_TIMED_OUT, globalEventHandler);
            ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_DISCONNECTED, globalEventHandler);
            ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_IO_ERROR, globalEventHandler);
            ListenerBinder.bind(socketProxy, PlatformEvent.SERVER_SECURITY_ERROR, globalEventHandler);
            ListenerBinder.bind(socketProxy, PlatformEvent.PLATFORM_MESSAGE_BROADCASTED, globalEventHandler);

			ListenerBinder.bind(gameClient.btnScreenMode, MouseEvent.CLICK, toggleScreenMode);

            // 连接服务器
            socketProxy.connect();

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
                    if (gameClient.currentState != "LOGIN") {
                        gameClient.currentState = "LOGIN"
                    }
                    Alert.show("本次会话已经过期，请重新登录！", "信息");
                    break;
                case PlatformEvent.SERVER_DISCONNECTED:
                    if (gameClient.currentState != "LOGIN") {
                        gameClient.currentState = "LOGIN"
                    }
                    Alert.show("网络连接失败！", "错误");
                    break;
                case PlatformEvent.SERVER_IO_ERROR:
                    if (gameClient.currentState != "LOGIN") {
                        gameClient.currentState = "LOGIN"
                    }
                    Alert.show("网络通信故障！", "错误");
                case PlatformEvent.SERVER_SECURITY_ERROR:
                    if (gameClient.currentState != "LOGIN") {
                        gameClient.currentState = "LOGIN"
                    }
                    Alert.show("网络通信安全设置有错误！", "错误");
                case PlatformEvent.PLATFORM_MESSAGE_BROADCASTED:
                    // 显示系统消息
                    if (gameClient.currentState == "LOBBY") {
                        Alert.show(event.incomingData, "系统消息");
                    }
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
