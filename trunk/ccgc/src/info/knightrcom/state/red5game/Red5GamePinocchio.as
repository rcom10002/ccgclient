package info.knightrcom.state.red5game
{
	import component.PlatformAlertUI;
	import component.PokerButton;
	
	import flash.events.MouseEvent;
	
	import info.knightrcom.puppet.GamePinocchio;
	import info.knightrcom.puppet.GamePinocchioEvent;
	import info.knightrcom.state.Red5GameStateManager;
	
	import mx.controls.Button;
	import mx.core.Application;
    
	/**
	 * 
	 * 
	 */
    public dynamic class Red5GamePinocchio extends GamePinocchio {

		/**
		 * 
		 * @param username
		 * @param password
		 * @param roomId
		 * @param gameSetting
		 * 
		 */
		public function Red5GamePinocchio(username:String, password:String, roomId:String, gameSetting:String = null) {
            super(username, password, roomId, gameSetting);
        }
        
        /**
         *
		 * @param event
         *
         */
        public override function selectGameSetting(event:GamePinocchioEvent):void {
			var btnLabel:String = Red5GameSetting.getNoRushStyle()[Number(this.gameSetting)];
			for each (var eachButton:Button in (event.tag as PlatformAlertUI).btns.getChildren()) {
				if (eachButton.label == btnLabel) {
					eachButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					break;
				}
			}
        }
		
		/**
		 *
		 * @param event
		 *
		 */
		public override function operateGame(event:GamePinocchioEvent):void {
			var red5GameStateManager:Red5GameStateManager = Application.application.getGameStateManager(Red5GameStateManager);
			var currentNumber:int = Red5GameStateManager.currentNextNumber;
			var currentNextNumber:int = Red5GameStateManager.currentNextNumber;
			var localNumber:int = Red5GameStateManager.localNumber;
			var localNextNumber:int = Red5GameStateManager.localNextNumber;
			var gameFinalSettingNumber:int = Red5GameStateManager.gameFinalSettingPlayerNumber;
			var boutCards:String = Red5GameStateManager.currentBoutCards;
			if (!(Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP) as Button).enabled) {
				boutCards = null;
			}
			// 判断出牌者是否为己方、牌型以及大小
			for each (var eachCardsStyle:Array in tips) {
				for each (var eachItem:Array in eachCardsStyle) {
                    if (boutCards == null || Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                        prepareCandidatedCards(eachCardsStyle, eachItem);
                        return;
                    }
				}
			}
			// 执行不要操作
			Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		}
		
        /**
         * 
         * @param eachCardsStyle
         * @param eachItem
         * 
         */
        private function prepareCandidatedCards(eachCardsStyle:Array, eachItem:Array):void {
            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_RESELECT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            eachCardsStyle.splice(eachCardsStyle.indexOf(eachItem), 1);
            if (eachCardsStyle.length == 0) {
                tips.splice(tips.indexOf(eachCardsStyle), 1);
            }
            // 准备出牌
            var i:int = 0;
            for each (var eachPokerButton:PokerButton in Application.application.red5GameModule.candidatedDown.getChildren())
            {
                // 不计花色比较
                if (eachPokerButton.value.replace(/\d/, "") ==  eachItem[i] || eachPokerButton.value ==  eachItem[i]) {
                    eachPokerButton.setSelected(true);
                    i++;
                }
            }
            if (Application.application.red5GameModule.btnBarPokers.visible) {
                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            }
        }

		/**
		 * 
		 * 默认方案<br>
		 * 按照独牌方式
		 * 
		 */
		private function defaultSolution():void
		{
			// 牌型分析※
			// 红五、大小王、草五、二；顺子、同张、单张
			/*var cardSeqs:Object = 
				{C1:
				 C2:
				 C3:};*/
			
			// 首发牌判断
			// 单牌、同张(含对子)、连牌
			
			// 判断对方牌型
			
			// 组织牌型
			
			// 出牌
		}
		
		/**
		 * 
		 * 简单方案<br>
		 * 牌型分析采用智能分析，然后以默认方案处理后续内容
		 * 
		 */
		private function simpleSolution():void
		{
			
		}

//		/**
//		 *
//		 * @param event
//		 *
//		 */
//		public override function backToLobby(event:GamePinocchioEvent):void {
//			(event.tag as Scoreboard).btnClose.dispatchEvent(new Event(MouseEvent.CLICK));
//		}
    }
}