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

        private var _gameBox:Red5GameBox = null;

        /**
		 * 
		 * @param username
		 * @param password
		 * @param roomId
		 * 
		 */
		public function Red5GamePinocchio(username:String, password:String, roomId:String) {
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
            var gameSetting:int, myTipCount:int = 0;
            myTipCount = this.tipCount();
            // 天外天判断
            var isExtinctRush:Function = function ():Boolean {
                if (myTipCount == 1) {
                    return true;
                }
                for each (var eachCardsStyle:Array in tips) {
                    for each (var eachItem:Array in eachCardsStyle) {
                        if (isInvincible(eachItem, false)) {
                        } else {
                            return false;
                        }
                    }
                }
                return true;
            };
            // 天独判断
            var isDeadlyRush:Function = function():Boolean {
                var invicibleCount:int = 0;
                for each (var eachCardsStyle:Array in tips) {
                    for each (var eachItem:Array in eachCardsStyle) {
                        if (isInvincible(eachItem, false)) {
                            invicibleCount++;
                        }
                    }
                }
                if ((invicibleCount + 1) == myTipCount) {
                    return true;
                }
                return false;
            };
            // 独牌判断
            var isRush:Function = function():Boolean {
                var cards:Array = null;
                // 必须要有红五
                cards = Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/1V5/);
                if (!cards) {
                    return false;
                }
                // 大小王总数至少要等于二
                cards = Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/[XY]/);
                if (cards && cards.length >= 2) {
                    if (2 < myTipCount && myTipCount <= 5) {
                        return true;
                    }
                } else {
                    if (2 < myTipCount && myTipCount <= 4) {
                        return true;
                    }
                    return false;
                }
                // 草五、王和红五的合计张数，应该大于等于七
                cards = Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/[5XY]/);
                if (cards && cards.length >= 7) {
                } else if (cards && cards.length >= 5) {
                    // 如果有五张或更多的话，可以用四个二代替
                    cards = Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/[2]/);
                    if (cards && cards.length > 3) {
                    } else {
                        return false;
                    }
                }
                return true;
            };
            if (isExtinctRush()) {
                // 天外天
                gameSetting = 3;
            } else if (isDeadlyRush()) {
                // 天独
                gameSetting = 2;
            } else if (isRush()) {
                // 独牌
                gameSetting = 1;
            } else {
                // 不独
                gameSetting = 0;
            }
			var btnLabel:String = Red5GameSetting.getNoRushStyle()[gameSetting];
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
            // 全局变量别名
			var currentNumber:int = Red5GameStateManager.currentNumber;
			var currentNextNumber:int = Red5GameStateManager.currentNextNumber;
			var localNumber:int = Red5GameStateManager.localNumber;
			var localNextNumber:int = Red5GameStateManager.localNextNumber;
			var gameFinalSettingNumber:int = Red5GameStateManager.gameFinalSettingPlayerNumber;
			var boutCards:String = Red5GameStateManager.currentBoutCards;
//            if (localNumber != currentNextNumber) {
//                return;
//            }
			if (!(Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP) as Button).enabled) {
				boutCards = null;
			}
            // 本地变量
            var eachCardsStyle:Array, eachItem:Array, myCardArray:Array = null;
            var myCards:String = "";
            var isAlliance:Boolean = isAlliance();
            var minValue:Array = null;
            var myTipCount:int = tipCount();

            // 重选备用牌
            // Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_HINT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_RESELECT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));

            if (!boutCards) {
                // 当前玩家出牌***规则定义
                if (myTipCount <= 4) {
                    // 按照从小到大，从多到少的规则进行出牌
                    for each (eachCardsStyle in this.tips) {
                        for each (eachItem in eachCardsStyle) {
                            if (Red5GameStateManager.gameSetting == Red5GameSetting.DEADLY_RUSH || Red5GameStateManager.gameSetting == Red5GameSetting.EXTINCT_RUSH) {
                                // 天外天或天独时
                                if (isInvincible(eachItem)) {
                                    // 首次发牌或有与上家发牌对应的牌时
                                    prepareCandidatedCards(eachItem);
                                    // 开始出牌
                                    if (Application.application.red5GameModule.btnBarPokers.visible) {
                                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                        return;
                                    }
                                }
                            }
                            if (Red5Game.isStraightStyle(eachItem.join(",").replace(/(?<!\\d)V/g, "4V"))) {
                                // 优先出顺子
                                prepareCandidatedCards(eachItem);
                                // 开始出牌
                                if (Application.application.red5GameModule.btnBarPokers.visible) {
                                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                    return;
                                }
                            }
                        }
                    }
                    // 先出全局最大的牌
                    if (myTipCount == 2) {
                        for each (eachCardsStyle in this.tips) {
                            for each (eachItem in eachCardsStyle) {
                                if (isInvincible(eachItem)) {
                                    // 首次发牌或有与上家发牌对应的牌时
                                    prepareCandidatedCards(eachItem);
                                    // 开始出牌
                                    if (Application.application.red5GameModule.btnBarPokers.visible) {
                                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                        return;
                                    }
                                }
                            }
                        }
                    }
//                    // 先出最小的牌，不计牌型
//                    minValue = null;
//                    for each (eachCardsStyle in this.tips) {
//                        for each (eachItem in eachCardsStyle) {
//                            if (minValue == null) {
//                                minValue = eachItem;
//                            } else if (Red5Game.isRuleFollowed(minValue[0].replace(/(?<!\d)V/g, "4V"), eachItem[0].replace(/(?<!\d)V/g, "4V"))) {
//                                minValue = eachItem;
//                            }
//                        }
//                    }
//                    // 首次发牌或有与上家发牌对应的牌时
//                    prepareCandidatedCards(minValue);
//                    // 开始出牌
//                    if (Application.application.red5GameModule.btnBarPokers.visible) {
//                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//                        return;
//                    }
                } // end of tipCount() <= 4
                // 从默认的备选牌型中提取含有最小值的牌型
                minValue = null;
                for each (eachCardsStyle in this.tips) {
                    for each (eachItem in eachCardsStyle) {
                        if (minValue == null) {
                            minValue = eachItem;
                        } else if (Red5Game.isRuleFollowed(minValue[0].replace(/(?<!\d)V/g, "4V"), eachItem[0].replace(/(?<!\d)V/g, "4V"))) {
                            minValue = eachItem;
                        }
                        // 如果独牌玩家或非独牌时的下家玩家手中只有一张牌，尽量不出单张
                        if ((Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH && (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length == 1) || 
                                (Red5GameStateManager.gameSetting == Red5GameSetting.NO_RUSH && (this._gameBox.cardsOfPlayers[localNextNumber - 1] as Array).length == 1)) {
                            if (minValue.length == 1 && eachItem.length > 1) {
                                minValue = eachItem;
                            }
                        }
//                        // A 2 5 X Y 需要审核后才可以出
//                        if (eachItem[0].toString().match(/[A25XY]/)) {
//                            continue;
//                        }
//                        // 首次发牌或有与上家发牌对应的牌时
//                        prepareCandidatedCards(minValue);
//                        // 开始出牌
//                        if (Application.application.red5GameModule.btnBarPokers.visible) {
//                            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//                            return;
//                        }
                    }
                }
                // 从 A 2 5 X Y 中找到最小值出牌
                prepareCandidatedCards(minValue);
                // 开始出牌
                if (Application.application.red5GameModule.btnBarPokers.visible) {
                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                    return;
                }
            } else {
                // 当前玩家跟牌***规则定义
                // 从默认的备选牌型中提取牌型
                for each (eachCardsStyle in this.tips) {
                    for each (eachItem in eachCardsStyle) {
                        if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                            // 如果当前玩家牌与被跟玩家为友邦且牌值相差较大
                            if (eachItem.join(",").match(/V[5XY]/) && eachItem.join(",").match(/V[5XY]/).length > 0) {
                                if (!isAlliance && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
                                    // 与出牌者敌对，出牌者为独牌玩家
                                } else if (!isAlliance) {
                                    // 与出牌者敌对，各自为战或出牌者非独牌玩家
                                    if (Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
                                        // 独牌玩家
                                    } else {
                                        // 各自为战
                                        if (tipCount(Red5Game.analyzeCandidateCards(this._gameBox.cardsOfPlayers[currentNumber - 1] as Array)) > 3) {
                                            continue;
                                        }
                                    }
                                } else if (isAlliance) {
                                    // 与出牌者友邦关系，且出牌者的牌为二、草五、王中之一
                                    if (boutCards.match(/[25XY]/)) {
                                        continue;
                                    }
                                }
                            }
                            // 首次发牌或有与上家发牌对应的牌时
                            prepareCandidatedCards(eachItem);
                            // 开始出牌
                            if (Application.application.red5GameModule.btnBarPokers.visible) {
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                return;
                            }
                        }
                    }
                }
                // 没默认牌型跟时
                if (!isAlliance && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
                    // 敌对时，有玩家独牌
                    
                    // 拆非顺子牌跟
                    for each (eachCardsStyle in this.tips) {
                        for each (eachItem in eachCardsStyle) {
                            if (Red5Game.isStraightStyle(eachItem.join(",").replace(/(?<!\d)V/g, "4V"))) {
                                continue;
                            } else {
                                myCards += eachItem.join(",") + ",";
                            }
                        }
                    }
                    // 非顺子牌组合
                    myCards = Red5Game.sortPokers(myCards.replace(/^,|,$/g, "")).join(",").replace(/(?<!\d)V/g, "4V");
                    myCardArray = Red5Game.getBrainPowerTip(myCards.replace(/(?<!\d)V/g, "4V").split(","), boutCards.split(","), false);
                    myCardArray = new Array(new Array(myCardArray ? myCardArray : new Array()));
                    if (tipCount(myCardArray) > 0) {
                        for each (eachCardsStyle in myCardArray) {
                            for each (eachItem in eachCardsStyle) {
                                if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                                    // 首次发牌或有与上家发牌对应的牌时
                                    prepareCandidatedCards(eachItem);
                                    // 开始出牌
                                    if (Application.application.red5GameModule.btnBarPokers.visible) {
                                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                        return;
                                    }
                                }
                            }
                        }
                    }
                    // 拆顺子牌跟
                    if (Red5GameStateManager.gameFinalSettingPlayerNumber == localNumber) {
                        // 当前玩家独牌
                        // 出牌者牌不多于5张时
                        if ((this._gameBox.cardsOfPlayers[currentNumber - 1] as Array).length <= 5 && Application.application.red5GameModule.btnBarPokers.visible) {
                            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_HINT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                            return;
                        }
                    } else {
                        // 当前玩家未独牌
                        if (!ableSiege(localNumber, boutCards)) {
                            // 开始出牌
                            if (Application.application.red5GameModule.btnBarPokers.visible) {
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_HINT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                return;
                            }
                        }
                    }
                } else if (!isAlliance) {
                    // 敌对时，各自为战

                    // 拆非顺子牌跟
                    for each (eachCardsStyle in this.tips) {
                        for each (eachItem in eachCardsStyle) {
                            if (Red5Game.isStraightStyle(eachItem.join(",").replace(/(?<!\d)V/g, "4V"))) {
                                continue;
                            } else {
                                myCards += eachItem.join(",") + ",";
                            }
                        }
                    }
                    // 非顺子牌组合
                    myCards = Red5Game.sortPokers(myCards).join(",").replace(/^,|,$/g, "").replace(/(?<!\d)V/g, "4V");
                    myCardArray = Red5Game.getBrainPowerTip(Red5Game.sortPokers(myCards), boutCards.split(","), false);
                    myCardArray = new Array(new Array(myCardArray ? myCardArray : new Array()));
                    if (tipCount(myCardArray) > 0) { // TODO myCardArray may be null value.
                        for each (eachCardsStyle in myCardArray) {
                            for each (eachItem in eachCardsStyle) {
                                if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                                    // 首次发牌或有与上家发牌对应的牌时
                                    prepareCandidatedCards(eachItem);
                                    // 开始出牌
                                    if (Application.application.red5GameModule.btnBarPokers.visible) {
                                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                        return;
                                    }
                                }
                            }
                        }
                    }

                    // 出牌者手中牌数不多于6张，必杀
                    if ((this._gameBox.cardsOfPlayers[currentNumber - 1] as Array).length <= 6) {
                        if (Application.application.red5GameModule.btnBarPokers.visible) {
                            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_HINT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                            return;
                        }
                    }
                }// 非敌对时可以什么都不做
            }

            // 执行不要操作
            if (Application.application.red5GameModule.btnBarPokers.visible) {
			    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            }
		}
        
        /**
         *
         * @param value
         *
         */
        public override function set gameBox(value:*):void {
            this._gameBox = value;
        }

        /**
         * 出牌准备
         * 
         * @param cardArray
         */
        private function prepareCandidatedCards(cardArray:Array):void {
            // 重选
            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_RESELECT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            // 准备出牌
            var i:int = 0;
            for each (var eachPokerButton:PokerButton in Application.application.red5GameModule.candidatedDown.getChildren())
            {
                // 不计花色比较
                if (eachPokerButton.value.replace(/\d/, "") ==  cardArray[i] || eachPokerButton.value ==  cardArray[i]) {
                    eachPokerButton.setSelected(true);
                    i++;
                }
            }
        }

        /**
         * 是否是同盟关系
         */
        private function isAlliance():Boolean {
            if (Red5GameStateManager.gameSetting == Red5GameSetting.NO_RUSH) {
                // 游戏最终设置为不独时，所有玩家彼此均为敌对
                return false;
            }
            // 游戏最终设置为独牌或天独或天外天时
            var isMyRush:Boolean = (Red5GameStateManager.gameFinalSettingPlayerNumber == Red5GameStateManager.localNumber);
            if (isMyRush) {
                // 当前玩家独时，与其它所有玩家敌对
                return false;
            } else {
                if (Red5GameStateManager.gameFinalSettingPlayerNumber == Red5GameStateManager.currentNumber) {
                    // 当前玩家以外的玩家独时，与游戏最终设置的玩家敌对
                    return false
                }
                // 当前玩家以外的玩家独时，与游戏非最终设置的玩家为友邦
                return true;
            }
        }
        
        /**
         * 从当前玩家位置出发，在后续友邦手中的牌中，查看是否有备用牌。
         * 
         * @param localNumber
         * @param currentBout
         * @return 
         */
        private function ableSiege(localNumber:int, currentBout:String):Boolean {
            if (Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH && Red5GameStateManager.gameFinalSettingPlayerNumber == localNumber) {
                // 独牌者
                return false;
            }
            // 从当前位置开始向下家方向流动，从玩家手中找到可用备用牌
            var startIndex:int = localNumber - 1;
            while (true) {
                startIndex++;
                if (startIndex == Red5GameStateManager.playerCogameNumber) {
                    startIndex = 0;
                }
                if (startIndex == localNumber - 1 || startIndex == Red5GameStateManager.gameFinalSettingPlayerNumber - 1) {
                    break;
                }
                // 从下家友邦中查找备用牌
                var tips:Array = Red5Game.getBrainPowerTip(this._gameBox.cardsOfPlayers[startIndex] as Array, currentBout.split(","), false);
                if (tips && tips.length > 0) {
                    return true;
                }
            }
            return false;
        }

        /**
         * 当前剩余牌型个数
         * 
         * @param dummyTips
         * @return 
         */
        private function tipCount(dummyTips:Array = null):int {
            var count:int = 0;
            if (!dummyTips) {
                dummyTips = this.tips;
            }
            for each (var eachItems:Array in dummyTips) {
                count += eachItems.length;
            }
            return count;
        }

        /**
         * 是否为全局最大牌，即无任何玩家可以跟牌
         * 
         * @param boutingCards 要检验的牌
         * @param useRule      按照一定的逻辑规则检验
         */
        private function isInvincible(boutingCards:Array, useRule:Boolean = true):Boolean {
            for (var i:int = 0; i < this._gameBox.cardsOfPlayers.length; i++) {
                if (i + 1 == Red5GameStateManager.localNumber) {
                    // 跳过当前玩家
                    continue;
                }
                if (useRule && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
                    // 有人独牌的情况
                    if (Red5GameStateManager.localNumber == Red5GameStateManager.gameFinalSettingPlayerNumber) {
                        // 当前玩家为独牌者，目标玩家未独牌
                    } else if ((i + 1) == Red5GameStateManager.gameFinalSettingPlayerNumber) {
                        // 当前玩家未独牌，目标玩家独牌
                    } else {
                        // 当前玩家未独牌，目标玩家未独牌
                        continue;
                    }
                }
                var resultArray:Array = Red5Game.getBrainPowerTip(this._gameBox.cardsOfPlayers[i] as Array, boutingCards.join(",").replace(/(?<!\d)V/g, "4V").split(","), false);
                if (resultArray && resultArray.length > 0) {
                    return false;
                }
            }
            return true;
        }

    }
}
