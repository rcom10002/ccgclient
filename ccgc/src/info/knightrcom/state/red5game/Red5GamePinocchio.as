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
            var gameSetting:int = 0;
            var myTipCount:int = this.tipCount();
            // 独牌判断
            var isRush:Function = function():Boolean {
                var cards:Array = null;
                // 必须要有红五
                cards = Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/1V5/);
                if (!cards) {
                    return false;
                }
                // 草五、王和红五的合计张数
                cards = Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/[5XY]/g);
                if (cards && cards.length >= 8) {
                    return true;
                } else if (cards && cards.length >= 5) {
                    // 是否有同张数量不小于五的牌型，或是有一个顺子牌型
                    for each (var cardStyle:Array in tips) {
                        for each (cards in cardStyle) {
                            if (Red5Game.isStraightStyle(cards.join(",").toString())) {
                                return true;
                            } else if (Red5Game.isSeveralFoldStyle(cards.join(",")) && Red5Game.getMultiple(cards.join(",")) >= 5) {
                                return true;
                            }
                        }
                    }
                    // 含有三个以上二的情况
                    cards = Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/V2/g);
                    if (cards && cards.length > 3) {
                        return true;
                    }
                }
                // 大小王总数至少要等于二
                cards = Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/[XY]/g);
                if (cards && cards.length >= 2 && (2 < myTipCount && myTipCount <= 5)) {
                    return true;
                } else {
                    if (2 < myTipCount && myTipCount <= 4) {
                        return true;
                    }
                }
                return false;
            };
            if (isBigRush(false, true, myTipCount)) {
                // 天外天
                gameSetting = 3;
            } else if (isBigRush(true, false, myTipCount)) {
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
				if (eachButton.label == btnLabel && (event.tag as PlatformAlertUI).visible) {
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
            // 本地变量
			var boutCards:String = Red5GameStateManager.currentBoutCards;
			if (!(Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP) as Button).enabled) {
				boutCards = null;
			}
            var eachCardsStyle:Array, eachItem:Array = null;
            var isAlliance:Boolean = isAlliance();
            var myTipCount:int = tipCount();

            // 重选备用牌
            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_RESELECT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));

            if (!boutCards) {
                // 当前玩家出牌***规则定义
                processDiscard(myTipCount);
            } else {
                // 当前玩家跟牌***规则定义

                // 计算发牌者手中牌型套数
                var currentTipCount:int = tipCount(Red5Game.analyzeCandidateCards(this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array));

                // 没默认牌型跟时
                if (!isAlliance && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
                    // 敌对时，有玩家独牌
                    processHostileRushFollow(boutCards, currentTipCount);
                } else if (!isAlliance) {
                    // 敌对时，各自为战
                    processHostileNoRushFollow(boutCards, myTipCount, currentTipCount);
                } else {
                    // 同盟时，即有玩家独牌且已出牌者与当前玩家为友邦关系
                    processAlliedRushFollow(boutCards, myTipCount, currentTipCount);
                }
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
         * 出牌处理 TODO 分解敌对与同盟的处理
         * 
         * @param myTipCount
         */
        private function processDiscard(myTipCount:int):void {
            var eachCardsStyle:Array, eachItem:Array = null;

            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (isBigRush(true, true, myTipCount) || 
                            Red5GameStateManager.gameSetting == Red5GameSetting.DEADLY_RUSH || 
                            Red5GameStateManager.gameSetting == Red5GameSetting.EXTINCT_RUSH) {
                        // 天外天或天独时
                        if (isInvincible(eachItem, false)) {
                            // 首次发牌或有与上家发牌对应的牌时
                            prepareCandidatedCards(eachItem);
                            // 开始出牌
                            if (Application.application.red5GameModule.btnBarPokers.visible) {
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                return;
                            }
                        }
                    }
                    if (myTipCount <= 4 && Red5Game.isStraightStyle(eachItem.join(",").replace(/(?<!\\d)V/g, "4V"))) {
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
            // 按照从小到大
            var minValue:Array = null;
            // ******************************************* 考虑独牌
//            , singleTips:Array = null;
//            singleTips = [];
//            if (Red5GameStateManager.gameSetting == Red5GameSetting.NO_RUSH && 
//                    (this._gameBox.cardsOfPlayers[Red5GameStateManager.localNextNumber - 1] as Array).length == 1) {
//                for each (eachCardsStyle in this.tips) {
//                    for each (eachItem in eachCardsStyle) {
//                        var eachTip:Array = eachItem.join(",").match(/\d?V[\dXY]+/g);
//                        if (eachTip && eachTip.length == 1) {
//                            singleTips.push(eachTip[0]);
//                        }
//                    }
//                }
//                Red5Game.getBrainPowerTip(singleTips, this._gameBox.cardsOfPlayers[localNextNumber - 1], false);
//            }
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (minValue == null) {
                        minValue = eachItem;
                    } else if (Red5Game.isRuleFollowed(minValue[0].replace(/(?<!\d)V/g, "4V"), eachItem[0].replace(/(?<!\d)V/g, "4V"))) {
                        minValue = eachItem;
                    }
                    // 如果独牌玩家或非独牌时的下家玩家手中只有一张牌，尽量不出单张
                    if ((Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH && (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length == 1) || 
                        (Red5GameStateManager.gameSetting == Red5GameSetting.NO_RUSH && (this._gameBox.cardsOfPlayers[Red5GameStateManager.localNextNumber - 1] as Array).length == 1)) {
                        if (minValue.length == 1 && eachItem.length > 1) {
                            if (Red5GameStateManager.gameSetting == Red5GameSetting.NO_RUSH) {
                                // 各自为战情况下，己方剩余的单牌个数多于一个且均没有下家牌大时，先从最小的牌出
                                continue;
                            }
                            minValue = eachItem;
                        }
                    }
                }
            }
            // 从 A 2 5 X Y 中找到最小值出牌
            prepareCandidatedCards(minValue);
            // 开始出牌
            if (Application.application.red5GameModule.btnBarPokers.visible) {
                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                return;
            }
        }
        
        /**
         * 敌对状态且有玩家独牌时跟牌处理(包括独牌玩家与非独牌玩家的处理方案)
         * 
         * @param boutCards
         * @param currentTipCount
         */
        private function processHostileRushFollow(boutCards:String, currentTipCount:int):void {
            var eachCardsStyle:Array, eachItem:Array, myCardArray:Array = null;
            var myCards:String = "";
            var isAlliance:Boolean = false;

            var attack:Boolean = false;
            // 从默认的备选牌型中提取牌型
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                        // 如果当前玩家牌与被跟玩家已经出的牌值相差较大
                        if (eachItem.join(",").match(/V[5XY]/)) {
                            if (Red5GameStateManager.localNumber == Red5GameStateManager.gameFinalSettingPlayerNumber) {
                                // 当前玩家为独牌玩家
                                if (boutCards.match(/V[25XY]/)) {
                                    attack = true;
                                }
                                // 任何一个非独牌玩家牌少于10张
                                for (var i:int = 0; i < this._gameBox.cardsOfPlayers.length; i++) {
                                    if ((this._gameBox.cardsOfPlayers[i] as Array).length < 10) {
                                        attack = true;
                                        break;
                                    }
                                }
                            } else {
                                // 当前玩家为独牌玩家
                                if (boutCards.match(/V[25XY]/) || (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length < 10) {
                                    attack = true;
                                }
                            }
                        }
                        if (attack) {
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
            myCards = Red5Game.sortPokers(myCards.replace(/^,|,$/g, "")).join(",").replace(/(?<!\d)V/g, "4V");
            myCardArray = Red5Game.getBrainPowerTip(myCards.replace(/(?<!\d)V/g, "4V").split(","), boutCards.split(","), false);
            myCardArray = new Array(new Array(myCardArray ? myCardArray : [])); // 非顺子牌组合
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
            if (Red5GameStateManager.gameFinalSettingPlayerNumber == Red5GameStateManager.localNumber) {
                // 当前玩家独牌
                // 出牌者的剩余牌型少于四套时
                if (currentTipCount < 4 && Application.application.red5GameModule.btnBarPokers.visible) {
                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_HINT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                    return;
                }
            } else {
                // 当前玩家未独牌
                if (!ableSiege(Red5GameStateManager.localNumber, boutCards)) {
                    // 开始出牌
                    if (Application.application.red5GameModule.btnBarPokers.visible) {
                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_HINT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                        return;
                    }
                }
            }
        }
        
        /**
         * 处理敌对时的各自为战跟牌操作
         * 
         * @param boutCards
         * @param myTipCount
         * @param currentTipCount
         */
        private function processHostileNoRushFollow(boutCards:String, myTipCount:int, currentTipCount:int):void {
            var eachCardsStyle:Array, eachItem:Array, myCardArray:Array = null;
            var myCards:String = "";
            var isAlliance:Boolean = false;

            // 从默认的备选牌型中提取牌型
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                        // 如果当前玩家牌与被跟玩家为友邦且牌值相差较大
                        if (eachItem.join(",").match(/V[5XY]/)) {
//                            if (!isAlliance && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
//                                // 有人独牌，且出牌者与已出牌玩家敌对
//                            } else if (!isAlliance) {
                                // 无人独牌，且当前玩家与出已牌者敌对
                                if (boutCards.match(/[25XY]/) || currentTipCount < 4) {
                                    // 敌方出二、五、王或是剩余三种牌型时
                                    if ((this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).join(",").match(/[XY]/)
                                            && (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length > 2
                                            && eachItem.join(",") == "1V5,1V5") {
                                        continue;
                                    }
                                } else {
                                    continue;
                                }
//                            } else if (isAlliance && boutCards.match(/V[25XY]/)) {
//                                // 与出牌者友邦关系，且出牌者的牌为二、草五、王中之一
//                                continue;
//                            }
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
            myCardArray = new Array(new Array(myCardArray ? myCardArray : []));
            if (tipCount(myCardArray) > 0) { // TODO myCardArray may be null value.
                for each (eachCardsStyle in myCardArray) {
                    for each (eachItem in eachCardsStyle) {
                        if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                            if (!boutCards.match(/V[25XY]/) && eachItem.join(",").match(/[5XY]/)) {
                                // 敌方未出二、草五、王、红五，但我方需出草五、王、红五时，需要审核
                                if (myTipCount > 4 && currentTipCount > 4) {
                                    continue;
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
            }
            
            // 出牌者手中牌型少于四套，必杀
            if (currentTipCount < 4 && Application.application.red5GameModule.btnBarPokers.visible) {
                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_HINT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                return;
            }
        }

        /**
         * 处理同盟时的跟牌处理
         * 
         * @param boutCards
         * @param currentTipCount
         */
        private function processAlliedRushFollow(boutCards:String, myTipCount:int, currentTipCount:int):void {
            var eachCardsStyle:Array, eachItem:Array = null;
            
            // ******************************************* 考虑独牌
//            var bigRush:Boolean = isBigRush(true, true, myTipCount);
//
//            // 友邦已经出的牌比独牌者备用牌大
//            eachItem = Red5Game.getBrainPowerTip(this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array, 
//                this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array, false);
//            if (!bigRush && eachItem && eachItem.length > 0) {
//                return;
//            }
            
            // 从默认的备选牌型中提取牌型
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                        // 如果当前玩家牌与被跟玩家为友邦且牌值相差较大
                        if (eachItem.join(",").match(/V[5XY]/)) {
//                            if (!isAlliance && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
//                                // 有人独牌，且出牌者与已出牌玩家敌对
//                            } else if (!isAlliance) {
//                                // 无人独牌，且当前玩家与出已牌者敌对
//                                if (boutCards.match(/[25XY]/) || currentTipCount < 4) {
//                                    // 敌方出二、五、王或是剩余三种牌型时
//                                } else {
//                                    continue;
//                                }
//                            } else if (isAlliance && boutCards.match(/V[25XY]/)) {
//                                // 与出牌者友邦关系，且出牌者的牌为二、草五、王中之一
//                                continue;
//                            }
                            if (boutCards.match(/V[25XY]/)) {
                                // 与出牌者友邦关系，且出牌者的牌为二、草五、王中之一
                                continue;
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
         * @param boutingCards    要检验的牌
         * @param applyFriendRule 启用忽略友邦规则
         */
        private function isInvincible(boutingCards:Array, applySkipFriendRule:Boolean):Boolean {
            for (var i:int = 0; i < this._gameBox.cardsOfPlayers.length; i++) {
                if (i + 1 == Red5GameStateManager.localNumber) {
                    // 跳过当前玩家
                    continue;
                }
                if (applySkipFriendRule && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
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

        /**
         * 天独或天外天判断，或者是类似于天独天外天的牌
         *  
         * @param forDeadly  执行天独判断逻辑
         * @param forExtinct 执行天外天判断逻辑
         * @param myTipCount 当前手中牌型套数
         * @return 
         */
        private function isBigRush(forDeadly:Boolean, forExtinct:Boolean, myTipCount:int):Boolean {
            var invicibleCount:int = 0;
            for each (var eachCardsStyle:Array in tips) {
                for each (var eachItem:Array in eachCardsStyle) {
                    if (isInvincible(eachItem, false)) {
                        invicibleCount++;
                    }
                }
            }
            if (forDeadly && (invicibleCount + 1) == myTipCount) {
                return true;
            } else if (forExtinct && invicibleCount == myTipCount) {
                return true;
            }
            return false;
        }
    }
}
