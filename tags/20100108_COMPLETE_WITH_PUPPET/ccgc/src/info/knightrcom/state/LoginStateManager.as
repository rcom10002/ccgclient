package info.knightrcom.state {
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.command.PlayerCommand;
    import info.knightrcom.event.PlayerEvent;
    import info.knightrcom.util.ListenerBinder;
    
    import mx.controls.Alert;
    import mx.events.FlexEvent;
    import mx.states.State;
    import mx.validators.Validator;

    public class LoginStateManager extends AbstractStateManager {

        /**
         *
         * @param socketProxy
         * @param gameClient
         * @param myState
         *
         */
        public function LoginStateManager(socketProxy:GameSocketProxy, gameClient:CCGameClient, myState:State):void {
            super(socketProxy, gameClient, myState);
            ListenerBinder.bind(myState, FlexEvent.ENTER_STATE, init);
        }

        /**
         * 初始化
         */
        private function init(event:Event):void {
            if (!isInitialized()) {
                // 配置事件监听
                // 非可视组件
                ListenerBinder.bind(socketProxy, PlayerEvent.LOGIN_SUCCESS, loginEventHandler);
                ListenerBinder.bind(socketProxy, PlayerEvent.LOGIN_USER_ALREADY_ONLINE, loginEventHandler);
                ListenerBinder.bind(socketProxy, PlayerEvent.LOGIN_ERROR_USERNAME_OR_PASSWORD, loginEventHandler);
                ListenerBinder.bind(socketProxy, PlayerEvent.LOGIN_MAX_CONNECTION_LIMIT, loginEventHandler);
                ListenerBinder.bind(socketProxy, PlayerEvent.LOGIN_IP_CONFLICT, loginEventHandler);
                // 可视组件
                ListenerBinder.bind(gameClient.btnConnect, MouseEvent.CLICK, connectClick);
                ListenerBinder.bind(gameClient.btnSubmit, MouseEvent.CLICK, submitClick);
                ListenerBinder.bind(gameClient.btnReset, MouseEvent.CLICK, resetClick);
                // 设置初始化标识
                setInitialized(true);
            }
        }

        /**
         * 登录结果响应
         */
        private function loginEventHandler(event:PlayerEvent):void {
            switch (event.type) {
                case PlayerEvent.LOGIN_SUCCESS:
                	BaseStateManager.currentProfileId = event.incomingData;
                	// FIXME this line should get data from server
                	BaseStateManager.currentUserId = gameClient.txtUsername.text;
                    gameClient.currentState = "LOBBY";
                    break;
                case PlayerEvent.LOGIN_USER_ALREADY_ONLINE:
                    Alert.show("当前用户已经登录，系统不允许重复登录！", "警告");
                    break;
                case PlayerEvent.LOGIN_ERROR_USERNAME_OR_PASSWORD:
                    Alert.show("用户名或密码错误！", "警告");
                    break;
                case PlayerEvent.LOGIN_MAX_CONNECTION_LIMIT:
                    Alert.show("当前服务器登录人数已满！", "警告");
                    break;
                case PlayerEvent.LOGIN_IP_CONFLICT:
                    Alert.show("相同的IP地址不可以重复登录！", "警告");
                    break;
            }
        }

        /**
         * 连接按钮动作
         */
        private function connectClick(event:Event):void {
            if (socketProxy.isConnected()) {
                Alert.show("连接已经完成！", "信息");
                return;
            }
            socketProxy.connect();
        }

        /**
         * 提交按钮动作
         */
        private function submitClick(event:Event):void {
            if (Validator.validateAll(gameClient.loginValidators).length == 0) {
                var data:Array = new Array(gameClient.txtUsername.text, gameClient.txtPassword.text);
                if (!socketProxy.isConnected()) {
                    socketProxy.connect();
                }
                socketProxy.sendPlayerData(PlayerCommand.LOGIN_SIGN_IN, data.join("~"));
            }
        }

        /**
         * 重置按钮动作
         */
        private function resetClick(event:Event):void {
            gameClient.txtUsername.text = "";
            gameClient.txtPassword.text = "";
            gameClient.txtUsername.setFocus();
        }
    }
}
