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

            // 当独牌玩家只有一张牌时，尽量不出单牌
            if (Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH && 
                    (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length == 0) {
                for each (eachCardsStyle in this.tips) {
                    for each (eachItem in eachCardsStyle) {
                        if (eachItem.join(",").indexOf(",") > -1) {
                            prepareCandidatedCards(eachItem);
                            // 开始出牌
                            if (Application.application.red5GameModule.btnBarPokers.visible) {
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                return;
                            }
                        }
                    }
                }
                // 从最大的单牌开始出
                (Application.application.red5GameModule.candidatedDown.getChildren()[Application.application.red5GameModule.candidatedDown.getChildren().length - 1] as PokerButton).setSelected(true);
                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                return;
            } // 2010/03/29

            // 按照从小到大
            var minValue:Array = null;
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (minValue == null) {
                        minValue = eachItem;
                    } else if (Red5Game.isRuleFollowed(minValue[0].replace(/(?<!\d)V/g, "4V"), eachItem[0].replace(/(?<!\d)V/g, "4V"))) {
                        // FIXME THIS SECTION SHOULD BE CONSIDERD WELL
//                        // 如果独牌玩家或非独牌时的下家玩家手中只有一张牌，尽量不出单张
//                        if (minValue.length == 1 && eachItem.length > 1) {
//                            if ((Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH && (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length == 1) || 
//                                (Red5GameStateManager.gameSetting == Red5GameSetting.NO_RUSH && (this._gameBox.cardsOfPlayers[Red5GameStateManager.localNextNumber - 1] as Array).length == 1)) {
//                                if (Red5GameStateManager.gameSetting == Red5GameSetting.NO_RUSH) {
//                                    // 各自为战情况下，己方剩余的单牌个数多于一个且均没有下家牌大时，先从最小的牌出
//                                    continue;
//                                }
//                            } else {
//                                continue;
//                            }
//                        }
                        minValue = eachItem;
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

            // 从默认的备选牌型中提取牌型
            var attack:Boolean = false;
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                        // 如果当前玩家牌与被跟玩家已经出的牌值相差较大
                        if (eachItem.join(",").match(/V[5XY]/)) {
                            if (Red5GameStateManager.localNumber == Red5GameStateManager.gameFinalSettingPlayerNumber) {
                                // 当前玩家为独牌玩家
                                if (boutCards.match(/V[25XY]/) || currentTipCount < 5) {
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
                                // 当前玩家为非独牌玩家
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
                        // 2010-03-09 REMOVED BEGIN if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                            // 首次发牌或有与上家发牌对应的牌时
                            prepareCandidatedCards(eachItem);
                            // 开始出牌
                            if (Application.application.red5GameModule.btnBarPokers.visible) {
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                return;
                            }
                        // 2010-03-09 REMOVED END }
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

            // 特殊的【2、5、王】放行情况
            var isPassOK:Boolean = !isBigRush(true, true, myTipCount); // 是否允许【PASS】操作
            if (isPassOK && boutCards.match(/[25XY]/g) && currentTipCount > 1 && Red5GameStateManager.localNumber == getNextNumber(Red5GameStateManager.currentNextNumber) && 
                (Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER || 
                    Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.currentNumber)) {
                // 上家出【2、5、王】，且并未产生二皇上或是上家就是二皇上，且上家手中仍然有多余一套的牌，且己方非“天独/天外天”牌型
                isPassOK = false;
                if (Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.currentNumber) {
                    // 车的情况
                    isPassOK = true;
                } else if (boutCards.split(",").length > 1) {
                    // 非车的情况，且上家出对子或同张
                    isPassOK = true;
                } else if (boutCards.indexOf("V2") == -1) {
                    // 非车的情况，且上家出非【2】的牌
                    isPassOK = true;
                } else if (boutCards.replace(/V2/g, "").length == 1) {
                    // 单张【2】的情况
                }
                // 执行【PASS】操作
                if (isPassOK && Application.application.red5GameModule.btnBarPokers.visible) {
                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                    return;
                }
            }
//            // 车的情况
//            if (boutCards.match(/25XY/) && (this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array).length == 0) {
//                // 开始出牌
//                if (Application.application.red5GameModule.btnBarPokers.visible) {
//                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//                    return;
//                }
//            } // 2010/03/29
//
//            // TODO 回旋打法的优先级高于下面的规则
//            myCardArray = boutCards.match(/[25XY]/g);
//            // 当没有玩家独牌，上家出2、5、王且他手中提示牌型大于【1】或玩家手中没有牌时，尽量放上家走，原因上家很可能出小牌，这样就可以顺牌
//            if (myCardArray && Red5GameStateManager.localNumber == Red5GameStateManager.currentNextNumber && 
//                    (Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER || 
//                     (this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array).length == 0)) {
//                if (boutCards.replace(/V2/g, "").length == 1) {
//                    // 单独出一张【2】的时候
////                    if (boutCards.match(/[25XY]/).length > 1 && Application.application.red5GameModule.candidatedDown.getChildren().join(",").match(/[XY]/) < 2) {
////                        // 上家出对子或同张2、5、王，且当前玩家手中【5】和王总数小于三时
////                    } else if (boutCards.match(/[5XY]/)) {
////                        // 上家出单张5、王时
////                    }
//                } else if (myCardArray && myCardArray.length > 1) {
//                    // 非单张并且
//                }
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
                            // 无人独牌，且当前玩家与出已牌者敌对
                            if (boutCards.match(/[25XY]/) || currentTipCount < 4) {
                                // 敌方出二、五、王或是剩余三种牌型时
                                if (eachItem.join(",") == "1V5,1V5"
                                        && (this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array).join(",").match(/[XY]/)
                                        && (this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array).length > 2) {
                                    continue;
                                }
                                // 当前出牌玩家出二或草五时，另外玩家手中有大小王，且大小王数量在两张或两张以上，并且每个玩家手中牌都多余五张时
                                if (eachItem.join(",").indexOf("1V5")) {
                                    // 当前玩家准备出红五
                                    var xyCount:int = 0;
                                    for (var i:int = 0; i < this._gameBox.cardsOfPlayers.length; i++) {
                                        if (i + 1 == Red5GameStateManager.currentNumber || i + 1 == Red5GameStateManager.localNumber) {
                                            continue;
                                        }
                                        if ((this._gameBox.cardsOfPlayers[i] as Array).join(",").match(/[XY]/g)) {
                                            xyCount += (this._gameBox.cardsOfPlayers[i] as Array).join(",").match(/[XY]/g).length;
                                        }
                                    }
                                    if (xyCount > 1 && Red5GameStateManager.secondPlaceNumber != Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER) {
                                        continue;
                                    }
                                } // 2010/03/29
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
                        // 2010-03-09 REMOVED BEGIN if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
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
                        // 2010-03-09 REMOVED END }
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

            // 当独牌玩家只有一张牌或是多张单牌时，当前玩家手中任意提示牌型均高于独牌玩家最后一张牌时
            var attack:Boolean = false;
            if ((this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length == 1 ||
                (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).join(",").match(/(V\w+),\d\1/)) {
                for each (eachCardsStyle in this.tips) {
                    for each (eachItem in eachCardsStyle) {
                        if (eachItem.join(",").indexOf(",") > -1 || 
                                Red5Game.prioritySequence.indexOf(eachItem.join(",").replace(/\dV/g, "V")) >= 
                                Red5Game.prioritySequence.indexOf((this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array)[0].replace(/\dV/g, "V"))) {
                            attack = true;
                        } else {
                            attack = false;
                            break;
                        }
                    }
                }
            } // 2010/03/29

            // 从默认的备选牌型中提取牌型
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                        if (attack) {
                            // 当前玩家随意提示牌均大于独牌玩家时，可以利用提示牌攻击友邦
                            // 首次发牌或有与上家发牌对应的牌时
                            prepareCandidatedCards(eachItem);
                            // 开始出牌
                            if (Application.application.red5GameModule.btnBarPokers.visible) {
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                return;
                            }
                        } // 2010/03/29

                        if (eachItem.length >= 4) {
                            // 友邦出牌个数四张以上时
                            // TODO 需要加一个限制，如果己方出牌，并且剩余牌为天独或天外天牌时
                            continue;
                        }

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
                            if (!isBigRush(true, true, myTipCount)) {
                                continue;
                            }
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
         * @param boutingCards        要检验的牌
         * @param applySkipFriendRule 启用忽略友邦规则(仅当独牌、天独、天外天时该功能才有效)
         */
        private function isInvincible(boutingCards:Array, applySkipFriendRule:Boolean):Boolean {
            for (var i:int = 0; i < this._gameBox.cardsOfPlayers.length; i++) {
                if (i + 1 == Red5GameStateManager.localNumber) {
                    // 跳过当前玩家
                    continue;
                }
                // TODO complete applySkipFriendRule
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
        
        /**
         * 
         * @param number 目标玩家编号
         * @return 目标玩家的下家编号
         */
        private function getNextNumber(number:int, firstTime:Boolean = true):int {
            // 下家编号通常比上家编号大一，四号玩家除外
            var nextNumber:int = (number == 4) ? 1 : number + 1;
            if (nextNumber == Red5GameStateManager.firstPlaceNumber || nextNumber == Red5GameStateManager.secondPlaceNumber) {
                return getNextNumber(nextNumber);
            }
            return nextNumber;
        }

        /**
         * 
         * @return 
         */
        private function isWeakBigRush():Boolean {
            // 找出大牌与其呼应的任意小牌牌型，形成对儿
            return false;
        }

        /**
         * 
         * 统计出所有的无敌大牌与小牌，让大牌与小牌配对
         * 
         * @param dummyTips 所有提示牌型
         * @return 当没有可用的迂回策略时，返回null，否则返回迂回策略结果
         */
        private function testRoundabout(dummyTips:Array):Object {
            if (false) {
                // TODO 只剩下一个对手时
            }
            // 整理提示牌型
            var xxx:Object = {
                invincible: new Array(),
                vincible: new Array(),
                invincibleSeq: new Array(),
                vincibleSeq: new Array(),
                maxLengthVincible: null // 牌数最多的非顺子牌型
            };
            for each (var eachTips:Array in dummyTips) {
                for each (var tipCards:Array in eachTips) {
                    if (isInvincible(tipCards, false)) {
                        // 无敌大牌
                        if (Red5Game.isStraightStyle(tipCards.join(","))) {
                            (xxx.invincibleSeq as Array).push(tipCards);
                        } else {
                            (xxx.invincible as Array).push(tipCards);
                        }
                    } else {
                        // 非无敌大牌
                        if (Red5Game.isStraightStyle(tipCards.join(","))) {
                            (xxx.vincibleSeq as Array).push(tipCards);
                        } else {
                            (xxx.vincible as Array).push(tipCards);
                            // 设置牌数最多的非顺子牌型
                            if (xxx.maxLengthVincible) {
                                xxx.maxLengthVincible = xxx.maxLengthVincible.length < tipCards.length ? tipCards : xxx.maxLengthVincible;
                            } else {
                                xxx.maxLengthVincible = tipCards;
                            }
                        }
                    }
                }
            }
            if (xxx.vincibleSeq.length > 1) {
                return null;
            } else if (xxx.vincibleSeq.length == 1) {
                // 存在一种顺子非无敌大牌
                if (xxx.invincible.length < xxx.vincible.length) {
                    return null;
                }
            } else {
                //
                if (xxx.invincible.length < xxx.vincible.length - xxx.maxLengthVincible.length) {
                    return null;
                }
            }
            // 组合迂回对儿，即相同牌型的一个非无敌大牌对应一个无敌大牌
            // 
            var invincibleCards:Object = {}; // 全局最大牌，可能是单张也可能是同张，如果是同张，需要标明是否可以拆分
            return invincibleCards;
        }

        /**
         * 
         * @param xxx
         * @return 
         * 
         */
        private function testMatch(xxx:Object):Object {
            // 将对子及同张的无敌大牌继续拆分成多个张数更少的牌型
            var tempArray:Array = [];
            for each (var eachInvicible:Array in (xxx.invicible as Array)) {
                if (/^V(10|[JQKA])$/.test(eachInvicible[0]) || eachInvicible.length == 1) {
                    // 
                    tempArray.push(eachInvicible);
                    continue;
                }
                // 开始拆分
                if ("1V5,1V5" == eachInvicible.toString()) {
                    // 对红五
                } else if ("0VX,0VX,0VY,0VY".indexOf(eachInvicible.toString()) > -1) {
                    // 对大王或对小王
                } else if (eachInvicible[0].toString().indexOf("V5") > -1) {
                    // 草五
                } else {
                    // 2
                    
                }
            }
            return null;
        }
    }
}
