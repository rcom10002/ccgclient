package info.knightrcom.state {
    import component.MahjongButton;
    
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.command.PushdownWinGameCommand;
    import info.knightrcom.event.GameEvent;
    import info.knightrcom.event.PushdownWinGameEvent;
    import info.knightrcom.state.pushdownwingame.PushdownWinGame;
    import info.knightrcom.state.pushdownwingame.PushdownWinMahjongBox;
    import info.knightrcom.util.ListenerBinder;
    
    import mx.containers.Box;
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.controls.ProgressBarMode;
    import mx.events.FlexEvent;
    import mx.events.ItemClickEvent;
    import mx.states.State;

    /**
     *
     * 推倒胡游戏状态管理器
     *
     */
    public class PushdownWinGameStateManager extends AbstractGameStateManager {

        /**
         * 游戏中玩家的个数
         */
        public static var playerCogameNumber:int;

        /**
         * 当前游戏id
         */
        public static var currentGameId:String;

        /**
         * 当前玩家序号
         */
        public static var localNumber:int;

        /**
         * 下家玩家序号
         */
        public static var localNextNumber:int;

        /**
         * 消息中的发牌玩家序号
         */
        public static var currentNumber:int;

        /**
         * 消息中的牌序
         */
        public static var currentBoutMahjong:String = null;

        /**
         * 消息中的下家玩家序号
         */
        public static var currentNextNumber:int;

        /**
         * 第一名玩家序号
         */
        public static var firstPlaceNumber:int = UNOCCUPIED_PLACE_NUMBER;

        /**
         * 第二名玩家序号
         */
        public static var secondPlaceNumber:int = UNOCCUPIED_PLACE_NUMBER;

        /**
         * 未占用的位置
         */
        public static const UNOCCUPIED_PLACE_NUMBER:int = -1;

		/**
		 * 用户发牌最大等待时间(秒)
		 */
		private static const MAX_CARDS_SELECT_TIME:int = 10;

        /**
         * 待发牌区域
         */
        private static var mahjongsCandidatedArray:Array = null;

        /**
         * 杠吃碰牌区域
         */
        private static var mahjongsDaisArray:Array = null;

        /**
         * 摸牌区域
         */
        private static var mahjongsRandArray:Array = null;

        /**
         * 玩家方向
         */
        private static var playerDirectionArray:Array = null;

        /**
         * 游戏中的麻将内存模型
         */
		private static var mahjongBox:PushdownWinMahjongBox;

		/**
		 * 计时器
		 */
		private var timer:Timer = new Timer(1000, MAX_CARDS_SELECT_TIME);

        /**
         * 当前游戏模块
         */
		private var currentGame:CCGamePushdownWin = null;

        /**
         *
         * @param socketProxy
         * @param currentGame
         * @param myState
         *
         */
        public function PushdownWinGameStateManager(socketProxy:GameSocketProxy, gameClient:CCGameClient, myState:State):void {
            super(socketProxy, gameClient, myState);
            ListenerBinder.bind(myState, FlexEvent.ENTER_STATE, init);
            batchBindGameEvent(PushdownWinGameEvent.EVENT_TYPE, new Array(
                    GameEvent.GAME_WAIT, gameWaitHandler,
                    GameEvent.GAME_CREATE, gameCreateHandler,
            		GameEvent.GAME_STARTED, gameStartedHandler,
            		GameEvent.GAME_FIRST_PLAY, gameFirstPlayHandler,
            		GameEvent.GAME_BRING_OUT, gameBringOutHandler,
            		GameEvent.GAME_INTERRUPTED, gameInterruptedHandler,
            		GameEvent.GAME_WINNER_PRODUCED, gameWinnerProducedHandler,
            		GameEvent.GAME_OVER, gameOverHandler));
        }

        /**
         *
         * @param event
         *
         */
        private function init(event:Event):void {
            if (!isInitialized()) {
                // 配置事件监听
                // 非可视组件
            	this.currentGame = gameClient.pushdownWinGameModule;
				timer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void {
					currentGame.timerTip.setProgress(MAX_CARDS_SELECT_TIME - timer.currentCount, MAX_CARDS_SELECT_TIME);
					currentGame.timerTip.label = "剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME - timer.currentCount);
					if (timer.currentCount == MAX_CARDS_SELECT_TIME) {
                        if (currentGame.randDown.numChildren > 0) {
                            // 摸牌区域有牌时，将摸到的牌打出
                            dealMahjong(MahjongButton(currentGame.randDown.getChildAt(0)));
                        } else {
                            // 摸牌区域无牌时，将玩家手中第一张牌打出
                            dealMahjong(MahjongButton(currentGame.candidatedDown.getChildAt(0)));
                        }
					}
				});
                // 可视组件
                ListenerBinder.bind(currentGame.btnBarMahjongs, ItemClickEvent.ITEM_CLICK, itemClick);
                ListenerBinder.bind(currentGame.btnBarMahjongs, FlexEvent.SHOW, show);
                ListenerBinder.bind(currentGame.btnBarMahjongs, FlexEvent.HIDE, hide);
                setInitialized(true);
            }
            // 按照当前玩家序号，进行画面座次安排
            var tempMahjongsCandidated:Array = new Array(currentGame.candidatedDown, currentGame.candidatedRight, currentGame.candidatedUp, currentGame.candidatedLeft);
            var tempMahjongsDais:Array = new Array(currentGame.daisDown, currentGame.daisRight, currentGame.daisUp, currentGame.daisLeft);
            var tempMahjongsRand:Array = new Array(currentGame.randDown, currentGame.randRight, currentGame.randUp, currentGame.randLeft);
            var tempPlayerDirection:Array = new Array("down", "right", "up", "left")
            // 进行位移操作
            var index:int = 0;
            while (index != localNumber - 1) {
                var temp:Object = null;
                temp = tempMahjongsCandidated.pop();
                tempMahjongsCandidated.unshift(temp);
                temp = tempMahjongsDais.pop();
                tempMahjongsDais.unshift(temp);
                temp = tempMahjongsRand.pop();
                tempMahjongsRand.unshift(temp);
                temp = tempPlayerDirection.pop();
                tempPlayerDirection.unshift(temp);
                index++;
            }
            // 更改画面组件
            mahjongsCandidatedArray = new Array(playerCogameNumber);
            for (index = 0; index < mahjongsCandidatedArray.length; index++) {
                mahjongsCandidatedArray[index] = tempMahjongsCandidated[index];
            }
            mahjongsDaisArray = new Array(playerCogameNumber);
            for (index = 0; index < mahjongsDaisArray.length; index++) {
                mahjongsDaisArray[index] = tempMahjongsDais[index];
            }
            mahjongsRandArray = new Array(playerCogameNumber);
            for (index = 0; index < mahjongsRandArray.length; index++) {
                mahjongsRandArray[index] = tempMahjongsRand[index];
            }
            playerDirectionArray = new Array(playerCogameNumber);
            for (index = 0; index < playerDirectionArray.length; index++) {
                playerDirectionArray[index] = tempPlayerDirection[index];
            }
            currentGame.btnBarMahjongs.visible = false;
            currentGame.timerTip.label = "剩余时间：";
		    currentGame.timerTip.minimum = 0;
            currentGame.timerTip.maximum = MAX_CARDS_SELECT_TIME;
            currentGame.timerTip.mode = ProgressBarMode.MANUAL;
            mahjongBox = new PushdownWinMahjongBox();
        }

        /**
         *
         * 游戏开始时，将系统分配的麻将进行排序
         *
         * @param event
         *
         */
        private function gameStartedHandler(event:PushdownWinGameEvent):void {
            // 显示系统洗牌后的结果，格式为：一号玩家待发牌 + "~" + 二号玩家待发牌 + "~" + 
            // 三号玩家待发牌 + "~" + 四号玩家待发牌 + "~" + 其余未分配的牌 
            var results:Array = event.incomingData.split("~");
            mahjongBox.mahjongsOfPlayers = new Array(results[0], results[1], results[2], results[3]);
            mahjongBox.mahjongsSpared = results[4].toString().split(",");
            var mahjongSequence:String = results[localNumber - 1];
            var mahjongNames:Array = PushdownWinGame.sortMahjongs(mahjongSequence);
            // 为当前玩家发牌
            for each (var mahjongName:String in mahjongNames) {
                addMahjongDown(currentGame.candidatedDown, "image/mahjong/down/standard/" + mahjongName + ".jpg");
            }
            // 为其他玩家发牌
            var index:int = 0;
            while (index != playerCogameNumber) {
                // 跳过当前玩家
                if (localNumber == index + 1) {
                    index++;
                    continue;
                }
                // 获取玩家手中的牌数
                var mahjongNumber:int = Number(results[index].toString().split(",").length);
                // 获取当前玩家待发牌个数
                var mahjongsCandidated:Box = Box(mahjongsCandidatedArray[index]);
                // 为其他玩家发牌，全为牌的背面图案
                for (var i:int = 0; i < mahjongNumber; i++) {
                    addMahjongExceptDown(mahjongsCandidated, "image/mahjong/" + playerDirectionArray[index] + "/standard/DEFAULT.jpg");
                }
                index++;
            }
            // 操作按钮初始化
            resetBtnBar();
        }

        /**
         *
         * 当前玩家为第一个发牌者时，开始进行游戏设置
         *
         * @param event
         *
         */
        private function gameFirstPlayHandler(event:PushdownWinGameEvent):void {
            // 开始摸牌
            var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
            dummyEvent.index = PushdownWinGame.OPTR_RAND;
            itemClick(dummyEvent);
            // 显示操作按钮
            currentGame.btnBarMahjongs.visible = true;
        }

        /**
         *
         * 接收到系统通知当前玩家出牌的消息<br>
         * 数据格式为：<br>
         * 当前玩家序号~牌名~下家玩家序号 - 玩家发牌格式<br>
         * 牌名 - 玩家摸牌格式<br>
         *
         * @param event
         *
         */
        private function gameBringOutHandler(event:PushdownWinGameEvent):void {
            // 接收上家出牌序列，显示出牌结果
            var results:Array = event.incomingData.split("~");
            if (results.length == 1) {
                // 玩家摸牌时，从尚未使用过的牌中移除已摸的牌，更新麻将模型
                mahjongBox.rand(results[0] - 1);
                return;
            }
            currentNumber = results[0];
            currentBoutMahjong = results[1];
            currentNextNumber = results[2];

            // 更新模型中已打出的牌
            mahjongBox.deal(currentNumber - 1, currentBoutMahjong);
            var boutMahjongButton:MahjongButton = new MahjongButton();
            boutMahjongButton.allowSelect = false;
            boutMahjongButton.source = "image/mahjong/down/standard/" + currentBoutMahjong + ".jpg"
            currentGame.dealed.addChild(boutMahjongButton);

            if (currentNumber == currentNextNumber) {
            	// TODO 有玩家暗杠时，只做模型更新
            	return;
            }

            // 初始化操作按钮
            resetBtnBar();

			// 从非出牌玩家中，找出唯一一个可以进行胡牌、杠牌或碰牌操作的玩家
			// 玩家的优先权取决于操作权（如胡牌优先权最高，其次是杠牌，再次是碰牌）
			var finalMixedIndex:int = -1;
			var won:Boolean, konged:Boolean, ponged:Boolean = false;
			var indexWin:int = PushdownWinGame.isWin(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, currentNumber - 1);
			finalMixedIndex = indexWin > 0 ? indexWin : finalMixedIndex;
			won = finalMixedIndex > -1; 
			if (!won) {
				var indexKong:int = PushdownWinGame.isKong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, currentNumber - 1);
				finalMixedIndex = indexKong > 0 ? indexKong : finalMixedIndex;
				konged = finalMixedIndex > -1;
			}
			if (!konged) {
    			var indexPong:int = PushdownWinGame.isPong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, currentNumber - 1);
    			finalMixedIndex = indexPong > 0 ? indexPong : finalMixedIndex;
				ponged = finalMixedIndex > -1;
			}

			// 准备胡杠碰操作
			// 玩家索引
			var playerIndex:int = finalMixedIndex % 10;
	     	if (finalMixedIndex > 0 && playerIndex != localNumber - 1) {
	     		// 胡牌、杠牌、碰牌玩家非当前玩家时，不执行任何操作
	     		return;
	     	} else if (finalMixedIndex > 0) {
	     		// 胡牌、杠牌、碰牌玩家为当前玩家时
	     		Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_GIVEUP)).enabled = true;
                currentGame.btnBarMahjongs.visible = true;
	     	}

			// 更改操作按钮状态
			// 操作索引
			var operationIndex:int = finalMixedIndex / 10;
  			var operationList:Array = new Array(
	  			function ():void {
					if (won && playerIndex == localNumber - 1) {
						// 胡牌，为出牌玩家设置麻将操作按钮外观
						Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_WIN)).enabled = true;
					}
	  			},
	  			function ():void {
					if (konged && playerIndex == localNumber - 1) {
						// 杠牌，为出牌玩家设置麻将操作按钮外观
						Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_KONG)).enabled = true;
					}
	  			},
	  			function ():void {
					if (ponged && playerIndex == localNumber - 1) {
						// 碰牌，为出牌玩家设置麻将操作按钮外观
						Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_PONG)).enabled = true;
					}
	  			}
	     	);
	     	for (var i:int = operationIndex; i < 3; i++) {
	     		operationList[i]();
	     	}
	     	// 没有玩家胡牌、杠牌、胡牌时，为当前玩家出牌做准备
			if (finalMixedIndex < 0 && currentNextNumber == localNumber) {
				// 吃牌判断
		     	if (PushdownWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])) {
		     		// 启用吃牌按钮
		     		Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_CHOW)).enabled = true;
		     		// 启用摸牌按钮
		     		Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_RAND)).enabled = true;
		     	}
            	// 为出牌玩家设置麻将操作按钮外观
                currentGame.btnBarMahjongs.visible = true;
                // 自动摸牌
	            var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
	            dummyEvent.index = PushdownWinGame.OPTR_RAND;
	            itemClick(dummyEvent);
            }
        }

        /**
         *
         * 接收到当前玩家为第一个发牌者通知
         *
         * @param event
         *
         */
        private function gameInterruptedHandler(event:PushdownWinGameEvent):void {
            currentGame.currentState = "LOBBY";
            gameClient.txtSysMessage.text += "游戏中断！请重新加入游戏！\n";
        }

        /**
         *
         * 游戏结束
         *
         * @param event
         *
         */
        private function gameOverHandler(event:PushdownWinGameEvent):void {
//            // 格式：发前玩家~牌序~接牌玩家
//            var results:Array = event.incomingData.split("~");
//            currentNumber = results[0];
//            currentBoutMahjong = results[1];
//            currentNextNumber = results[2];
//            var scoreboardInfo:Array = String(results[3]).split(/;/);
//            // 非出牌者时，移除桌面上显示的已出的牌，在桌面上显示最近新出的牌
//            // if (localNumber != currentNumber && gameSetting != PushdownWinGameSetting.EXTINCT_RUSH) {
//            if (localNumber != currentNumber && isOrderNeighbor(currentNumber, currentNextNumber)) {
//                // 本局待发牌区域
//                var mahjongsCandidated:Box = mahjongsCandidatedArray[Number(currentNumber) - 1];
//                // 本局已发牌区域
//                var mahjongsDealed:Tile = mahjongsDealedArray[Number(currentNumber) - 1];
//                mahjongsDealed.removeAllChildren();
//                var mahjongNames:Array = currentBoutMahjong.split(",");
//                for each (var mahjongName:String in mahjongNames) {
//                    // 为发牌区域添加已经发出的牌
//                    var mahjong:MahjongButton = new MahjongButton();
//                    mahjong.allowSelect = false;
//                    mahjong.source = "image/mahjong/" + mahjongName + ".png";
//                    mahjongsDealed.addChild(mahjong);
//                    // 从待发牌区域移除已经发出的牌
//                    mahjongsCandidated.removeChildAt(0);
//                }
//            }
//            // 设置游戏排名
//            if (gameSetting == PushdownWinGameSetting.NO_RUSH) {
//                // 设置不独时的排名
//                thirdPlaceNumber = currentNumber;
//                forthPlaceNumber = currentNextNumber;
//            } else if (gameSetting != PushdownWinGameSetting.NO_RUSH) {
//                // 设置独牌时的排名
//                firstPlaceNumber = currentNumber;
//            }
//            // 显示记分牌
//            new Scoreboard().popUp(currentGame, scoreboardInfo, function():void {
//            	currentGame.currentState = 'LOBBY';
//            });
//            // 显示游戏积分
//            if (gameSetting != PushdownWinGameSetting.NO_RUSH) {
//                var rushResult:String = null;
//                if (firstPlaceNumber == gameFinalSettingPlayerNumber) {
//                    rushResult = "成功！";
//                } else {
//                    rushResult = "失败！";
//                }
//                // 游戏结束，并且当前玩家不是最终的游戏规则设置者
////                Alert.show(PushdownWinGameSetting.getDisplayName(gameSetting) + rushResult, "信息", Alert.OK, currentGame, function():void {
////                        currentGame.currentState = "LOBBY";
////                    });
//                currentGame.txtSysMessage.text += PushdownWinGameSetting.getDisplayName(gameSetting) + rushResult + "\n";
//            } else {
////                Alert.show(new Array(firstPlaceNumber, secondPlaceNumber, thirdPlaceNumber, forthPlaceNumber).join(","), "信息", Alert.OK, currentGame, function():void {
////                        currentGame.currentState = "LOBBY";
////                    });
//                currentGame.txtSysMessage.text += [firstPlaceNumber, 
//                                                  secondPlaceNumber, 
//                                                  thirdPlaceNumber, 
//                                                  forthPlaceNumber].join(",") + "\n";
//            }
        }

        /**
         *
         * 没有独牌或天独的情况下，游戏中产生获胜者
         *
         * @param event
         *
         */
        private function gameWinnerProducedHandler(event:PushdownWinGameEvent):void {
            // TODO
            Alert.show("function gameWinnerProducedHandler haven't been implemented yet.");
        }

        /**
         *
         * 游戏创建，为客户端玩家分配游戏id号与当前游戏玩家序号以及下家玩家序号
         *
         * @param event
         *
         */
        private function gameCreateHandler(event:GameEvent):void {
            // 游戏初始化
            var results:Array = null;
            if (event.incomingData != null) {
                results = event.incomingData.split("~");
            }
            PushdownWinGameStateManager.resetInitInfo();
            PushdownWinGameStateManager.currentGameId = results[0];
            PushdownWinGameStateManager.localNumber = results[1];
            PushdownWinGameStateManager.playerCogameNumber = results[2];
            // 为当前玩家的下家分配编号
            if (PushdownWinGameStateManager.playerCogameNumber == PushdownWinGameStateManager.localNumber) {
                PushdownWinGameStateManager.localNextNumber = 1;
            } else {
                PushdownWinGameStateManager.localNextNumber = PushdownWinGameStateManager.localNumber + 1;
            }
            gameClient.currentState = "PUSHDOWNWINGAME";
        }

        /**
         *
         * @param event
         *
         */
        private function gameWaitHandler(event:GameEvent):void {
            gameClient.txtSysMessage.text += event.incomingData + "\n";
            gameClient.txtSysMessage.selectionEndIndex = gameClient.txtSysMessage.length - 1;
        }

        /**
         *
         * 麻将操作
         *
         * 1#mahjongSeq#2#mahjongSeq#3#mahjongSeq#4#mahjongSeq#
         *
         * mahjongSeq = 1V3,2V3,3V3,4V3|2V3,3V4,4V5,3V6
         *
         * @param event
         *
         */
        private function itemClick(event:ItemClickEvent):void {
            var i:int = -1;
            switch (event.index) {
                case 0:
                    // 胡牌
                    socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END);
                    break;
                case 1:
                    // 杠
                    for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                        if (currentBoutMahjong == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                            break;
                        }
                    }
                    var mahjongKong1:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 2));
                    var mahjongKong2:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 1));
                    var mahjongKong3:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i));
                    currentGame.daisDown.addChild(mahjongKong1);
                    currentGame.daisDown.addChild(mahjongKong2);
                    currentGame.daisDown.addChild(mahjongKong3);
                    break;
                case 2:
                    // 碰
                    for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                        if (currentBoutMahjong == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                            break;
                        }
                    }
                    var mahjongPong1:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 1));
                    var mahjongPong2:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i));
                    currentGame.daisDown.addChild(mahjongPong1);
                    currentGame.daisDown.addChild(mahjongPong2);
                    break;
                case 3:
                    // 吃
                    // TODO 选择要出的牌
                    var mahjongs:String = "";
                    for each (var mahjong:MahjongButton in currentGame.candidatedDown.getChildren()) {
                        if (mahjong.isSelected()) {
                            mahjongs += mahjong.value + ",";
                        }
                    }
                    mahjongs = mahjongs.replace(/,$/, "");
                    // 未作任何选择时，直接退出处理
                    if (mahjongs.length == 0) {
                        return;
                    }
                    // 设置出牌结果
                    // 当前剩余的牌数
                    var mahjongsCandicateNumber:int = currentGame.candidatedDown.getChildren().length;
                    // 即将打出的牌数
                    var mahjongsDealedNumber:int = mahjongs.split(",").length;
                    // 打出后剩余牌数
                    var mahjongsLeftNumber:int = mahjongsCandicateNumber - mahjongsDealedNumber;
                    // 出牌操作结束后，关闭麻将操作栏
                    currentGame.btnBarMahjongs.visible = false;
                    break;
                case 4:
	            	// 玩家放弃胡牌、杠牌、碰牌操作，则将优先权转移至下家玩家
	            	// TODO
                    break;
                case 5:
                    // 摸牌
                    var mahjongRandValue:String = mahjongBox.rand(localNumber - 1);
                    if (mahjongRandValue == null) {
                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END, null);
                        return;
                    }
                    var mahjongRand:MahjongButton = new MahjongButton();
                    mahjongRand.source = "image/mahjong/down/standard/" + mahjongRandValue + ".jpg";
                    ListenerBinder.bind(mahjongRand, MouseEvent.CLICK, function (event:MouseEvent):void {
                        dealMahjong(mahjongRand);
                    });
                    currentGame.randDown.addChild(mahjongRand);
                    // 判断是否可以自摸、杠
                    // TODO
                    socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, mahjongRandValue);
                    break;
            }
        }

		/**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
		 * 
		 */
		private function show(event:FlexEvent):void {
			// 显示进度条，倒计时开始开始
            currentGame.timerTip.setProgress(MAX_CARDS_SELECT_TIME, MAX_CARDS_SELECT_TIME);
			currentGame.timerTip.label = "剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME);
			currentGame.timerTip.visible = true;
			timer.start();
		}

		/**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
		 * 
		 */
		private function hide(event:FlexEvent):void {
			// 进度条隐藏，并重置计时器
			currentGame.timerTip.visible = false;
			timer.reset();
		}

        /**
         *
         * 打出选中的麻将牌
         * 
         * @param mahjong
         * @return 
         * 
         */
        private function dealMahjong(mahjong:MahjongButton):void {
            if (!currentGame.btnBarMahjongs.visible || !mahjong.allowSelect) {
                return;
            }

            // 隐藏操作按钮
            currentGame.btnBarMahjongs.visible = false;

            // 从玩家手中牌删除选中牌
            mahjong.parent.removeChild(mahjong);

            // 将牌显示在桌面
            mahjong.allowSelect = false;
            currentGame.dealed.addChild(mahjong);

            // 重新设置当前玩家的布局
            var mahjongsDown:Array = currentGame.candidatedDown.getChildren();
            var mahjongsNewDown:Array = mahjongsDown.concat(currentGame.randDown.getChildren());
            currentGame.candidatedDown.removeAllChildren();
            // 重新排序
            for each (var eachMahjongButton:MahjongButton in PushdownWinGame.sortMahjongButtons(mahjongsNewDown)) {
                currentGame.candidatedDown.addChild(eachMahjongButton);
            }

            // 更新内存模型
            mahjongBox.deal(localNumber - 1, mahjong.value);

            // 发送出牌命令
            socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + mahjong.value + "~" + localNextNumber);
        }

        /**
         * 
         * @param container
         * @param picPath
         * @return 
         * 
         */
        private function addMahjongDown(
                container:DisplayObjectContainer, 
                picPath:String):MahjongButton {
            var mahjong:MahjongButton = new MahjongButton();
            mahjong.source = picPath;
            ListenerBinder.bind(mahjong, MouseEvent.CLICK, function (event:MouseEvent):void {
                dealMahjong(mahjong);
            });
            container.addChild(mahjong);
            return mahjong;
        }

        /**
         * 
         * @param container
         * @param picPath
         * @return 
         * 
         */
        private function addMahjongExceptDown(
                container:DisplayObjectContainer, 
                picPath:String):MahjongButton {
            var mahjong:MahjongButton = new MahjongButton();
            mahjong.allowSelect = false;
            mahjong.source = picPath;
            container.addChild(mahjong);
            return mahjong;
        }

        /**
         *
         * 禁用所有操作按钮 
         * 
         */
        private function resetBtnBar():void {
            for each (var eachButton:Button in currentGame.btnBarMahjongs.getChildren()) {
                eachButton.enabled = false;
            }
        }

        /**
         *
         * 重置参数初始化
         *
         */
        public static function resetInitInfo():void {
            // 参数初始化
            playerCogameNumber = 0;
            currentGameId = null;
            localNumber = 0;
            localNextNumber = 0;
            currentNumber = 0;
            currentBoutMahjong = null;
            currentNextNumber = 0;
            firstPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            secondPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            mahjongsCandidatedArray.removeAllChildren();
            mahjongsDaisArray.removeAllChildren();
            mahjongsRandArray.removeAllChildren();
            playerDirectionArray.removeAllChildren();
        }
    }
}