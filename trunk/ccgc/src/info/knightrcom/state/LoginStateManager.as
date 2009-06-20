package info.knightrcom.state {
    import flash.display.StageDisplayState;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.command.PlayerCommand;
    import info.knightrcom.event.PlayerEvent;
    
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
            myState.addEventListener(FlexEvent.ENTER_STATE, init);
        }

        /**
         * 初始化
         */
        private function init(event:Event):void {
            // 配置事件监听
            // 非可视组件
            socketProxy.addEventListener(PlayerEvent.LOGIN_SUCCESS, loginEventHandler);
            socketProxy.addEventListener(PlayerEvent.LOGIN_USER_ALREADY_ONLINE, loginEventHandler);
            socketProxy.addEventListener(PlayerEvent.LOGIN_ERROR_USERNAME_OR_PASSWORD, loginEventHandler);
            socketProxy.addEventListener(PlayerEvent.LOGIN_MAX_CONNECTION_LIMIT, loginEventHandler);
            // 可视组件
            gameClient.btnConnect.addEventListener(MouseEvent.CLICK, connectClick);
            gameClient.btnSubmit.addEventListener(MouseEvent.CLICK, submitClick);
            gameClient.btnReset.addEventListener(MouseEvent.CLICK, resetClick);
        }

        /**
         * 登录结果响应
         */
        private function loginEventHandler(event:PlayerEvent):void {
            switch (event.type) {
                case PlayerEvent.LOGIN_SUCCESS:
                	BaseStateManager.currentProfileId = event.incomingData;
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
            }
        }

        /**
         * 连接按钮动作
         */
        private function connectClick(event:Event):void {
            try {
                if (socketProxy.isConnected()) {
                    Alert.show("连接已经完成！", "信息");
                    return;
                }
                socketProxy.connect();
            } catch (error:Error) {
                trace(error.message);
            }
        }

        /**
         * 提交按钮动作
         */
        private function submitClick(event:Event):void {
            try {
                if (Validator.validateAll(gameClient.loginValidators).length == 0) {
                    var data:Array = new Array(gameClient.txtUsername.text, gameClient.txtPassword.text);
                    if (!socketProxy.isConnected()) {
                        socketProxy.connect();
                    }
                    socketProxy.sendPlayerData(PlayerCommand.LOGIN_SIGN_IN, data.join("~"));
                }
            } catch (error:Error) {
                trace(error.message);
            }
        }

        /**
         * 重置按钮动作
         */
        private function resetClick(event:Event):void {
            try {
                gameClient.txtUsername.text = "";
                gameClient.txtPassword.text = "";
            } catch (error:Error) {
                trace(error.message);
            }
        }
    }
}
