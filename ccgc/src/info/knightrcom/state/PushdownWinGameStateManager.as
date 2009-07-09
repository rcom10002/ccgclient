package info.knightrcom.state {
    import component.MahjongButton;
    
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.command.PushdownWinGameCommand;
    import info.knightrcom.event.GameEvent;
    import info.knightrcom.event.PushdownWinGameEvent;
    import info.knightrcom.state.pushdownwingame.PushdownWinGame;
    import info.knightrcom.util.ListenerBinder;
    
    import mx.containers.Box;
    import mx.containers.Tile;
    import mx.controls.Button;
    import mx.controls.ProgressBarMode;
    import mx.events.FlexEvent;
    import mx.events.ItemClickEvent;
    import mx.states.State;

    /**
     *
     * 红五游戏状态管理器
     *
     */
    public class PushdownWinGameStateManager extends AbstractGameStateManager {

        /**
         * 游戏中玩家的个数
         */
        public static var playerCogameNumber:int;

        /**
         * 游戏的最终设置所对应的玩家编号
         */
        public static var gameFinalSettingPlayerNumber:int = -1;

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
         * 第三名玩家序号
         */
        public static var thirdPlaceNumber:int = UNOCCUPIED_PLACE_NUMBER;

        /**
         * 第四名玩家序号
         */
        public static var forthPlaceNumber:int = UNOCCUPIED_PLACE_NUMBER;

        /**
         * 未占用的位置
         */
        public static const UNOCCUPIED_PLACE_NUMBER:int = -1;

		/**
		 * 用户发牌最大等待时间(秒)
		 */
		private static const MAX_CARDS_SELECT_TIME:int = 15;

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
         * 备选牌
         */
        private static var mahjongsSpared:Array = null;

        /**
         * 玩家方向
         */
        private static var playerDirection:Array = null;

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
                            dealMahjong("down", MahjongButton(currentGame.randDown.getChildAt(0)));
                        } else {
                            // 摸牌区域无牌时，将玩家手中第一张牌打出
                            dealMahjong("down", MahjongButton(currentGame.candidatedDown.getChildAt(0)));
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
            playerDirection = new Array(playerCogameNumber);
            for (index = 0; index < playerDirection.length; index++) {
                playerDirection[index] = tempPlayerDirection[index];
            }
            currentGame.btnBarMahjongs.visible = false;
            currentGame.timerTip.label = "剩余时间：";
		    currentGame.timerTip.minimum = 0;
            currentGame.timerTip.maximum = MAX_CARDS_SELECT_TIME;
            currentGame.timerTip.mode = ProgressBarMode.MANUAL;
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
            mahjongsSpared = results[4].toString().split(",");
            var mahjongSequence:String = results[localNumber - 1];
            var mahjongNames:Array = PushdownWinGame.sortMahjongs(mahjongSequence);
            var mahjong:MahjongButton = null;
            // 为当前玩家发牌
            for each (var mahjongName:String in mahjongNames) {
                mahjong = new MahjongButton();
                mahjong.source = "image/mahjong/down/standard/" + mahjongName + ".jpg";
                ListenerBinder.bind(mahjong, FlexEvent.HIDE, function (event:FlexEvent):void {
                    dealMahjong("down", mahjong);
                });
                currentGame.candidatedDown.addChild(mahjong);
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
                    mahjong = new MahjongButton();
                    mahjong.source = "image/mahjong/" + playerDirection[index] + "/standard/DEFAULT.jpg";
                    mahjong.allowSelect = false;
                    mahjongsCandidated.addChild(mahjong);
                }
                index++;
            }
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
            var mahjongValue:String = mahjongsSpared.pop();
            var mahjongRand:MahjongButton = new MahjongButton();
            mahjongRand.source = "image/mahjong/down/standard/" + mahjongValue + ".jpg";
            ListenerBinder.bind(mahjongRand, FlexEvent.HIDE, function (event:FlexEvent):void {
                dealMahjong("down", mahjongRand);
            });
            currentGame.randDown.addChild(mahjongRand);
            // 显示操作按钮
            currentGame.btnBarMahjongs.visible = true;
        }

        /**
         *
         * 接收到系统通知当前玩家出牌的消息，数据格式为：当前玩家序号~牌名,牌名...~下家玩家序号
         *
         * @param event
         *
         */
        private function gameBringOutHandler(event:PushdownWinGameEvent):void {
            // 接收上家出牌序列，显示出牌结果
            var results:Array = event.incomingData.split("~");
            currentNumber = results[0];
            currentBoutMahjong = results[1];
            currentNextNumber = results[2];
            var passed:Boolean = false;
            var count:int = 0;
            var tempTile:Tile = null;

            // 在桌面上显示最近新出的牌
            if (results.length == 4) {
                // 获取"不要"标识
                passed = ("pass" == results[3]);
            }
            // 上局待发牌区域
            var mahjongsCandidated:Box = mahjongsCandidatedArray[Number(currentNumber) - 1];
            // 获取牌序
            var mahjongNames:Array = currentBoutMahjong.split(",");

            // 为出牌玩家设置麻将操作按钮外观
            if (currentNextNumber == localNumber) {
                // 轮到当前玩家出牌时
                currentGame.btnBarMahjongs.visible = true;
                Button(currentGame.btnBarMahjongs.getChildAt(1)).enabled = true;
                if (currentNumber == currentNextNumber) {
                    // 如果消息中指定的发牌玩家序号与下家序号都等于当前玩家，
                    // 即当前玩家最后一次出的牌，在回合中最大，本回合从当前玩家开始
                    currentBoutMahjong = null;
                    Button(currentGame.btnBarMahjongs.getChildAt(1)).enabled = false;
                }
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
            // 有新的获胜者产生，调整当前玩家次序
            var results:Array = event.incomingData.split("~");
            currentNumber = results[0];
            currentNextNumber = results[2];
            // 判断当前玩家是否是获胜者的上家
            if (localNextNumber == currentNumber) {
                // 当前玩家是获胜者的上家时，将当前玩家下家改成获胜者的下家
                localNextNumber = currentNextNumber;
            }
            // 判断当前玩家是否是获胜者下家
            if (currentNextNumber == localNumber) {
                // 当前玩家是否是获胜者下家时，设置标识符
                // isWinnerFollowed = true;
            }
            // 更新画面表现
            gameBringOutHandler(event);
            // 设置游戏获胜者信息
            if (firstPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                firstPlaceNumber = currentNumber;
            } else if (secondPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                secondPlaceNumber = currentNumber;
            } else if (thirdPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                thirdPlaceNumber = currentNumber;
                var placeNumberPattern:RegExp = new RegExp("[" + firstPlaceNumber + secondPlaceNumber + thirdPlaceNumber + "]", "g");
                forthPlaceNumber = Number("1234".replace(placeNumberPattern, ""));
            }
            // TODO DROP THE FOLLOWING DEBUG INFO
//            var placeNumbers:Array = new Array(firstPlaceNumber, secondPlaceNumber, thirdPlaceNumber, forthPlaceNumber);
//            Alert.show("玩家[" + placeNumbers.join(",") + "]胜出！", "消息");
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
            var mahjong:MahjongButton;
            var isGameOver:Boolean = false;
            switch (event.index) {
                case 0:
                    // 胡牌
                    break;
                case 1:
                    // 杠
                    break;
                case 2:
                    // 碰
                    break;
                case 3:
                    // 吃
                    // 选择要出的牌
                    var mahjongs:String = "";
                    for each (mahjong in currentGame.candidatedDown.getChildren()) {
                        if (mahjong.isSelected()) {
                            mahjongs += mahjong.value + ",";
                        }
                    }
                    mahjongs = mahjongs.replace(/,$/, "");
                    // 未作任何选择时，直接退出处理
                    if (mahjongs.length == 0) {
                        return;
                    }
                    // 规则验证
                    if (!PushdownWinGame.isRuleFollowed(mahjongs, currentBoutMahjong)) {
                        itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 0));
                        return;
                    }
                    // 设置出牌结果
                    // 当前剩余的牌数
                    var mahjongsCandicateNumber:int = currentGame.candidatedDown.getChildren().length;
                    // 即将打出的牌数
                    var mahjongsDealedNumber:int = mahjongs.split(",").length;
                    // 打出后剩余牌数
                    var mahjongsLeftNumber:int = mahjongsCandicateNumber - mahjongsDealedNumber;
//                    if (gameSetting > PushdownWinGameSetting.RUSH && gameFinalSettingPlayerNumber != localNumber) {
//                        // 设置游戏冠军玩家
//                        firstPlaceNumber = localNumber;
//                        // 游戏设置为天独或天外天时，且有非独牌者出牌的情况
//                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END, localNumber + "~" + mahjongs + "~" + localNextNumber);
//                        isGameOver = true;
//                    } else if (mahjongsLeftNumber == 0 && (gameSetting == PushdownWinGameSetting.RUSH || gameSetting == PushdownWinGameSetting.DEADLY_RUSH)) {
//                        // 设置游戏冠军玩家
//                        firstPlaceNumber = localNumber;
//                        // 游戏设置为独牌或天独时，且有玩家胜出的情况
//                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END, localNumber + "~" + mahjongs + "~" + localNextNumber);
//                        isGameOver = true;
//                    } else if (mahjongsLeftNumber == 0 && gameSetting == PushdownWinGameSetting.NO_RUSH) {
//                        // 没有独牌或天独或天外天的情况，判断是否还有剩余牌
//                    } else if (mahjongsLeftNumber > 0 || gameSetting == PushdownWinGameSetting.EXTINCT_RUSH) {
//                        // 当前规则下，出牌玩家手中还有剩余牌，并未获胜，正常出牌的情况
//                    } else {
//                        throw Error("其他无法预测的出牌动作！");
//                    }
//                    // 更新客户端麻将显示
//                    currentGame.mahjongsDealedDown.removeAllChildren();
//                    for each (mahjong in currentGame.mahjongsCandidatedDown.getChildren()) {
//                        if (mahjong.isSelected()) {
//                            currentGame.mahjongsCandidatedDown.removeChild(mahjong);
//                            currentGame.mahjongsDealedDown.addChild(mahjong);
//                            mahjong.allowSelect = false;
//                        }
//                    }
                    // 出牌操作结束后，关闭麻将操作栏
                    currentGame.btnBarMahjongs.visible = false;
                    break;
                case 4:
                    // 放弃
                    break;
                case 5:
                    // 摸牌
                    var mahjongRandValue:String = mahjongsSpared.pop();
                    var mahjongRand:MahjongButton = new MahjongButton();
                    mahjongRand.source = "image/mahjong/down/standard/" + mahjongRandValue + ".jpg";
                    ListenerBinder.bind(mahjongRand, FlexEvent.HIDE, function (event:FlexEvent):void {
                        dealMahjong("down", mahjongRand);
                    });
                    currentGame.candidatedDown.addChild(mahjongRand);
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
         * @param direction
         * @param mahjong
         * @return 
         * 
         */
        private function dealMahjong(direction:String, mahjong:MahjongButton):void {
            // 从玩家手中牌删除选中牌
            mahjong.parent.removeChild(mahjong);
            // 获取玩家位置索引
            var playerPosIndex:uint = playerDirection.indexOf(direction);
            // 将牌显示在桌面
            mahjong.allowSelect = false;
            currentGame.dealed.addChild(mahjong);
            mahjong.visible = true;
            socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + mahjong.value + "~" + localNextNumber);
            // 隐藏操作按钮
            currentGame.btnBarMahjongs.visible = false;
        }

        /**
         *
         * 重置参数初始化
         *
         */
        public static function resetInitInfo():void {
            // 参数初始化
            playerCogameNumber = 0;
            gameFinalSettingPlayerNumber = -1;
            currentGameId = null;
            localNumber = 0;
            localNextNumber = 0;
            currentNumber = 0;
            currentBoutMahjong = null;
            currentNextNumber = 0;
            firstPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            secondPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            thirdPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            forthPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            for each (var mahjongsCandidated:Box in mahjongsCandidatedArray) {
                mahjongsCandidated.removeAllChildren();
            }
        }

    }
}