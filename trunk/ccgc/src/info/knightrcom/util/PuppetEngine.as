package info.knightrcom.util {
    import component.Scoreboard;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.MouseEvent;
    import flash.utils.getDefinitionByName;
    
    import info.knightrcom.puppet.GamePinocchio;
    import info.knightrcom.puppet.GamePinocchioEvent;
    import info.knightrcom.puppet.Red5GamePinocchio;
    import info.knightrcom.puppet.PushdownWinGamePinocchio;
    
    import mx.controls.Button;
    import mx.core.Application;
    import mx.core.Container;
    import mx.events.StateChangeEvent;
    import mx.managers.ISystemManager;
    
    /**
     * 该类用于为所有的Puppet实现提供必要的公共方法，如登录、进入房间、加入游戏等功能
     * 
     */
    public class PuppetEngine {
        
        private static const INTERVAL_LOGIN:int = 5000;
        
        private static const INTERVAL_ENTER_ROOM:int = 5000;
        
        private static const INTERVAL_JOIN_GAME:int = 60000;
        
        public function PuppetEngine() {
            throw Error("This class can not be initialized!");
        }
        
        /**
         *
         * 创建Puppet实例对象
         * 
         * @param securityPassword
         * @param classPrefix Red5, FightLandlord ...
         * @param username
         * @param password
         * @param roomId
         * @return
         *
         */
        public static function createPinocchioPuppet(securityPassword:String, classPrefix:String, username:String, password:String, roomId:String):GamePinocchio {
            // 创建实例对象
            var a:Red5GamePinocchio;
            var b:PushdownWinGamePinocchio;
            var gamePuppetType:Class = getDefinitionByName("info.knightrcom.puppet." + classPrefix + "GamePinocchio") as Class;
            var puppet:GamePinocchio = new gamePuppetType(username, password, roomId);

			// 登录游戏平台，每隔 N 秒执行一次登录操作直到进入平台为止
            puppet.prepareActionTimer(INTERVAL_LOGIN, function():void {
                    if (Application.application.currentState == "LOBBY") {
                        puppet.resetActionTimer();
                        puppet.prepareActionTimer(INTERVAL_ENTER_ROOM, function():void {
                                if (!puppet.enterRoom()) {
                                    return;
                                }
                                // 立即执行一次
                                puppet.joinGame();
                                puppet.resetActionTimer();
                            }).start();
                    } else {
                        // FIXME This should be fixed for removing all model windows
                        // iterateAllModelWindow(null, true);
                        puppet.loginPlatform();
                    }
                }).start();
            // 运行时相关
            // ===> 游戏开始，整理牌型
            ListenerBinder.bind(puppet, GamePinocchioEvent.GAME_START, function (event:GamePinocchioEvent):void {
                puppet.startGame(event);
            });
			// ===> 游戏进行，游戏设置
			ListenerBinder.bind(puppet, GamePinocchioEvent.GAME_SETTING, function (event:GamePinocchioEvent):void {
                    puppet.prepareActionTimer(intervalRandom(), function():void {
                        puppet.selectGameSetting(event)
                        puppet.resetActionTimer();
                    }).start();
                });
			// ===> 游戏进行，智能出牌
            ListenerBinder.bind(puppet, GamePinocchioEvent.GAME_BOUT, function (event:GamePinocchioEvent):void {
                    puppet.prepareActionTimer(intervalRandom(2, 6), function():void {
                        puppet.preoperateGame(event);
                        puppet.operateGame(event);
                        puppet.resetActionTimer();
                    }).start();
                });
            // ===> 游戏结束，游戏结束时关闭积分面板并返回游戏大厅
            ListenerBinder.bind(puppet, GamePinocchioEvent.GAME_END, function(event:GamePinocchioEvent):void {
// FIXME remove all managed Alert windows
//                    iterateAllModelWindow(function(target:*):void {
//                            if (target is Scoreboard) {
//                                puppet.backToLobby();
//                            }
//                        });
//                    // 加入游戏，从游戏大厅加入游戏
//                    puppet.prepareActionTimer(INTERVAL_JOIN_GAME, function():void {
//                            if (Application.application.currentState == "LOBBY") {
//                                iterateAllModelWindow(null, true);
//                                puppet.joinGame();
//                            } else {
//                                puppet.resetActionTimer();
//                            }
//                        }).start();
                    puppet.prepareActionTimer(intervalRandom(), function():void {
                        puppet.backToLobby(event);
                        puppet.resetActionTimer();
                        // var joinGameFunc:Function = function (e:Event):void {
                            // 每隔 M 秒执行一次加入游戏
                            puppet.prepareActionTimer(INTERVAL_JOIN_GAME, function():void {
                                if (Application.application.currentState == "LOBBY") {
                                    // FIXME This should be fixed for removing all model windows
                                    // iterateAllModelWindow(null, true);
                                    puppet.joinGame();
                                } else {
                                    puppet.resetActionTimer();
                                }
                            }).start();
                        // };
                        // ListenerBinder.bind(Application.application as EventDispatcher, StateChangeEvent.CURRENT_STATE_CHANGE, joinGameFunc);
                    }).start();
                });
            return puppet;
        }
        
        /**
         *
         * @param username
         * @param password
         *
         */
        public static function loginPlatform(username:String, password:String):void {
            Application.application.txtUsername.text = username;
            Application.application.txtPassword.text = password;
            Application.application.btnSubmit.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
        }
        
        /**
         *
         * @param roomId
         *
         */
        public static function enterRoom(roomId:String):Boolean {
            for each (var lobby:Container in Application.application.acdnLobbys.getChildren()) {
                for each (var roomButton:Button in lobby.getChildren()) {
                    if (roomButton.name == roomId) {
                        roomButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                        return true;
                    }
                }
            }
            return false;
        }
        
        /**
         *
         * 加入游戏
         *
         */
        public static function joinGame():void {
            Application.application.gameControlBar.btnGameJoin.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
        }
        
//        /**
//         *
//         *
//         */
//        public static function backToLobby():void {
//            iterateAllModelWindow(function(target:*):void {
//                    if (target is Scoreboard) {
//                        (target as Scoreboard).btnClose.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//                    }
//                });
//        }
//        
//        /**
//         *
//         * 遍历所有的模态窗口<br>
//         *
//         * @param callbackFunc 每当遍历到一个模态窗口，就会将当前窗口传递给回调函数callbackFunc
//         * @param removeInvoked 是否删除所有模态窗口
//         *
//         */
//        public static function iterateAllModelWindow(callbackFunc:Function = null, removeInvoked:Boolean = false):void {
//            // code reference "http://blog.flexmonkeypatches.com/2007/10/04/flex-close-all-popups/"
//            var systemManager:ISystemManager = Application.application.systemManager;
//			// if you scope your popups to PopUpManagerChildList.POPUP
//			// this is all you should have to check to clear all popups
////			while(systemManager.popUpChildren.numChildren > 0){
////				if (callbackFunc != null) {
////					callbackFunc(systemManager.popUpChildren.getChildAt(0));
////				}
////				if (removeInvoked) {
//////					PopUpManager.removePopUp(systemManager.popUpChildren.getChildAt(0) as IFlexDisplayObject);
//////					systemManager.removeChildAt(0);
////					systemManager.popUpChildren.removeChildAt(0);
////				}
////			}
//			// if you scope your popups to other than PopUpManagerChildList.POPUP
//			// you need to scan this and check the class name to decide if you need to remove the child
////			for (var i:int = systemManager.numChildren - 1; i >= 0; i--) {
////				if (callbackFunc != null) {
////					callbackFunc(systemManager.getChildAt(i));
////				}
////				if(/*getQualifiedClassName(systemManager.getChildAt(i)) == "Popup" && */removeInvoked){
////					systemManager.removeChildAt(i);
////				}
////			}
//        }

        /**
         * 
         * 返回随机时间间隔，默认为3至8秒之间
         * 
         * @param min
         * @param max
         * @return 
         * 
         */
        private static function intervalRandom(min:Number = 3, max:Number = 8):Number {
            var scale:Number = max - min;
            return Math.round(Math.random() * scale + min) * 1000;
        }

        /**
         *
         * @param securityPassword
         * @return
         *
         */
        private static function isValidSecurityPassword(securityPassword:String):Boolean {
            // get the orignal string sequence
            var orgC1:String = securityPassword.charAt(2);
            var orgC2:String = securityPassword.charAt(securityPassword.length - 3);
            var orgChars:String = orgC1 + orgC2;
            var expectedResult:String = MD5.encode(orgChars);
            expectedResult = expectedResult.replace(/^(.{2}).(.*)$/, orgC1);
            expectedResult = expectedResult.replace(/^(.*?).(.{2})$/, orgC2);
            return securityPassword == expectedResult;
        }
    }
}
