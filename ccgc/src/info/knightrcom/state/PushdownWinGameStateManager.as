package info.knightrcom.state {
    import component.MahjongButton;
    
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.event.GameEvent;
    import info.knightrcom.state.pushdownwingame.PushdownWinGame;
    import info.knightrcom.event.PushdownWinGameEvent;
    import info.knightrcom.util.ListenerBinder;
    import info.knightrcom.util.PlatformAlertEvent;
    
    import mx.containers.Box;
    import mx.containers.Tile;
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.controls.Label;
    import mx.controls.ProgressBarMode;
    import mx.events.FlexEvent;
    import mx.events.ItemClickEvent;
    import mx.states.State;

    /**
     *
     * 红五游戏状态管理器
     *
     */
    public class PushdownWinGameStateManager extends AbstractStateManager {

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
        public static var currentBoutCards:String = null;

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
         * 已发牌区域
         */
        private static var mahjongsDealedArray:Array = null;

        /**
         * 待发牌区域
         */
        private static var mahjongsCandidatedArray:Array = null;

		/**
		 * 计时器
		 */
		private var timer:Timer = new Timer(1000, MAX_CARDS_SELECT_TIME);

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
            currentGame = gameClient.pushdownWinGameModule;
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
                ListenerBinder.bind(socketProxy, GameEvent.GAME_BRING_OUT, gameBringOutHandler);
                ListenerBinder.bind(socketProxy, GameEvent.GAME_STARTED, gameStartedHandler);
                ListenerBinder.bind(socketProxy, GameEvent.GAME_FIRST_PLAY, gameFirstPlayHandler);
                ListenerBinder.bind(socketProxy, GameEvent.GAME_INTERRUPTED, gameInterruptedHandler);
                ListenerBinder.bind(socketProxy, GameEvent.GAME_SETTING_UPDATE, gameSettingUpdateHandler);
                ListenerBinder.bind(socketProxy, GameEvent.GAME_WINNER_PRODUCED, gameWinnerProducedHandler);
                ListenerBinder.bind(socketProxy, GameEvent.GAME_OVER, gameOverHandler);
				timer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void {
					currentGame.timerTip3.setProgress(MAX_CARDS_SELECT_TIME - timer.currentCount, MAX_CARDS_SELECT_TIME);
					currentGame.timerTip3.label = "剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME - timer.currentCount);
					if (timer.currentCount == MAX_CARDS_SELECT_TIME) {
						if (Button(currentGame.btnBarPdwMahjongs.getChildAt(1)).enabled) {
							// 可以选择不要按钮时，则进行不要操作
	                        itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 1));
						} else {
							// 重选
	                        itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 0));
	                        // 选择第一张牌
	                        MahjongButton(currentGame.mahjongsCandidatedDown.getChildAt(0)).setSelected(true);
							// 出牌
	                        itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 3));
						}
					}
				});
                // 可视组件
                ListenerBinder.bind(currentGame.btnBarPdwMahjongs, ItemClickEvent.ITEM_CLICK, itemClick);
                ListenerBinder.bind(currentGame.btnBarPdwMahjongs, FlexEvent.SHOW, show);
                ListenerBinder.bind(currentGame.btnBarPdwMahjongs, FlexEvent.HIDE, hide);
                setInitialized(true);
            }
            // 按照当前玩家序号，进行画面座次安排
            var tempCardsCandidated:Array = new Array(currentGame.mahjongsCandidatedDown, currentGame.mahjongsCandidatedRight, currentGame.mahjongsCandidatedUp, currentGame.mahjongsCandidatedLeft);
            // 进行位移操作
            var index:int = 0;
            // 更改画面组件
            mahjongsDealedArray = new Array(playerCogameNumber);
            mahjongsCandidatedArray = new Array(playerCogameNumber);
            for (index = 0; index < mahjongsCandidatedArray.length; index++) {
                mahjongsCandidatedArray[index] = tempCardsCandidated[index];
            }
            currentGame.btnBarPdwMahjongs.visible = false;
            currentGame.timerTip3.label = "剩余时间：";
		    currentGame.timerTip3.minimum = 0;
            currentGame.timerTip3.maximum = MAX_CARDS_SELECT_TIME;
            currentGame.timerTip3.mode = ProgressBarMode.MANUAL;
        }

        /**
         *
         * 游戏开始时，将系统分配的麻将进行排序
         *
         * @param event
         *
         */
        private function gameStartedHandler(event:PushdownWinGameEvent):void {
            // 显示系统洗牌后的结果，格式为：当前玩家待发牌 + "~" + "0=15;1=15;2=15;3=15"
            var results:Array = event.incomingData.split("~");
            var mahjongSequence:String = results[0];
            var mahjongNames:Array = PushdownWinGame.sortMahjongs(mahjongSequence);
            var mahjong:MahjongButton = null;
            // 为当前玩家发牌
//            for each (var mahjongName:String in mahjongNames) {
//                mahjong = new MahjongButton();
//                mahjong.source = "image/mahjong/" + mahjongName + ".png";
//                currentGame.mahjongsCandidatedDown.addChild(mahjong);
//            }
            // 其他玩家牌数
            var mahjongNumberOfPlayers:String = results[1];
            var index:int = 0;
            while (index != playerCogameNumber) {
                // 跳过当前玩家
                if (localNumber == index + 1) {
                    index++;
                    continue;
                }
                // 获取玩家手中的牌数
                var mahjongNumberPattern:RegExp = new RegExp("^.*" + index + "=(\\d+).*$");
                var mahjongNumber:int = Number(mahjongNumberOfPlayers.replace(mahjongNumberPattern, "$1"));
                // 获取当前玩家待发牌个数
                var mahjongsCandidated:Box = Box(mahjongsCandidatedArray[index]);
                // 为其他玩家发牌，全为牌的背面图案
                for (var i:int = 0; i < mahjongNumber; i++) {
                    mahjong = new MahjongButton();
                    mahjong.source = "image/mahjong/back.png";
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
            // PlatformAlert.show("游戏设置", "信息", PushdownWinGameSetting.getNoRushStyle(), gameSettingSelect);
        }

        /**
         *
         * 发送游戏设置
         *
         * @param event
         *
         */
        private function gameSettingSelect(event:PlatformAlertEvent):void {
//            if (currentGame.currentState != "PushdownWinGame") {
//                return;
//            }
//            // 更新游戏设置已经进行的次数
//            gameSettingUpdateTimes++;
//
//            var setting:int = -1;
//            setting = int(event.detail);
//            if (gameSetting == -1) {
//                // 首次进行游戏设置时，直接发送本次的游戏设置
//                socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
//                gameSetting = setting;
//                gameFinalSettingPlayerNumber = localNumber;
//                if (setting == PushdownWinGameSetting.EXTINCT_RUSH) {
//                    socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING_FINISH, localNumber + "~" + setting);
//                    // 准备出牌
//                    currentGame.btnBarPdwMahjongs.visible = true;
//                    // 首次出牌需要禁用"不要"按键
//                    Button(currentGame.btnBarPdwMahjongs.getChildAt(1)).enabled = false;
//                }
//            } else if (gameSettingUpdateTimes == playerCogameNumber) {
//                // 当前玩家为最后一个玩家时，马上可以开始游戏
//                if (setting != PushdownWinGameSetting.NO_RUSH) {
//                    // 游戏设置为独牌或天独时
//                    socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING_FINISH, localNumber + "~" + setting);
//                    socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
//                    gameSetting = setting;
//                    gameFinalSettingPlayerNumber = localNumber;
//                    // 准备出牌
//                    currentGame.btnBarPdwMahjongs.visible = true;
//                    // 首次出牌需要禁用"不要"按键
//                    Button(currentGame.btnBarPdwMahjongs.getChildAt(1)).enabled = false;
//                } else {
//                    // 游戏设置为不独时
//                    socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING_FINISH, currentNumber + "~" + gameSetting);
//                    socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING, currentNumber + "~" + gameSetting + "~" + localNextNumber);
//                }
//            } else if (setting == PushdownWinGameSetting.NO_RUSH) {
//                // 非首次和末次，不独时，直接转发前次的游戏设置
//                socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING, currentNumber + "~" + gameSetting + "~" + localNextNumber);
//            } else if (setting == PushdownWinGameSetting.RUSH || setting == PushdownWinGameSetting.DEADLY_RUSH) {
//                // 非首次和末次，独牌或天独时，发送本次的游戏设置
//                socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
//                gameSetting = setting;
//                gameFinalSettingPlayerNumber = localNumber;
//            } else if (setting == PushdownWinGameSetting.EXTINCT_RUSH) {
//                socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING_FINISH, localNumber + "~" + gameSetting);
//                // 非首次和末次，天外天时，发送本次的游戏设置
//                socketProxy.sendGameData(PushdownWinGameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
//                gameSetting = setting;
//                gameFinalSettingPlayerNumber = localNumber;
//                // 准备出牌
//                currentGame.btnBarPdwMahjongs.visible = true;
//                // 首次出牌需要禁用"不要"按键
//                Button(currentGame.btnBarPdwMahjongs.getChildAt(1)).enabled = false;
//            }
        }

        /**
         *
         * 游戏设置结束，准备发牌
         *
         * @param event
         *
         */
        private function gameSettingUpdateHandler(event:PushdownWinGameEvent):void {
//            gameSettingUpdateTimes++;
//            var results:Array = event.incomingData.split("~");
//            currentNumber = results[0];
//            if (gameSetting < results[1]) {
//                gameSetting = results[1];
//            }
//            currentNextNumber = results[2];
//            gameFinalSettingPlayerNumber = currentNumber;
//            if (gameSettingUpdateTimes == playerCogameNumber) {
//                // 每个玩家都进行过游戏设置，则可以开始游戏
//                if (localNumber == currentNumber) {
//                    // 游戏设置结束，准备出牌
//                    currentGame.btnBarPdwMahjongs.visible = true;
//                    // 首次出牌需要禁用"不要"按键
//                    Button(currentGame.btnBarPdwMahjongs.getChildAt(1)).enabled = false;
//                }
//            } else if (gameSetting == PushdownWinGameSetting.EXTINCT_RUSH) {
//                // 游戏设置途中有天外天时，等候天独玩家发牌
//            } else if (currentNextNumber == localNumber) {
//                // 当前设置为不独或非最后一个玩家的独牌、天独，则继续进行游戏设置
//                var alertButtons:Array = null;
//                switch (gameSetting) {
//                    case PushdownWinGameSetting.NO_RUSH:
//                        // 当前游戏设置为不独时
//                        alertButtons = PushdownWinGameSetting.getNoRushStyle();
//                        break;
//                    case PushdownWinGameSetting.RUSH:
//                        // 当前游戏设置为独时
//                        alertButtons = PushdownWinGameSetting.getRushStyle();
//                        break;
//                    case PushdownWinGameSetting.DEADLY_RUSH:
//                        // 当前游戏设置天独时
//                        alertButtons = PushdownWinGameSetting.getDeadlyRushStyle();
//                        break;
//                    case PushdownWinGameSetting.EXTINCT_RUSH:
//                        return;
//                }
//                PlatformAlert.show("游戏设置", "信息", alertButtons, gameSettingSelect);
//            }
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
            currentBoutCards = results[1];
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
            // 上局已发牌区域
            var mahjongsDealed:Tile = mahjongsDealedArray[Number(currentNumber) - 1];
            // 获取牌序
            var mahjongNames:Array = currentBoutCards.split(",");
            // 更新发牌玩家的发牌区域
            if (passed) {
                // 上家不要时，显示不要的内容 TODO 间隔玩家？？？
                var currentIndex:int = (currentNextNumber - 1);
                var previousIndex:int = currentIndex == 0 ? playerCogameNumber - 1 : currentIndex - 1;
                var passLabel:Label = new Label();
                passLabel.text = "不要";
                passLabel.setStyle("fontSize", 24);
                Tile(mahjongsDealedArray[previousIndex]).removeAllChildren();
                Tile(mahjongsDealedArray[previousIndex]).addChild(passLabel);
            } else {
                if (isOrderNeighbor(currentNumber, currentNextNumber)) {
                    // 如果牌序中的两个玩家为邻座的两个人，并且上下家顺序为逆时针，则为正常出牌
                    count = mahjongNames.length;
                    while (count-- > 0) {
                        // 从待发牌中移除牌
                        mahjongsCandidated.removeChildAt(0);
                    }
                }
                // 上家出牌时，从已发牌中移除所有牌
                mahjongsDealed.removeAllChildren();
                for each (var mahjongName:String in mahjongNames) {
                    // 向已发牌中添加牌
                    var mahjong:MahjongButton = new MahjongButton();
                    mahjong.allowSelect = false;
                    mahjong.source = "image/mahjong/" + mahjongName + ".png";
                    mahjongsDealed.addChild(mahjong);
                }
            }

            // 全都"不要"时的首发牌，清除桌面上所有牌
            if (currentNumber == currentNextNumber) {
                for each (tempTile in mahjongsDealedArray) {
                    tempTile.removeAllChildren();
                }
            }

            // 为出牌玩家设置麻将操作按钮外观
            if (currentNextNumber == localNumber) {
                // 轮到当前玩家出牌时
                currentGame.btnBarPdwMahjongs.visible = true;
                Button(currentGame.btnBarPdwMahjongs.getChildAt(1)).enabled = true;
                if (currentNumber == currentNextNumber) {
                    // 如果消息中指定的发牌玩家序号与下家序号都等于当前玩家，
                    // 即当前玩家最后一次出的牌，在回合中最大，本回合从当前玩家开始
                    currentBoutCards = null;
                    Button(currentGame.btnBarPdwMahjongs.getChildAt(1)).enabled = false;
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
//            currentBoutCards = results[1];
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
//                var mahjongNames:Array = currentBoutCards.split(",");
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
//                case 0:
//                    // 重选
//                    for each (mahjong in currentGame.mahjongsCandidatedDown.getChildren()) {
//                        mahjong.setSelected(false);
//                    }
//                    break;
//                case 1:
//                    // 不要
//                    if (isWinnerFollowed) {
//                        // 如果当前玩家上家是获胜者时，需要重新设置获胜者发出的消息
//                        // 将获胜者牌更为当前玩家牌，以便在所有玩家“不要”的情况下
//                        // 可以由获胜者的直接下家出牌
//                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + currentBoutCards + "~" + localNextNumber + "~pass");
//                        isWinnerFollowed = false;
//                    } else if (gameSetting == PushdownWinGameSetting.EXTINCT_RUSH && localNextNumber == currentNumber && currentGame.mahjongsCandidatedRight.getChildren().length == 0) {
//                        // 设置游戏冠军玩家
//                        firstPlaceNumber = currentNumber;
//                        // 游戏设置为天外天，且所有非独牌者均不要时
//                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END, currentNumber + "~" + mahjongs + "~" + localNextNumber + "~pass");
//                        isGameOver = true;
//                    } else {
//                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, currentNumber + "~" + currentBoutCards + "~" + localNextNumber + "~pass");
//                        if (currentNumber == localNextNumber) {
//                            // 当前玩家在本回合中不要，且之前所有的玩家均不要的时候
//                            for each (var mahjongsDealed:Tile in mahjongsDealedArray) {
//                                mahjongsDealed.removeAllChildren();
//                            }
//                            currentGame.btnBarPdwMahjongs.visible = false;
//                            return;
//                        }
//                    }
//                    // 在发牌区域显示"不要"标签
//                    var currentIndex:int = (localNumber - 1);
//                    var passLabel:Label = new Label();
//                    passLabel.text = "不要";
//                    passLabel.setStyle("fontSize", 24);
//                    Tile(mahjongsDealedArray[currentIndex]).removeAllChildren();
//                    Tile(mahjongsDealedArray[currentIndex]).addChild(passLabel);
//                    // 出牌操作结束后，关闭麻将操作栏
//                    currentGame.btnBarPdwMahjongs.visible = false;
//                    break;
//                case 2:
//                    // 提示
//                    break;
//                case 3:
//                    // 出牌
//                    // 选择要出的牌
//                    var mahjongs:String = "";
//                    for each (mahjong in currentGame.mahjongsCandidatedDown.getChildren()) {
//                        if (mahjong.isSelected()) {
//                            mahjongs += mahjong.value + ",";
//                        }
//                    }
//                    mahjongs = mahjongs.replace(/,$/, "");
//                    // 未作任何选择时，直接退出处理
//                    if (mahjongs.length == 0) {
//                        return;
//                    }
//                    // 规则验证
//                    if (!PushdownWinGame.isRuleFollowed(mahjongs, currentBoutCards)) {
//                        itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 0));
//                        return;
//                    }
//                    // 设置出牌结果
//                    // 当前剩余的牌数
//                    var mahjongsCandicateNumber:int = currentGame.mahjongsCandidatedDown.getChildren().length;
//                    // 即将打出的牌数
//                    var mahjongsDealedNumber:int = mahjongs.split(",").length;
//                    // 打出后剩余牌数
//                    var mahjongsLeftNumber:int = mahjongsCandicateNumber - mahjongsDealedNumber;
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
//                        if (firstPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
//                            // 第一名未产生时，设置firstPlace
//                            firstPlaceNumber = localNumber;
//                            // 要出的牌数与剩余牌数相同时，发送获胜信息
//                            socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN, localNumber + "~" + mahjongs + "~" + localNextNumber);
//                        } else if (secondPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
//                            // 第二名未产生时，设置secondPlace
//                            secondPlaceNumber = localNumber;
//                            // 如果是secondPlace，则发生获胜以及游戏结束信息
//                            socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN, localNumber + "~" + mahjongs + "~" + localNextNumber);
//                        } else if (thirdPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
//                            // 第三名未产生时，设置thirdPlace
//                            thirdPlaceNumber = localNumber;
//                            // 设置forthPlace
//                            var placePattern:RegExp = new RegExp("[abc]".replace(/a/, firstPlaceNumber).replace(/b/, secondPlaceNumber).replace(/c/, thirdPlaceNumber), "g");
//                            forthPlaceNumber = int("1234".replace(placePattern, ""));
//                            // 如果是thirdPlace，则发生获胜以及游戏结束信息
//                            socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END, localNumber + "~" + mahjongs + "~" + localNextNumber);
//                            isGameOver = true;
//                        }
//                        if (!isGameOver) {
//                            var placeNumbers:Array = new Array(firstPlaceNumber, secondPlaceNumber, thirdPlaceNumber, forthPlaceNumber);
//                            // Alert.show("玩家[" + placeNumbers.join(",") + "]胜出！", "消息");
//                        }
//                    } else if (mahjongsLeftNumber > 0 || gameSetting == PushdownWinGameSetting.EXTINCT_RUSH) {
//                        // 当前规则下，出牌玩家手中还有剩余牌，并未获胜，正常出牌的情况
//                        // 或者是天外天时，独牌者进行发牌
//                        if (isWinnerFollowed) {
//                            // 没有独牌或天独，并且第一个获胜者牌最大
//                            // 构造出牌数据，当前玩家序号~牌名,牌名...~下家玩家序号
//                            socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + mahjongs + "~" + localNextNumber);
//                            isWinnerFollowed = false;
//                        } else {
//                            // 构造出牌数据，当前玩家序号~牌名,牌名...~下家玩家序号
//                            socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + mahjongs + "~" + localNextNumber);
//                        }
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
//                    // 出牌操作结束后，关闭麻将操作栏
//                    currentGame.btnBarPdwMahjongs.visible = false;
//                    break;
            }
        }

		/**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
		 * 
		 */
		private function show(event:FlexEvent):void {
			// 显示进度条，倒计时开始开始
            currentGame.timerTip3.setProgress(MAX_CARDS_SELECT_TIME, MAX_CARDS_SELECT_TIME);
			currentGame.timerTip3.label = "剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME);
			currentGame.timerTip3.visible = true;
			timer.start();
		}

		/**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
		 * 
		 */
		private function hide(event:FlexEvent):void {
			// 进度条隐藏，并重置计时器
			currentGame.timerTip3.visible = false;
			timer.reset();
		}

        /**
         *
         * 判断两个玩家是否为逆时针顺序紧挨着的
         *
         * @param previousNumber
         * @param nextNumber
         *
         */
        private function isOrderNeighbor(number:int, nextNumber:int):Boolean {
            var initOrder:String = "1234";
            if (firstPlaceNumber != UNOCCUPIED_PLACE_NUMBER) {
                initOrder = initOrder.replace(new RegExp(firstPlaceNumber, "g"), "");
            }
            if (secondPlaceNumber != UNOCCUPIED_PLACE_NUMBER) {
                initOrder = initOrder.replace(new RegExp(secondPlaceNumber, "g"), "");
            }
            if (thirdPlaceNumber != UNOCCUPIED_PLACE_NUMBER) {
                Alert.show("isOrderNeighbor[thirdPlaceNumber != UNOCCUPIED_PLACE_NUMBER]");
            }
            // 取得索引号
            var index:int = initOrder.indexOf(String(number));
            var nextIndex:int = initOrder.indexOf(String(nextNumber));
            if (initOrder.length == 2) {
                return true;
            }
            // 计算所有间隔
            var indexInterval:int = nextIndex - index;
            return (indexInterval == 1 || indexInterval == 1 - initOrder.length);
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
            currentBoutCards = null;
            currentNextNumber = 0;
            firstPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            secondPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            thirdPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            forthPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            for each (var mahjongsDealed:Tile in mahjongsDealedArray) {
                mahjongsDealed.removeAllChildren();
            }
            for each (var mahjongsCandidated:Box in mahjongsCandidatedArray) {
                mahjongsCandidated.removeAllChildren();
            }
        }

    }
}