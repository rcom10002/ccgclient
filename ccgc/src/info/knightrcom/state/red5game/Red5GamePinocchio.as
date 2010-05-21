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
	 *　　万里长城十亿兵,<br/>
     *　　国耻岂待儿孙平;<br/>
     *　　愿提十万虎狼旅,<br/>
     *　　越马扬刀入东京.<br/>
     *　　大江南北十亿兵,<br/>
     *　　国仇就在今生平.<br/>
     *　　中华傲立世界日, <br/>
     *　　铁甲十万灭东瀛.
	 */
    public dynamic class Red5GamePinocchio extends GamePinocchio {

        private var _gameBox:Red5GameBox = null;

        private var roundabout:Object = null;

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
                roundabout = testRoundabout(tips, myTipCount);
                if (roundabout) {
                    return true;
                }
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

            // 2010-04-27 ADDED [摆渡牌判断与出牌] BEGIN 
            if (Red5GameStateManager.gameSetting != Red5GameSetting.DEADLY_RUSH && Red5GameStateManager.gameSetting != Red5GameSetting.EXTINCT_RUSH && this.roundabout) {
                // 按照【roundabout】方式出牌或跟牌
                if (processRoundaboutDiscard(boutCards)) {
                    return;
                }
            }
            // 2010-04-27 ADDED [摆渡牌判断与出牌] END

            if (!boutCards) {
                // 当前玩家出牌***规则定义
                // 2010-04-27 ADDED [摆渡牌判断与出牌] BEGIN 
                if (Red5GameStateManager.gameSetting != Red5GameSetting.DEADLY_RUSH && Red5GameStateManager.gameSetting != Red5GameSetting.EXTINCT_RUSH && !this.roundabout) {
                    // 进行【roundabout】测试
                    this.roundabout = testRoundabout(this.tips, myTipCount);
                    if (this.roundabout) {
                        // 按照【roundabout】方式出牌或跟牌
                        if (processRoundaboutDiscard(boutCards)) {
                            return;
                        }
                    }
                }
                // 2010-04-27 ADDED [摆渡牌判断与出牌] END
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
         * 处理摆渡牌
         * 
         *  roundabout = {
         *      invincible: [],
         *      vincible: [],
         *      invincibleSeq: [],
         *      vincibleSeq: [],
         *      maxLengthVincible: [], // 牌数最多的非顺子牌型
         *      discardOrder: null,    // 最终的摆渡提示方案，可能为null
         *      currentStep: 0
         *  };
         * 
         * @param boutCards
         * 
         */
        private function processRoundaboutDiscard(boutCards:String):Boolean {
            if (Red5GameStateManager.gameSetting == Red5GameSetting.DEADLY_RUSH || 
                Red5GameStateManager.gameSetting == Red5GameSetting.EXTINCT_RUSH) {
                // 天独或天外天时，不做摆渡处理
                return false;
            } else if ((this.roundabout.discardCards as Array).length == this.roundabout.discardIndex) {
                return false;
            }
            // 首次发牌或有与上家发牌对应的牌时
            if (!Red5Game.isRuleFollowed(this.roundabout.discardCards[this.roundabout.discardIndex].toString(), boutCards)) {
                this.roundabout = null;
                return false;
            }
            prepareCandidatedCards(roundabout.discardCards[roundabout.discardIndex]);
            // 开始出牌
            if (Application.application.red5GameModule.btnBarPokers.visible) {
                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                this.roundabout.discardIndex++;
                return true;
            }
            this.roundabout = null;
            return false;
        }

        /**
         * 出牌处理分解敌对与同盟的处理
         * 
         * @param myTipCount
         */
        private function processDiscard(myTipCount:int):void {
            var eachCardsStyle:Array, eachItem:Array = null;

            // 处理天独、天外天牌型
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
                        // 当只剩下一个对手时 如何拆分成多个倍数牌来避免出单牌
                        // 2010-05-14
                        if (Red5GameStateManager.gameSetting == Red5GameSetting.NO_RUSH &&
                            Red5GameStateManager.secondPlaceNumber != Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER) {
                            if (!(this._gameBox.cardsOfPlayers[Red5GameStateManager.localNextNumber - 1] as Array).toString().replace(/1V5/g, "").match(/\d(V\w+),\d\1/)) {
                                // 对手牌全是单张时
                                // TODO FIXME
                                // 将所有牌都拆分成倍数牌
                                // 如果当前要打出的牌是一个五连顺，抛弃首牌或尾牌来组合另外一组倍数牌
                            }
                        }
                        // 2010-05-14
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

//            // 当独牌玩家只有一张牌时，尽量不出单牌
//            if (Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH && 
//                    (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length == 0) {
//                for each (eachCardsStyle in this.tips) {
//                    for each (eachItem in eachCardsStyle) {
//                        if (eachItem.join(",").indexOf(",") > -1) {
//                            prepareCandidatedCards(eachItem);
//                            // 开始出牌
//                            if (Application.application.red5GameModule.btnBarPokers.visible) {
//                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//                                return;
//                            }
//                        }
//                    }
//                }
//                // 从最大的单牌开始出
//                (Application.application.red5GameModule.candidatedDown.getChildren()[Application.application.red5GameModule.candidatedDown.getChildren().length - 1] as PokerButton).setSelected(true);
//                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//                return;
//            }

            // 统计全局最少牌
            var minLength:int = 0;
            if (Red5GameStateManager.gameFinalSettingPlayerNumber == Red5GameSetting.NO_RUSH /* &&
                    Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER */) {
                // 当没人独牌并且剩余多于两个玩家时，统计剩余牌数最少的玩家手中的牌数
                for (var i:int = 0; i < Red5GameStateManager.playerCogameNumber; i++) {
                    if ((this._gameBox.cardsOfPlayers[i] as Array).length == 0 || Red5GameStateManager.localNumber == i + 1) {
                        // 跳过当前玩家和手中无牌的玩家
                        continue;
                    }
                    if (minLength == 0 || minLength > (this._gameBox.cardsOfPlayers[i] as Array).length) {
                        minLength = (this._gameBox.cardsOfPlayers[i] as Array).length;
                    }
                }
            } else if (Red5GameStateManager.gameFinalSettingPlayerNumber != Red5GameSetting.NO_RUSH) {
                // 有人独牌
                minLength = (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length;
            }
            minLength = minLength > 3 ? 0 : minLength;

            // 按照从小到大的顺序出牌，但是需要考虑其他玩家手中的牌数，查找可以使用的最小牌
            var minValue:Array = null;   // 当前玩家手中物理最小牌
            var logicValue:Array = null; // 当前玩家手中可以利用的逻辑最小牌
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    // ===> 初始赋值
                    if (minValue == null) {
                        minValue = eachItem;
                        logicValue = eachItem;
                        continue;
                    }
                    
                    // ===> 物理最小值
                    var isSmallerFound:Boolean = Red5Game.isRuleFollowed(logicValue[0].replace(/(?<!\d)V/g, "4V"), eachItem[0].replace(/(?<!\d)V/g, "4V"));
                    if (isSmallerFound) {
                        minValue = eachItem;
                    }

                    // ===> 均多于【3】张牌 
                    if (isSmallerFound && minLength == 0) {
                        // 这里只需要考虑牌大小，不用考虑其他玩家手中牌数，因为其他每位玩家手中牌数必大于【3】张
                        logicValue = eachItem;
                        continue;
                    }

                    // ===> 存在小于【3】张牌
                    if (minLength != 0) {
                        // 存在手中的牌数在【3】张以内的玩家
                        if (Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
                            // 独牌时
                            if (eachItem.length != minLength) {
                                if (logicValue.length == minLength) {
                                    logicValue = eachItem;
                                } else if (isSmallerFound) {
                                    logicValue = eachItem;
                                }
                            }
                        } else {
                            // 非独牌时
                            if (Red5GameStateManager.firstPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER ||
                                Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER) {
                                // 剩余三个或四个玩家
                                if (eachItem.length != minLength && eachItem.toString().match(/10|[JQKA]/)) {
                                    if (logicValue.length == minLength) {
                                        logicValue = eachItem;
                                    } else if (isSmallerFound) {
                                        logicValue = eachItem;
                                    }
                                }
                            } else {
                                // 剩余两个玩家
                                if (eachItem.length != minLength) {
                                    if (logicValue.length == minLength) {
                                        logicValue = eachItem;
                                    } else if (isSmallerFound) {
                                        logicValue = eachItem;
                                    }
                                }
                            }
                        }
                    }
                }
            }

//            // 矫正逻辑可用最小值
//            if (minLength == 0) {
//                // 每人手中都超过【3】张牌
//                logicValue = minValue;
//            } else {
//                // 存在手中不超过【3】张牌的玩家
//                if (Red5GameStateManager.firstPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER ||
//                    Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER) {
//                    if (logicValue.length == minLength || logicValue.toString().match(/10|[JQKA]/g).length == -1) {
//                        logicValue = minValue;
//                    }
//                } if (logicValue.length == minLength) {
//                    // 当前玩家手中不存在合适的牌型时，准备拆牌
//                    if (Red5GameStateManager.secondPlaceNumber != Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER ||
//                        Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
//                        // 从右侧最大的牌开始出
//                    } else {
//                        logicValue = minValue;
//                    }
//                }
//            }

            // 从 A 2 5 X Y 中找到最小值出牌
            prepareCandidatedCards(logicValue);
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
                                if (boutCards.match(/V[25XY]/) || currentTipCount < 3) {
                                    attack = true;
                                }
                                // 任何一个非独牌玩家牌少于【8】张
                                for (var i:int = 0; i < this._gameBox.cardsOfPlayers.length; i++) {
                                    if ((this._gameBox.cardsOfPlayers[i] as Array).length < 8) {
                                        attack = true;
                                        break;
                                    }
                                }
                            } else {
                                // 当前玩家为非独牌玩家
                                if (boutCards.match(/V[25XY]/) || (this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array).length < 9) {
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
            myCardArray = [[myCardArray ? myCardArray : []]]; // 非顺子牌组合
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
            
            // FIXME 如果启用此功能，要保证出牌前后的提示牌型的数量保持不变
            //            // 顺子牌可以拆牌跟
            //            if (Red5Game.isStraightStyle(boutCards)) {
            //                // 开始出牌
            //                if (Application.application.red5GameModule.btnBarPokers.visible) {
            //                    // 重选
            //                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_RESELECT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            //                    // 提示
            //                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_HINT).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            //                    // 发牌
            //                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            //                }
            //                if (!Application.application.red5GameModule.btnBarPokers.visible) {
            //                    return;
            //                }
            //            }

            // 当有人出【2、5、王】时，可以根据实际情况来采取放行
            // 当前玩家不能
            var isPassOK:Boolean = !isBigRush(true, true, myTipCount); // 是否允许【PASS】操作
            if (!isPassOK) {
                // 手中是天独或天外天牌型时，从备用牌型中选出无敌大牌打出
                for each (eachCardsStyle in this.tips) {
                    for each (eachItem in eachCardsStyle) {
                        if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards) &&
                                isInvincible(eachItem, false)) {
                            // 甩出无敌大牌从而获取发牌权
                            prepareCandidatedCards(eachItem);
                            // 开始出牌
                            if (Application.application.red5GameModule.btnBarPokers.visible) {
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                return;
                            }
                        }
                    }
                }
            } else if (isPassOK && boutCards.match(/V[25XY]/) && (Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.currentNumber ||
                Red5GameStateManager.firstPlaceNumber == Red5GameStateManager.currentNumber ||
                (Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER && currentTipCount > 2))) {
                // 当前玩家牌型不是天独或天外天，出牌者为直接上家，上家出【2、5、王】，且并未产生二皇上或是上家就是二皇上，且上家手中仍然有多余一套的牌
                isPassOK = false;
                if (boutCards.replace(/V2/g, "").length == 1) {
                    // 单张【2】的情况
                    isPassOK = false;
                } else if (Red5GameStateManager.localNumber == getNextNumber(Red5GameStateManager.currentNumber)) {
                    // 上家出牌时
                    isPassOK = true;
                } else if (Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.currentNumber ||
                        Red5GameStateManager.firstPlaceNumber == Red5GameStateManager.currentNumber) {
                    // 车的情况
                    isPassOK = true;
                }
                // 执行【PASS】操作
                if (isPassOK && Application.application.red5GameModule.btnBarPokers.visible) {
                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                    return;
                }
            }

            // 从默认的备选牌型中提取牌型
            var invincibleAndVincible:Array = fetchInvicibleAndVincible(this.tips);
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                        // 如果当前玩家牌与被跟玩家为友邦且牌值相差较大
                        if (eachItem.join(",").match(/V[5XY]/) && (invincibleAndVincible[1] as Array).length > 1) {
                            // 无人独牌，且当前玩家与出已牌者敌对
                            if (boutCards.match(/V[25XY]/) || currentTipCount < 3) {
                                // 敌方出二、五、王或是剩余不到三种牌型时
                                if (eachItem.join(",") == "1V5,1V5"
                                        && (this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array).join(",").match(/[XY]/)
                                        && (this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array).length > 2) {
                                    // 当前玩家需出对红五，且出牌玩家手中牌大于两张时，执行【PASS】操作
                                    if (isPassOK && Application.application.red5GameModule.btnBarPokers.visible) {
                                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                        return;
                                    }
                                }
                                // 当前出牌玩家出二或草五时，另外玩家手中有大小王，且大小王数量在两张或两张以上，并且每个玩家手中牌都多余五张时
                                if (Red5GameStateManager.secondPlaceNumber != Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER && eachItem.toString() == "1V5") {
                                    // 当前玩家准备出红五，但外面仍然剩余多余一张的大小王
                                    if ((this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array).toString().match(/[XY]/g).length > 1) {
                                        // 执行【PASS】操作
                                        if (isPassOK && Application.application.red5GameModule.btnBarPokers.visible) {
                                            Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                            return;
                                        }
                                    }
                                }
                                if (eachItem.join(",").match(/[XY]/)) {
                                    // 当前玩家准备出大小王
                                    var allXY5Count:int = this._gameBox.cardsOfPlayers.toString().match(/[XY]|1V5/g).length; // 总红五、大小王个数
                                    var myXY5Count:int = this.tips.toString().match(/[XY]|1V5/g).length; // 当前玩家手中总红五、大小王个数
                                    var currentXY5Count:int = (this._gameBox.cardsOfPlayers[Red5GameStateManager.currentNumber - 1] as Array).toString().match(/[XY]|1V5/g).length; // 出牌玩家手中总红五、大小王个数
                                    if (Red5GameStateManager.firstPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER) {
                                        if (myXY5Count == 1 && allXY5Count - myXY5Count > 3) {
                                            // 执行【PASS】操作
                                            if (isPassOK && Application.application.red5GameModule.btnBarPokers.visible) {
                                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                                return;
                                            }
                                        }
                                    }
                                    // 已经产生大皇上但未产生二皇上时
                                    if (Red5GameStateManager.firstPlaceNumber != Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER &&
                                        Red5GameStateManager.secondPlaceNumber == Red5GameStateManager.UNOCCUPIED_PLACE_NUMBER &&
                                        eachItem.join(",").match(/[XY]/) && currentTipCount < 4) {
                                        if (myXY5Count < allXY5Count - myXY5Count - currentXY5Count) {
                                            // 执行【PASS】操作
                                            if (isPassOK && Application.application.red5GameModule.btnBarPokers.visible) {
                                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                                return;
                                            }
                                        }
                                    }
                                }
                            } else {
                                // 处理对付【2】以下的牌
                                myCardArray = this._gameBox.cardsOfPlayers[Red5GameStateManager.localNumber - 1];
                                if (myCardArray.length == myCardArray.toString().match(/[5XY]/g).length ||
                                    myCardArray.toString().match(/[5XY]/g).length >= 2) {
                                    // 剩余的牌全是【5】、大小王，或者剩余不少于【2】张的【5】、大小王时
                                    prepareCandidatedCards(eachItem);
                                    // 开始出牌
                                    if (Application.application.red5GameModule.btnBarPokers.visible) {
                                        Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                        return;
                                    }
                                }
                                // 执行【PASS】操作
                                if (isPassOK && Application.application.red5GameModule.btnBarPokers.visible) {
                                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                    return;
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
            // 如果当前所有玩家牌数大于45张(总牌数有60张)，且当前玩家手中的牌型数大于3，那就不做拆牌处理
            if (this._gameBox.cardsOfPlayers.toString().split(",").length > 45 && currentTipCount > 3) {
                // 执行【PASS】操作
                if (isPassOK && Application.application.red5GameModule.btnBarPokers.visible) {
                    Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                    return;
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
            myCardArray = [[myCardArray ? myCardArray : []]];
            if (tipCount(myCardArray) > 0) {
                for each (eachCardsStyle in myCardArray) {
                    for each (eachItem in eachCardsStyle) {
                        if (!boutCards.match(/V[25XY]/) && eachItem.join(",").match(/V[5XY]/)) {
                            // 敌方未出二、草五、王、红五，但我方需出草五、王、红五时，需要审核
                            if (myTipCount >= 4 && currentTipCount >= 4) {
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

            // 当前玩家手中任意提示牌型均高于独牌玩家的提示牌型时
            var deadlyAttack:Boolean = false;
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    eachItem = Red5Game.getBrainPowerTip(this._gameBox.cardsOfPlayers[Red5GameStateManager.gameFinalSettingPlayerNumber - 1] as Array, 
                        eachItem.toString().replace(/(?<!\d)V/g, "4V").split(","), false);
                    if (eachItem && eachItem.length > 1) {
                        deadlyAttack = true;
                    } else {
                        deadlyAttack = false;
                        break;
                    }
                }
            }
            if (!deadlyAttack) {
                // TODO FIXME 提供回旋打的机会
            }

            // 从默认的备选牌型中提取牌型
            for each (eachCardsStyle in this.tips) {
                for each (eachItem in eachCardsStyle) {
                    if (Red5Game.isRuleFollowed(eachItem.join(",").replace(/(?<!\d)V/g, "4V"), boutCards)) {
                        if (deadlyAttack) {
                            // 当前玩家随意提示牌均大于独牌玩家时，可以利用提示牌攻击友邦
                            // 首次发牌或有与上家发牌对应的牌时
                            prepareCandidatedCards(eachItem);
                            // 开始出牌
                            if (Application.application.red5GameModule.btnBarPokers.visible) {
                                Application.application.red5GameModule.btnBarPokers.getChildAt(Red5Game.OPTR_DISCARD).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                                return;
                            }
                        } // 2010/03/29

                        if (eachItem.length >= 4 && !isBigRush(true, true, myTipCount)) {
                            // 友邦出牌个数四张以上时
                            // TODO 需要加一个限制，如果己方出牌，并且剩余牌为天独或天外天牌时
                            continue;
                        }

                        // 如果当前玩家牌与被跟玩家为友邦且牌值相差较大
                        if (eachItem.join(",").match(/[^1]V[5XY]/)) {
                            if (!isBigRush(true, true, myTipCount) && boutCards.match(/10|[JQKA]/g).length >= 3) {
                                // 不能构成天独或天外天，且友邦牌为三同张或更多同张的【10-A】牌
                                continue;
                            }
                            if (boutCards.match(/V[5XY]/) || boutCards.match(/V2/g).length > 1) {
                                // 与出牌者友邦关系，且出牌者的牌为草五、王中之一，或是两张以上的【2】
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
                // 启用友邦跳过，即假定友邦不会阻止当前玩家
                if (applySkipFriendRule && Red5GameStateManager.gameSetting != Red5GameSetting.NO_RUSH) {
                    // 有人独牌的情况
                    if (i + 1 != Red5GameStateManager.gameFinalSettingPlayerNumber) {
                        // 此次遍历到的玩家非独牌玩家
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
        private function getNextNumber(number:int):int {
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
         * @param dummyTips
         * @return 位置【0】的是无敌大牌，位置【1】是小牌
         * 
         */
        private function fetchInvicibleAndVincible(dummyTips:Array):Array {
            var invincibleParts:Array = [];
            var vincibleParts:Array = [];
            for each (var eachTips:Array in dummyTips) {
                for each (var tipCards:Array in eachTips) {
                    if (isInvincible(tipCards, false)) {
                        // 无敌大牌
                        invincibleParts.push(tipCards);
                    } else {
                        // 非无敌大牌
                        vincibleParts.push(tipCards);
                    }
                }
            }
            return [invincibleParts, vincibleParts];
        }

        /**
         * 
         * 统计出所有的无敌大牌与小牌，让大牌与小牌配对
         * 
         * @param dummyTips  所有提示牌型
         * @param myTipCount 玩家当前手中的牌型个数
         * @return 当没有可用的摆渡策略时，返回null，否则返回摆渡策略结果
         */
        private function testRoundabout(dummyTips:Array, myTipCount:int):Object {
            if (myTipCount < 3) {
                return null;
            }
            // 整理提示牌型，数组形式为：[【V10】,【V5】],[【VJ,VJ】],[【V10,VJ,VQ,VK】]
            var xxx:Object = {
                invincible: [],
                vincible: [],
                invincibleSeq: [],
                vincibleSeq: [],
                maxLengthVincible: [] // 牌数最多的非顺子牌型
            };
            // 大小牌归类
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
                // 存在一种以上的非无敌顺子大牌
                return null;
            }
            if (xxx.vincibleSeq.length == 1) {
                // 存在一种顺子非无敌大牌
                xxx.hasSeqTail = true;
            }
            if (tipCount(xxx.invincible) < tipCount(xxx.vincible)) {
                // 当无敌大牌总和大于无敌小牌总和时，需要最后一个出牌数最多的小牌
                xxx.hasVincibleTail = true;
            }
            if (xxx.hasSeqTail && xxx.hasVincibleTail) {
                // 需要最后出顺子小牌和非无敌大牌时
                return null;
            }
            if (xxx.hasVincibleTail && (tipCount(xxx.invincible) < tipCount(xxx.vincible) - xxx.maxLengthVincible.length)) {
                // 需要最后一个出非无敌大牌，且无敌大牌个数的总和小于无敌小牌个数的总和与牌数最多的小牌的个数差时
                return null;
            }
            // 不执行拆牌操作，直接匹配
            dummyTips = [];
            for each (tipCards in xxx.invincible) {
                dummyTips.push(tipCards);
                for each (tipCards in xxx.vincible) {
                    if ((dummyTips[dummyTips.length - 1] as Array).length == tipCards.length) {
                        (xxx.vincible as Array).splice((xxx.vincible as Array).indexOf(tipCards), 1);
                        dummyTips.push(tipCards);
                        break;
                    }
                }
                if (dummyTips.length % 2 == 1) {
                    return null;
                }
            }
            
            if ((xxx.vincible as Array).length + (xxx.vincibleSeq as Array).length > 1) {
                return null;
            } else {
                dummyTips = dummyTips.reverse();
                xxx.discardIndex = 0;
                if ((xxx.vincible as Array).length + (xxx.vincibleSeq as Array).length == 1) {
                    // 存在尾牌的时候
                    dummyTips.push((xxx.vincible as Array).length > 0 ? xxx.vincible : xxx.vincibleSeq);
                }
                xxx.discardCards = dummyTips;
                return xxx;
            }
            return null;
            // TODO The following codes are commented at 2010/05/18
//            // 组合摆渡对儿，即相同牌型的一个非无敌大牌对应一个无敌大牌
//            if (xxx.hasVincibleTail) {
//                // 从xxx的非无敌大牌中，去除牌数最多的非无敌大牌
//                (xxx.vincible as Array).splice((xxx.vincible as Array).indexOf(xxx.maxLengthVincible), 1);
//            }
//            xxx.discardCards = testMatch(xxx);
//            // 补充尾牌
//            if (xxx.discardCards) {
//                var tailCards:Array = null;
//                if (xxx.hasVincibleTail) {
//                    (xxx.discardCards as Array).push(xxx.maxLengthVincible);
//                } else if (xxx.hasSeqTail) {
//                    (xxx.discardCards as Array).push(xxx.vincibleSeq[0]);
//                }
//            }
//            xxx.discardIndex = 0;
//            return xxx.discardCards ? xxx : null;
        }

        /**
         *  // 整理提示牌型，数组形式为：["V10","V5","VJ,VJ"],["V10,VJ,VQ,VK"],["1V5,1V5"]
         *  var xxx:Object = {
         *      invincible: [],
         *      vincible: [],
         *      invincibleSeq: [],
         *      vincibleSeq: [],
         *      maxLengthVincible: [] // 牌数最多的非顺子牌型
         *  };
         * @param xxx
         * @return 
         * 
         */
        private function testMatch(xxx:Object):Array {
            // 筛选非无敌大牌(不包含顺子)
            var tempVincibleArray:Array = [];
            // 处理小牌
            for each (var eachVincible:Array in (xxx.vincible as Array)) {
                tempVincibleArray.push(eachVincible);
            }
            // 将对子及同张的无敌大牌继续拆分成多个张数更少的牌型
            var tempInvincibleArray:Array = [];
            for each (var eachInvincible:Array in (xxx.invincible as Array)) {
                if (/^V(10|[JQKA])$/.test(eachInvincible[0]) || eachInvincible.length == 1) {
                    // 跳过单张或是以10、J、Q、K、A开头的牌
                    tempInvincibleArray.push(eachInvincible);
                    continue;
                }
                // 开始拆分
                if ("1V5,1V5,0VX,0VX,0VY,0VY".indexOf("," + eachInvincible[0].toString()) > -1) {
                    // 对红五或对大王或对小王
                    if (eachInvincible.toString().indexOf("0VX") > -1 && isInvincible(["0VX"], false)) {
                        tempInvincibleArray.push(["0VX"]);
                        tempInvincibleArray.push(["0VX"]);
                    } else if (eachInvincible.toString().indexOf("0VY") > -1 && isInvincible(["0VY"], false)) {
                        tempInvincibleArray.push(["0VY"]);
                        tempInvincibleArray.push(["0VY"]);
                    } else if (eachInvincible.toString().indexOf("1V5") > -1) {
                        tempInvincibleArray.push(["1V5"]);
                        tempInvincibleArray.push(["1V5"]);
                    } else {
                        tempInvincibleArray.push(eachInvincible);
                    }
                } else if (eachInvincible[0].toString().indexOf("V5") > -1) {
                    // 草五
                    if (eachInvincible.length <= 3 && isInvincible(["V5"], false)) {
                        eachInvincible.forEach(function(item:*, index:int, array:Array):void {
                            tempInvincibleArray.push(["V5"]);
                        });
                    } else if (eachInvincible.length > 3 && isInvincible(["V5", "V5"], false)) {
                        // 四张或更多草五时
                        switch (eachInvincible.length) {
                            case 4:
                                tempInvincibleArray.push(["V5", "V5"]);
                                tempInvincibleArray.push(["V5", "V5"]);
                                break;
                            case 5:
                                tempInvincibleArray.push(["V5", "V5"]);
                                tempInvincibleArray.push(["V5", "V5", "V5"]);
                                break;
                            case 6:
                                tempInvincibleArray.push(["V5", "V5"]);
                                if (isInvincible(["V5"], false)) {
                                    tempInvincibleArray.push(["V5"]);
                                    tempInvincibleArray.push(["V5", "V5", "V5"]);
                                } else {
                                    tempInvincibleArray.push(["V5", "V5"]);
                                    tempInvincibleArray.push(["V5", "V5"]);
                                }
                                break;
                        }
                    } else {
                        tempInvincibleArray.push(eachInvincible);
                    }
                } else if (false) {
                    // TODO 暂时不拆分2，如果拆分，拆成3张+X张，X可能为vincible
                    //                    // 2
                    //                    if (isInvincible(["0VX"], false)) {
                    //                        
                    //                    }
                } else {
                    tempInvincibleArray.push(eachInvincible);
                }
            }
            // 考虑效率问题，暂时只处理张数在【6】以内的无敌大牌
            if (tempInvincibleArray.length > 6) {
                return null;
            }
            // 开始进行大牌与小牌进行配对
            var invincibleItems:Array = [];
            var vincibleItems:Array = [];
            // 按长度对大牌和小牌进行归类，以便后期处理使用
            var invincibleItemsLengthMap:Array = [];
            var vincibleItemsLengthMap:Array = [];
            for each (var eachInvincibleItems:Array in tempInvincibleArray) {
                invincibleItems.push(eachInvincibleItems.length);
                // 按长度进行归类
                if (!invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)]) {
                    invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)] = [];
                }
                (invincibleItemsLengthMap["L" + String(eachInvincibleItems.length)] as Array).push(eachInvincibleItems);
            }
            for each (var eachVincibleItems:Array in tempVincibleArray) {
                vincibleItems.push(eachVincibleItems.length);
                // 按长度进行归类
                if (!vincibleItemsLengthMap["L" + String(eachVincibleItems.length)]) {
                    vincibleItemsLengthMap["L" + String(eachVincibleItems.length)] = [];
                }
                (vincibleItemsLengthMap["L" + String(eachVincibleItems.length)] as Array).push(eachVincibleItems);
            }
            vincibleItems = vincibleItems.sort(Array.NUMERIC);
            invincibleItems = invincibleItems.sort(Array.NUMERIC);
            // >>>
            
            // <<<
            //    |
            //    |
            //    |
            //    |
            //    |
            //    |
            //  \ | /
            //   \|/
            var tempVincibleString:String = null;
            var tempinvincibleString:String = null;
            // 拼凑辅助性小牌与无敌大牌的字符串
            var pieces:Array = [];
            tempVincibleArray.forEach(function(item:*, index:int, array:Array):void {
                pieces.push((item as Array).toString());
            });
            tempVincibleString = pieces.join(";");
            pieces = [];
            tempInvincibleArray.forEach(function(item:*, index:int, array:Array):void {
                pieces.push((item as Array).toString());
            });
            tempinvincibleString = pieces.join(";");
            // 生成摆渡方案，组合形式为：2,=2,1,2,=3,3,=3,1,4,=5,1
            // 其中以“=”为前缀的代表小牌的牌型，不带“=”的代表大牌的牌型，这些牌型可以从vincibleItemsLengthMap和invincibleItemsLengthMap中找到
            var discardOrderArray:Array = testAllCases(invincibleItems, vincibleItems);
            // 将匹配的内容进行处理，TODO合并
            if (discardOrderArray && discardOrderArray.length > 0) {
                discardOrderArray = discardOrderArray.toString().split(/(?<==\d),/g);
                var thisVincible:String = null; // 当前正在参与配对的小牌，可能需要分解的
                var finalDiscardCards:Array = []; // 保存计算好的出牌顺序，形式为小牌,大牌(,小牌,大牌)
                for each (var eachDiscardOrder:String in discardOrderArray) {
                    // 利用取得的拆分方案，对现有的无敌大牌，小牌进行拆分组合
                    // eachDiscardOrder为一个组合方案或是天外天
                    for each (var eachOrder:String in eachDiscardOrder.split(",")) {
                        if (eachOrder.charAt(0) == "=") {
                            // 处理小牌，将标识变量重置为空
                            thisVincible = null;
                            continue;
                        } else {
                            // 处理无敌大牌
                            if (!thisVincible && eachDiscardOrder.indexOf("=") > -1) {
                                // 根据小牌的个数来进行定位并删除
                                thisVincible = ((vincibleItemsLengthMap["L" + eachOrder] as Array).shift() as Array)[0];
                            }
                            // 放入小牌
                            if (thisVincible) {
                                finalDiscardCards.push(new Array(eachOrder).toString().replace(/,/g, thisVincible + ",").concat(thisVincible).split(","));
                            }
                            // 放入大牌
                            finalDiscardCards.push((invincibleItemsLengthMap["L" + eachOrder] as Array).shift());
                        }
                    }
                }
                return finalDiscardCards;
            } else {
                return null;
            }
        }
        
        /**
         * 根据给定的大牌牌型和小牌牌型，让大小牌配对，匹配不上的大牌不做处理。<br />
         * 小牌的牌数总和小于大牌的牌数总和。
         * 
         * @param invincibleItems 无敌大牌
         * @param vincibleItems   送死小牌
         * @param filters         辅助参数，可以忽略
         * @param singleFilter    辅助参数，可以忽略
         * @param finalResults    辅助参数，可以忽略
         * @return 
         * 
         */
        private function testAllCases(invincibleItems:Array, vincibleItems:Array, finalResults:Array = null, filters:String = "", singleFilter:String = ""):Array {
            var tempItems:Array = null;
            var discardOrder:Array = [];
            if (!finalResults) {
                finalResults = [];
            }
            if (filters.length == 0) {
                tempItems = invincibleItems;
                if (!tempItems) {
                    return null;
                }
            } else {
                tempItems = invincibleItems.toString().replace(new RegExp("[" + singleFilter + "]"), "").replace(/,{2,}/g, ",").replace(/^,|,$/g, "").split(",");
            }
            if (tempItems[0].toString().length == 0) {
                finalResults.push(filters);
                return null;
            }
            for (var i:int = 0; i < tempItems.length; i++) {
                if (int(filters.charAt(0)) > vincibleItems[0]) {
                    break;
                }
                testAllCases(tempItems, vincibleItems, finalResults, filters + tempItems[i], tempItems[i]);
            }
            if (filters.length == 0) {
                // 摆独匹配
                for each (var eachItem:String in finalResults) {
                    var sumValue:int = 0;
                    i = 0;
                    tempItems = eachItem.split("");
                    for each (eachItem in tempItems) {
                        sumValue += int(eachItem);
                        discardOrder.push(int(eachItem));
                        if (sumValue == vincibleItems[i]) {
                            discardOrder.push("=" + sumValue);
                            sumValue = 0;
                            i++;
                        } else if (sumValue > vincibleItems[i]) {
                            discardOrder = [];
                            break;
                        }
                    }
                    if (i == vincibleItems.length) {
                        tempItems = discardOrder;
                        return tempItems;
                    }
                }
            }
            return null;
        }
    }
}
