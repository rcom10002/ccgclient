package info.knightrcom.puppet
{
	import component.MahjongButton;
	import component.PlatformAlertUI;
	import component.PokerButton;
	
	import flash.events.MouseEvent;
	
	import info.knightrcom.puppet.GamePinocchio;
	import info.knightrcom.puppet.GamePinocchioEvent;
	import info.knightrcom.state.PushdownWinGameStateManager;
	import info.knightrcom.state.pushdownwingame.PushdownWinGame;
	import info.knightrcom.state.pushdownwingame.PushdownWinMahjongBox;
	
	import mx.controls.Button;
	import mx.core.Application;
    
	/**
	 *　　万里长城十亿兵,<br/>
     *　　国耻岂待儿孙平;<br/>
     *　　愿提十万虎狼旅,<br/>
     *　　越马扬刀入东京.<br/>
     *　　大江南北十亿兵,<br/>
     *　　国仇就在今生平.<br/>
     *　　中华傲立世界日, <br/>
     *　　铁甲十万灭东瀛.
	 */
    public dynamic class PushdownWinGamePinocchio extends GamePinocchio {

        private var _gameBox:PushdownWinMahjongBox = null;

        private var roundabout:Object = null;

        /**
		 * 
		 * @param username
		 * @param password
		 * @param roomId
		 * 
		 */
		public function PushdownWinGamePinocchio(username:String, password:String, roomId:String) {
            super(username, password, roomId);
        }
        
        /**
         * 
         * @param event
         * 
         */
        public override function startGame(event:GamePinocchioEvent) : void {
            this.tips = event.tag;
        }
        
        /**
         *
		 * @param event
         *
         */
        public override function selectGameSetting(event:GamePinocchioEvent):void {
        }

		/**
		 *
		 * @param event
		 *
		 */
		public override function operateGame(event:GamePinocchioEvent):void {
            // 系统已经强制出牌，则放弃本次自主出牌
            if (!Application.application.pushdownWinGameModule.btnBarMahjongs.visible) {
                return;
            }
            
            // 本地变量
            var boutMahjong:String = PushdownWinGameStateManager.currentBoutMahjong;
            // 执行操作
            for each (var eachBtn:Button in Application.application.pushdownWinGameModule.btnBarMahjongs.getChildren().reverse()) {
                if (eachBtn.enabled) {
                    eachBtn.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                    break;
                }
            }
            if (Application.application.pushdownWinGameModule.btnBarMahjongs.visible) {
                (Application.application.pushdownWinGameModule.candidatedDown.getChildAt(0) as MahjongButton).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            }
//            if (!(Application.application.pushdownWinGameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP) as Button).enabled) {
//                boutMahjong = null;
//            }
//            var eachCardsStyle:Array, eachItem:Array = null;
//            var isAlliance:Boolean = isAlliance();
//            var myTipCount:int = tipCount();
//            
//            // 重选备用牌
//            Application.application.pushdownWinGameModule.btnBarPokers.getChildAt(Red5Game.OPTR_RESELECT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//            
//            // 2010-04-27 ADDED [摆渡牌判断与出牌] BEGIN 
//            if (Red5GameStateManager.gameSetting != Red5GameSetting.DEADLY_RUSH && Red5GameStateManager.gameSetting != Red5GameSetting.EXTINCT_RUSH && this.roundabout) {
//                // 按照【roundabout】方式出牌或跟牌
//                if (processRoundaboutDiscard(boutMahjong)) {
//                    return;
//                }
//            }
//            // 2010-04-27 ADDED [摆渡牌判断与出牌] END
//            
//            if (!boutMahjong) {
//                // 当前玩家出牌***规则定义
//                // 2010-04-27 ADDED [摆渡牌判断与出牌] BEGIN 
//                if (Red5GameStateManager.gameSetting != Red5GameSetting.DEADLY_RUSH && Red5GameStateManager.gameSetting != Red5GameSetting.EXTINCT_RUSH && !this.roundabout) {
//                    // 进行【roundabout】测试
//                    this.roundabout = testRoundabout(this.tips, myTipCount);
//                    if (this.roundabout) {
//                        // 按照【roundabout】方式出牌或跟牌
//                        if (processRoundaboutDiscard(boutMahjong)) {
//                            return;
//                        }
//                    }
//                }
//                // 2010-04-27 ADDED [摆渡牌判断与出牌] END
//                processDiscard(myTipCount);
//            } else {
//                // 当前玩家跟牌***规则定义
//                
//                // 计算发牌者手中牌型套数
//                var currentTipCount:int = tipCount(Red5Game.analyzeCandidateCards(this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array));
//                
//                // 没默认牌型跟时
//                if (!isAlliance && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
//                    // 敌对时，有玩家独牌
//                    processHostileRushFollow(boutMahjong, currentTipCount);
//                } else if (!isAlliance) {
//                    // 敌对时，各自为战
//                    processHostileNoRushFollow(boutMahjong, myTipCount, currentTipCount);
//                } else {
//                    // 同盟时，即有玩家独牌且已出牌者与当前玩家为友邦关系
//                    processAlliedRushFollow(boutMahjong, myTipCount, currentTipCount);
//                }
//            }
//            
//            // 执行不要操作
//            if (Application.application.pushdownWinGameModule.btnBarPokers.visible) {
//                Application.application.pushdownWinGameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//            }
		}
        
        /**
         *
         * @param value
         *
         */
        public override function set gameBox(value:*):void {
            this._gameBox = value;
        }

        private function processDiscard(boutMahjong:String/*, currentTipCount:int*/):void {
            
        }
    }
}
