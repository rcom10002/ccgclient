package info.knightrcom.state {
    import component.PokerButton;
    import component.Scoreboard;
    
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.assets.PokerResource;
    import info.knightrcom.assets.Red5GameResource;
    import info.knightrcom.command.Red5GameCommand;
    import info.knightrcom.event.GameEvent;
    import info.knightrcom.event.Red5GameEvent;
    import info.knightrcom.puppet.GamePinocchioEvent;
    import info.knightrcom.service.LocalPlayerProfileService;
    import info.knightrcom.state.red5game.Red5Game;
    import info.knightrcom.state.red5game.Red5GameBox;
    import info.knightrcom.state.red5game.Red5GameSetting;
    import info.knightrcom.util.HttpServiceProxy;
    import info.knightrcom.util.ListenerBinder;
    import info.knightrcom.util.PlatformAlert;
    import info.knightrcom.util.PlatformAlertEvent;
    
    import mx.containers.Box;
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.controls.ButtonBar;
    import mx.controls.Image;
    import mx.controls.ProgressBarMode;
    import mx.core.Container;
    import mx.events.FlexEvent;
    import mx.events.ItemClickEvent;
    import mx.managers.CursorManager;
    import mx.rpc.events.ResultEvent;
    import mx.states.State;

    /**
     *
     * 红五游戏状态管理器
     *
     */
    public class Red5GameStateManager extends AbstractGameStateManager {

        /**
         * 游戏中玩家的个数
         */
        public static var playerCogameNumber:int;

        /**
         * 游戏设置：
         * 0、不独
         * 1、独牌
         * 2、天独
         * 3、天外天
         */
        public static var gameSetting:int = -1;

        /**
         * 游戏的最终设置所对应的玩家编号
         */
        public static var gameFinalSettingPlayerNumber:int = -1;

        /**
         * 游戏设置更新次数
         */
        public static var gameSettingUpdateTimes:int = 0;

        /**
         * 当前游戏id
         */
        public static var currentGameId:String;

        /**
         * 当前玩家序号
         */
        public static var firstPlayerNumber:int;

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
		private static const MAX_CARDS_SELECT_TIME:int = 20;

        /**
         * 是否是第一个获胜者的下家
         */
        public static var isWinnerFollowed:Boolean = false;

        /**
         * 已发牌区域
         */
        private static var cardsDealedArray:Array = null;
        
        /**
         * 首次发牌提示区域
         */
        private static var cardsCandidatedTipArray:Array = null;

        /**
         * 待发牌区域
         */
        private static var cardsCandidatedArray:Array = null;

		/**
		 * 计时器
		 */
		private static var timer:Timer = new Timer(1000, MAX_CARDS_SELECT_TIME);

        /**
         * 计时器(用于显示其他玩家出牌所用时间)
         */
        private static var otherTimer:Timer = new Timer(1000, MAX_CARDS_SELECT_TIME);

        /**
         * 当前游戏模块
         */
		private static var currentGame:CCGameRed5 = null;

		/**
		 * 游戏内存模型
		 */
		private static var pokerBox:Red5GameBox;

		/**
		 * 玩家当前的游戏积分
		 */
		private static var myScore:Number = 0;

        /**
         *
         * @param socketProxy
         * @param gameClient
         * @param myState
         *
         */
        public function Red5GameStateManager(socketProxy:GameSocketProxy, myState:State):void {
            super(socketProxy, myState);
            ListenerBinder.bind(myState, FlexEvent.ENTER_STATE, init);
            batchBindGameEvent(Red5GameEvent.EVENT_TYPE, new Array(
                    GameEvent.GAME_WAIT, gameWaitHandler,
                    GameEvent.GAME_CREATE, gameCreateHandler,
            		GameEvent.GAME_STARTED, gameStartedHandler,
            		GameEvent.GAME_FIRST_PLAY, gameFirstPlayHandler,
                    GameEvent.GAME_SETTING_UPDATE, gameSettingUpdateHandler,
                    GameEvent.GAME_SETTING_OVER, gameSettingOverHandler,
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
                currentGame = gameClient.red5GameModule;
                // 配置事件监听
                // 注册非可视组件监听事件
                ListenerBinder.bind(timer, TimerEvent.TIMER, function(event:TimerEvent):void {
                    // 倒计时开始
                    currentGame.timerTip.label = "计时开始";
                    if (currentGame.candidatedTipDownExt.numChildren > 0) {
                        (currentGame.candidatedTipDownExt.getChildAt(0) as GameWaiting).tipText = String(MAX_CARDS_SELECT_TIME - timer.currentCount);
                    } else {
                        var gameWaitingClock:GameWaiting = new GameWaiting();
                        gameWaitingClock.tipText = String(MAX_CARDS_SELECT_TIME - timer.currentCount);
                        currentGame.candidatedTipDownExt.addChild(gameWaitingClock);
                    }
                    // 自动放弃缩短至3秒
                    if (currentGame.btnBarPokers.visible && Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled) {
                        // 当前玩家出牌时
                        var brainpowerTips:Array = Red5Game.getBrainPowerTip(
                                currentGame.candidatedDown.getChildren().join(",").split(","), currentBoutCards.split(","));
                        if (brainpowerTips === null) {
                            currentGame.timerTip.label = "智能放弃【" + timer.currentCount + "】";
                            if (timer.currentCount == 3) {
                                // 可以选择不要按钮时，则进行不要操作
                                itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, Red5Game.OPTR_GIVEUP));
                            }
                            currentGame.candidatedTipDownExt.removeAllChildren();
                            return;
                        }
                    }
                    // 常规计时
                    currentGame.timerTip.setProgress(MAX_CARDS_SELECT_TIME - timer.currentCount, MAX_CARDS_SELECT_TIME);
                    currentGame.timerTip.label = "剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME - timer.currentCount);
                    if (currentGame.btnBarPokers.visible && timer.currentCount == MAX_CARDS_SELECT_TIME) {
                        // 当前玩家出牌时
                        if (Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled) {
                            // 可以选择不要按钮时，则进行不要操作
                            itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, Red5Game.OPTR_GIVEUP));
                        } else {
                            // 重选
                            itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, Red5Game.OPTR_RESELECT));
                            // 选择第一张牌
                            PokerButton(currentGame.candidatedDown.getChildAt(0)).setSelected(true);
                            // 出牌
                            itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, Red5Game.OPTR_DISCARD));
                        }
                        currentGame.candidatedTipDownExt.removeAllChildren();
                    }
                });
                ListenerBinder.bind(otherTimer, TimerEvent.TIMER, function(e:TimerEvent):void {
                    if (currentGame.btnBarPokers.visible) {
                        return;
                    }
                    var otherGameWaitingClockParent:Container = Container(cardsDealedArray[currentNextNumber - 1]);
                    var lastChildIndex:int = otherGameWaitingClockParent.numChildren - 1;
                    if (otherGameWaitingClockParent.numChildren > 0 && otherGameWaitingClockParent.getChildAt(lastChildIndex) is GameWaiting) {
                        GameWaiting(otherGameWaitingClockParent.getChildAt(lastChildIndex)).tipText = String(MAX_CARDS_SELECT_TIME - otherTimer.currentCount);// Label(otherGameWaitingClockParent.getChildAt(lastChildIndex)).text.replace(/【\d+】/g, "【#】".replace(/#/, String(MAX_CARDS_SELECT_TIME - otherTimer.currentCount)));
                    }
                });
                // 注册可视组件监听事件
                ListenerBinder.bind(currentGame.btnBarPokers, ItemClickEvent.ITEM_CLICK, itemClick);
                ListenerBinder.bind(currentGame.btnBarPokers, FlexEvent.SHOW, show);
                ListenerBinder.bind(currentGame.btnBarPokers, FlexEvent.HIDE, hide);
                ListenerBinder.bind(currentGame.btnBarPokersTipA, ItemClickEvent.ITEM_CLICK, btnBarPokersTipHandler);
                ListenerBinder.bind(currentGame.btnBarPokersTipB, ItemClickEvent.ITEM_CLICK, btnBarPokersTipHandler);
                ListenerBinder.bind(currentGame.btnBarPokersTipC, ItemClickEvent.ITEM_CLICK, btnBarPokersTipHandler);
                
                ListenerBinder.bind(currentGame, FlexEvent.UPDATE_COMPLETE, function (event:Event):void {
                    var eachButton:Button = null;
                    for each (var eachBar:ButtonBar in [currentGame.btnBarPokersTipA, 
                                                        currentGame.btnBarPokersTipB, 
                                                        currentGame.btnBarPokersTipC]) {
                            for each (eachButton in eachBar.getChildren()) {
                                eachButton.styleName = "gameButton";
                            }
                        }
                    for each (eachButton in currentGame.btnBarPokers.getChildren()) {
                        eachButton.styleName = "gameBigButton";
                    }
                });
                
                // 调整画面布局
                currentGame.setChildIndex(currentGame.bgLaceLeft, 0);
                currentGame.setChildIndex(currentGame.bgLaceRight, 0);
                currentGame.setChildIndex(currentGame.bgLogo, 0);
                currentGame.setChildIndex(currentGame.bgCurtainLeft, 0);
                currentGame.setChildIndex(currentGame.bgCurtainRight, 0);
                for each (var eachContainer:Container in cardsCandidatedTipArray) {
                    currentGame.setChildIndex(eachContainer, currentGame.numChildren - 1);
                }
                currentGame.setChildIndex(currentGame.timerTip, currentGame.numChildren - 1);
                currentGame.setChildIndex(currentGame.infoBoard, currentGame.numChildren - 1);
                currentGame.setChildIndex(currentGame.infoBoardText, currentGame.numChildren - 1);
                
                setInitialized(true);
            }
            // 按照当前玩家序号，进行画面座次安排
            var tempCardsDealed:Array = new Array(currentGame.dealedDown, currentGame.dealedRight, currentGame.dealedUp, currentGame.dealedLeft);
            var tempCardsCandidatedTip:Array = new Array(currentGame.candidatedTipDown, currentGame.candidatedTipRight, currentGame.candidatedTipUp, currentGame.candidatedTipLeft);
            var tempCardsCandidated:Array = new Array(currentGame.candidatedDown, currentGame.candidatedRight, currentGame.candidatedUp, currentGame.candidatedLeft);
            // 进行位移操作
            var index:int = 0;
            while (index != localNumber - 1) {
                var temp:Object = tempCardsDealed.pop();
                tempCardsDealed.unshift(temp);
                temp = tempCardsCandidatedTip.pop();
                tempCardsCandidatedTip.unshift(temp);
                temp = tempCardsCandidated.pop();
                tempCardsCandidated.unshift(temp);
                index++;
            }
            // 更改画面组件
            cardsDealedArray = new Array(playerCogameNumber);
            for (index = 0; index < cardsDealedArray.length; index++) {
                cardsDealedArray[index] = tempCardsDealed[index];
            }
            cardsCandidatedTipArray = new Array(playerCogameNumber);
            for (index = 0; index < cardsCandidatedTipArray.length; index++) {
                cardsCandidatedTipArray[index] = tempCardsCandidatedTip[index];
            }
            cardsCandidatedArray = new Array(playerCogameNumber);
            for (index = 0; index < cardsCandidatedArray.length; index++) {
                cardsCandidatedArray[index] = tempCardsCandidated[index];
            }
            // 数据初始化
            currentGame.btnBarPokers.visible = false;
            currentGame.btnBarPokersTipA.visible = false;
            currentGame.btnBarPokersTipB.visible = false;
            currentGame.btnBarPokersTipC.visible = false;
            currentGame.timerTip.label = "剩余时间：";
		    currentGame.timerTip.minimum = 0;
            currentGame.timerTip.maximum = MAX_CARDS_SELECT_TIME;
            currentGame.timerTip.mode = ProgressBarMode.MANUAL;
        }

        /**
         *
         * 游戏开始时，将系统分配的扑克进行排序
         *
         * @param event
         *
         */
        private function gameStartedHandler(event:Red5GameEvent):void {
            // 更新配对提示
            gameClient.progressBarMatching.visible = false;
            gameClient.progressBarMatching.setProgress(0, 100);
            gameClient.progressBarMatching.indeterminate = true;
            // 显示系统洗牌后的结果，格式为：当前玩家待发牌 + "~" + "0=15;1=15;2=15;3=15"
            var results:Array = event.incomingData.split("~");
            var cardSequence:String = results[0];
            var cardNames:Array = Red5Game.sortPokers(cardSequence);
            var poker:PokerButton = null;
            // 为当前玩家发牌
            for each (var cardName:String in cardNames) {
                poker = new PokerButton();
                poker.source = PokerResource.load(cardName);
                currentGame.candidatedDown.addChild(poker);
            }
            // 其他玩家牌数
            var pokerNumberOfPlayers:String = results[1];
            var index:int = 0;
            while (index != playerCogameNumber) {
                // 跳过当前玩家
                if (localNumber == index + 1) {
                    index++;
                    continue;
                }
                // 获取玩家手中的牌数
                var pokerNumberPattern:RegExp = new RegExp("^.*" + index + "=(\\d+).*$");
                var pokerNumber:int = Number(pokerNumberOfPlayers.replace(pokerNumberPattern, "$1"));
                // 获取当前玩家待发牌个数
                var cardsCandidated:Box = Box(cardsCandidatedArray[index]);
                // 为其他玩家发牌，全为牌的背面图案
                for (var i:int = 0; i < pokerNumber; i++) {
                    poker = new PokerButton();
                    poker.source = PokerResource.load("back");
                    poker.allowSelect = false;
                    cardsCandidated.addChild(poker);
                }
                index++;
            }
            // 显示当前玩家积分
            HttpServiceProxy.send(
        			LocalPlayerProfileService.READ_PLAYER_PROFILE, 
            		{PROFILE_ID : BaseStateManager.currentProfileId}, 
            		null, 
            		function (e:ResultEvent):void {
		            	var e4x:XML = new XML(e.result);
		            	myScore = Number(e4x.entity.currentScore.text());
                        currentGame.infoBoardText.text = "我的当前积分：" + myScore;						// 少于500分时设置警戒色
						if (myScore < 500) {
							currentGame.infoBoardText.setStyle("color", "red");
						} else {
							currentGame.infoBoardText.setStyle("color", "white");
						}
            		}
            );
            this._myPuppet.dispatchEvent(new GamePinocchioEvent(
                GamePinocchioEvent.GAME_START, 
                null, 
                currentGame.candidatedDown.getChildren()));
//            // 七独八天判断
//            var myCards:String = currentGame.candidatedDown.getChildren().join(",");
//            // 去除5、大小王
//            myCards = myCards.replace(/0VX|0VY|\dV5/g, "").replace(",{2,}", ",").replace(/^,|,$/g, "");
//            if (/\d(V[^,]*)(,\1){6}/.test(myCards)) {
//                // 七独
//                socketProxy.sendGameData(Red5GameCommand.GAME_DEADLY7_EXTINCT8, localNumber + "~" + myCards.match(/\d(V[^,]*)(,\1){6}/)[0]);
//            } else if (/(\dV\d*)(,\1){7}/.test(myCards)) {
//                // 八天
//                socketProxy.sendGameData(Red5GameCommand.GAME_DEADLY7_EXTINCT8, localNumber + "~" + myCards.match(/(\dV\d*)(,\1){7}/)[0]);
//            }
        }

        /**
         * 
         * 七独八天
         * 
         * @param event
         * 
         */
        private function gameDeadly7Extinct8Handler(event:Red5GameEvent):void {
            var results:Array = event.incomingData.split("~");
            
        }

        /**
         *
         * 当前玩家为第一个发牌者时，开始进行游戏设置
         *
         * @param event
         *
         */
        private function gameFirstPlayHandler(event:Red5GameEvent):void {
            var results:Array = new Array(event.incomingData.substr(0, 1), event.incomingData.substring(2));
            firstPlayerNumber = parseInt(results[0]);
            results[1] = results[1].toString().replace(/~[^~]+;$/, "");
            var initCardsOfPlayers:Array = results[1].toString().split(/~[^~]+;/g);
        	pokerBox = new Red5GameBox();
        	pokerBox.cardsOfPlayers = initCardsOfPlayers;
            var playerDirection:Array = new Array("下", "右", "上", "左");
            var index:int = 0;
            while (index != localNumber - 1) {
                var temp:Object = null;
                temp = playerDirection.pop();
                playerDirection.unshift(temp);
                index++;
            }
            // 设置红十标记
//            var poker:PokerButton = new PokerButton();
//            poker.allowSelect = false;
//            poker.source = PokerResource.load("1V10");
            var firstPoker:Image = new Image();
            firstPoker.source = Red5GameResource.FIRST_POKER_TIP;
            (cardsCandidatedTipArray[firstPlayerNumber - 1] as Box).addChild(firstPoker);
            if (firstPlayerNumber == localNumber) {
                this._myPuppet.gameBox = pokerBox;
				this._myPuppet.dispatchEvent(new GamePinocchioEvent(
					GamePinocchioEvent.GAME_SETTING, 
					null, 
					PlatformAlert.show("10", "信息", Red5GameSetting.getNoRushStyle(), gameSettingSelect)));
            }
            updateOtherTip(-1, firstPlayerNumber, firstPlayerNumber != localNumber);
        }

        /**
         *
         * 发送游戏设置
         *
         * @param event
         *
         */
        private function gameSettingSelect(event:PlatformAlertEvent):void {
            if (gameClient.currentState != "RED5GAME") {
                return;
            }
            // 更新游戏设置已经进行的次数
            gameSettingUpdateTimes++;

            var setting:int = -1;
            setting = int(event.detail);
            if (gameSetting == -1) {
                // 首次进行游戏设置时，直接发送本次的游戏设置
                socketProxy.sendGameData(Red5GameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
                gameSetting = setting;
                gameFinalSettingPlayerNumber = localNumber;
                if (setting == Red5GameSetting.EXTINCT_RUSH) {
                    socketProxy.sendGameData(Red5GameCommand.GAME_SETTING_FINISH, localNumber + "~" + setting);
//                    // 准备出牌
//                    currentGame.btnBarPokers.visible = true;
//                    // 首次出牌需要禁用"不要"按键
//                    Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled = false;
                }
                updateOtherTip(localNumber, localNextNumber);
            } else if (gameSettingUpdateTimes == playerCogameNumber) {
                // 当前玩家为最后一个玩家时，马上可以开始游戏
                if (setting != Red5GameSetting.NO_RUSH) {
                    // 游戏设置为独牌或天独时
                    socketProxy.sendGameData(Red5GameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
                    socketProxy.sendGameData(Red5GameCommand.GAME_SETTING_FINISH, localNumber + "~" + setting);
                    gameSetting = setting;
                    gameFinalSettingPlayerNumber = localNumber;
//                    // 准备出牌
//                    currentGame.btnBarPokers.visible = true;
//                    // 首次出牌需要禁用"不要"按键
//                    Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled = false;
                } else {
                    // 游戏设置为不独时
                    socketProxy.sendGameData(Red5GameCommand.GAME_SETTING, currentNumber + "~" + gameSetting + "~" + localNextNumber);
                    socketProxy.sendGameData(Red5GameCommand.GAME_SETTING_FINISH, currentNumber + "~" + gameSetting);
                    updateOtherTip(currentNumber, gameFinalSettingPlayerNumber);
                }
            } else if (setting == Red5GameSetting.NO_RUSH) {
                // 非首次和末次，不独时，直接转发前次的游戏设置
                socketProxy.sendGameData(Red5GameCommand.GAME_SETTING, currentNumber + "~" + gameSetting + "~" + localNextNumber);
                updateOtherTip(currentNumber, localNextNumber);
            } else if (setting == Red5GameSetting.RUSH || setting == Red5GameSetting.DEADLY_RUSH) {
                // 非首次和末次，独牌或天独时，发送本次的游戏设置
                socketProxy.sendGameData(Red5GameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
                gameSetting = setting;
                gameFinalSettingPlayerNumber = localNumber;
                updateOtherTip(localNumber, localNextNumber);
            } else if (setting == Red5GameSetting.EXTINCT_RUSH) {
                // 非首次和末次，天外天时，发送本次的游戏设置
                socketProxy.sendGameData(Red5GameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
                socketProxy.sendGameData(Red5GameCommand.GAME_SETTING_FINISH, localNumber + "~" + setting);
                gameSetting = setting;
                gameFinalSettingPlayerNumber = localNumber;
//                // 准备出牌
//                currentGame.btnBarPokers.visible = true;
//                // 首次出牌需要禁用"不要"按键
//                Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled = false;
            }
        }

        /**
         *
         * 游戏设置更新
         *
         * @param event
         *
         */
        private function gameSettingUpdateHandler(event:Red5GameEvent):void {
            gameSettingUpdateTimes++;
            var results:Array = event.incomingData.split("~");
            currentNumber = results[0];
            if (gameSetting < results[1]) {
                gameSetting = results[1];
            }
            gameFinalSettingPlayerNumber = currentNumber;
            currentNextNumber = (gameSettingUpdateTimes == playerCogameNumber ? gameFinalSettingPlayerNumber : results[2]);
            if (gameSettingUpdateTimes == playerCogameNumber) {
//                // 每个玩家都进行过游戏设置，则可以开始游戏
//                if (localNumber == currentNumber) {
//                    // 游戏设置结束，准备出牌
//                    currentGame.btnBarPokers.visible = true;
//                    // 首次出牌需要禁用"不要"按键
//                    Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled = false;
//                }
            } else if (gameSetting == Red5GameSetting.EXTINCT_RUSH) {
                // 游戏设置途中有天外天时，等候天独玩家发牌
                currentNextNumber = gameFinalSettingPlayerNumber;
            } else if (currentNextNumber == localNumber) {
                // 当前设置为不独或非最后一个玩家的独牌、天独，则继续进行游戏设置
                var alertButtons:Array = null;
                switch (gameSetting) {
                    case Red5GameSetting.NO_RUSH:
                        // 当前游戏设置为不独时
                        alertButtons = Red5GameSetting.getNoRushStyle();
                        break;
                    case Red5GameSetting.RUSH:
                        // 当前游戏设置为独时
                        alertButtons = Red5GameSetting.getRushStyle();
                        break;
                    case Red5GameSetting.DEADLY_RUSH:
                        // 当前游戏设置天独时
                        alertButtons = Red5GameSetting.getDeadlyRushStyle();
                        break;
                    case Red5GameSetting.EXTINCT_RUSH:
                        return;
                }
                this._myPuppet.gameBox = pokerBox;
				this._myPuppet.dispatchEvent(new GamePinocchioEvent(
					GamePinocchioEvent.GAME_SETTING, 
					null, 
					PlatformAlert.show("10", "信息", alertButtons, gameSettingSelect)));
            }
            // 从画面中清除已经使用过的倒计时
            for each (var eachDealed:Container in cardsDealedArray) {
                eachDealed.removeAllChildren();
            }
            updateOtherTip(currentNumber, currentNextNumber, currentNextNumber != localNumber);
        }

        /**
         *
         * 响应游戏设置结束事件
         *
         * @param event
         *
         */
        private function gameSettingOverHandler(event:Red5GameEvent):void {
            var results:Array = event.incomingData.split("~");
            gameFinalSettingPlayerNumber = results[0];
            currentNumber = results[0];
            gameSetting = results[1];
            // 每个玩家都进行过游戏设置，则可以开始游戏
            if (localNumber == currentNumber) {
                // 游戏设置结束，准备出牌
                currentGame.btnBarPokers.visible = true;
                // 首次出牌需要禁用"不要"按键
                Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled = false;
            }
            if (gameSetting == Red5GameSetting.NO_RUSH) {
                // 非独牌时
                updateOtherTip(-1, gameFinalSettingPlayerNumber, gameFinalSettingPlayerNumber != localNumber);
            } else {
                // 独牌时，添加独牌提示图标
                var gameSettingImage:Image = new Image();
                switch (gameSetting) {
                    case Red5GameSetting.RUSH:
                        gameSettingImage.source = Red5GameResource.RUSH;
                        break;
                    case Red5GameSetting.DEADLY_RUSH:
                        gameSettingImage.source = Red5GameResource.DEADLY_RUSH;
                        break;
                    case Red5GameSetting.EXTINCT_RUSH:
                        gameSettingImage.source = Red5GameResource.EXTINCT_RUSH;
                        break;
                }
                (cardsCandidatedTipArray[gameFinalSettingPlayerNumber - 1] as Container).addChild(gameSettingImage);
            }
            // updateOtherTip(-1, gameFinalSettingPlayerNumber, gameFinalSettingPlayerNumber != localNumber);
        }

        /**
         *
         * 接收到系统通知当前玩家出牌的消息，数据格式为：当前玩家序号~牌名,牌名...~下家玩家序号
         *
         * @param event
         *
         */
        private function gameBringOutHandler(event:Red5GameEvent):void {
            // 接收上家出牌序列，显示出牌结果
            var results:Array = event.incomingData.split("~");
            currentNumber = results[0];
            currentBoutCards = results[1];
            currentNextNumber = results[2];
            var passed:Boolean = false;
            var count:int = 0;
            var tempTile:Container = null;

            // 在桌面上显示最近新出的牌
            if (results.length == 5) {
                // 获取"不要"标识
                passed = ("pass" == results[3]);
            }
            // 上局待发牌区域
            var cardsCandidated:Box = cardsCandidatedArray[currentNumber - 1];
            // 上局已发牌区域
            var cardsDealed:Container = cardsDealedArray[currentNumber - 1];
            // 获取牌序
            var cardNames:Array = currentBoutCards.split(",");
            // 更新发牌玩家的发牌区域
            if (passed) {
                // 上家不要时，显示不要的内容 TODO 间隔玩家？？？
//                var currentIndex:int = (currentNextNumber - 1);
//                var previousIndex:int = currentIndex == 0 ? playerCogameNumber - 1 : currentIndex - 1;
                var previousIndex:int = parseInt(results[4]) - 1;
//                var passLabel:Label = new Label();
//                passLabel.text = "PASS";
//                passLabel.setStyle("fontSize", 24);
                var passImage:Image = new Image();
                passImage.source = Red5GameResource.PASS;
                Container(cardsDealedArray[previousIndex]).removeAllChildren();
                Container(cardsDealedArray[previousIndex]).addChild(passImage);
            } else {
                if (isOrderNeighbor(currentNumber, currentNextNumber)) { // TODO THIS METHOD MAY BE USELESS
                    // 如果牌序中的两个玩家为邻座的两个人，并且上下家顺序为逆时针，则为正常出牌
                    count = cardNames.length;
                    while (count-- > 0) {
                        // 从待发牌中移除牌
                        cardsCandidated.removeChildAt(0);
                    }
                }
                // 上家出牌或是首次发牌时，从已发牌中移除所有牌
                cardsDealed.removeAllChildren();
                for each (var cardName:String in cardNames) {
                    // 向已发牌中添加牌
                    var poker:PokerButton = new PokerButton();
                    poker.allowSelect = false;
                    poker.source = PokerResource.load(cardName);
                    cardsDealed.addChild(poker);
                    // 更新内存模型
                    pokerBox.exportPoker(currentNumber - 1, cardName);
                }
            }
// 2009/10/13 该功能可能需要保留
//            // 全都"不要"时的首发牌，清除桌面上所有牌
//            if (currentNumber == currentNextNumber) {
//                for each (tempTile in cardsDealedArray) {
//                    tempTile.removeAllChildren();
//                }
//            }

            // 为出牌玩家设置扑克操作按钮外观
            if (currentNextNumber == localNumber) {
                // 轮到当前玩家出牌时
                currentGame.btnBarPokers.visible = true;
                Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled = true;
                if (currentNumber == currentNextNumber) {
                    // 如果消息中指定的发牌玩家序号与下家序号都等于当前玩家，
                    // 即当前玩家最后一次出的牌，在回合中最大，本回合从当前玩家开始
                    currentBoutCards = null;
                    Button(currentGame.btnBarPokers.getChildAt(Red5Game.OPTR_GIVEUP)).enabled = false;
                }
            }

            // 更新显示提示
            updateOtherTip(currentNumber, currentNextNumber, !currentGame.btnBarPokers.visible);
        }

        /**
         *
         * 接收到当前玩家为第一个发牌者通知
         *
         * @param event
         *
         */
        private function gameInterruptedHandler(event:Red5GameEvent):void {
            this._myPuppet.dispatchEvent(new GamePinocchioEvent(GamePinocchioEvent.GAME_END, null));
            gameClient.currentState = "LOBBY";
            gameClient.txtSysMessage.text += "游戏中断！请重新加入游戏！\n";
            CursorManager.removeBusyCursor();
        }

        /**
         *
         * 游戏结束
         *
         * @param event
         *
         */
        private function gameOverHandler(event:Red5GameEvent):void {
            // 格式：发前玩家~牌序~接牌玩家
            var results:Array = event.incomingData.split("~");
            currentNumber = results[0];
            currentBoutCards = results[1];
            currentNextNumber = results[2];
            var scoreboardInfo:Array = String(results[results.length - 1]).split(/;/);
            // 非出牌者时，移除桌面上显示的已出的牌，在桌面上显示最近新出的牌
            // if (localNumber != currentNumber && gameSetting != Red5GameSetting.EXTINCT_RUSH) {
            if (localNumber != currentNumber && isOrderNeighbor(currentNumber, currentNextNumber)) {
                // 本局待发牌区域
                var cardsCandidated:Box = cardsCandidatedArray[currentNumber - 1];
                // 本局已发牌区域
                var cardsDealed:Container = cardsDealedArray[currentNumber - 1];
                cardsDealed.removeAllChildren();
                var cardNames:Array = currentBoutCards.split(",");
                for each (var cardName:String in cardNames) {
                    // 为发牌区域添加已经发出的牌
                    var poker:PokerButton = new PokerButton();
                    poker.allowSelect = false;
                    poker.source = PokerResource.load(cardName);
                    cardsDealed.addChild(poker);
                    // 从待发牌区域移除已经发出的牌
                    cardsCandidated.removeChildAt(0);
                    // 更新内存
                    pokerBox.exportPoker(currentNumber - 1, cardName);
                }
            }
            // 设置游戏排名
            if (gameSetting == Red5GameSetting.NO_RUSH) {
                // 设置不独时的排名
                thirdPlaceNumber = currentNumber;
                forthPlaceNumber = currentNextNumber;
            } else if (gameSetting != Red5GameSetting.NO_RUSH) {
                // 设置独牌时的排名
                firstPlaceNumber = currentNumber;
            }
            // 开始亮牌，并从当前玩家的下家开始
            var startIndex:int = localNumber;
            for (var i:int = 1; i < playerCogameNumber; i++) {
            	if (startIndex == playerCogameNumber) {
            		startIndex = 0;
            	}
                var tempCardCandidated:Box = (cardsCandidatedArray[startIndex] as Box);
                if (gameSetting != Red5GameSetting.NO_RUSH || (tempCardCandidated.numChildren > 0 && !(tempCardCandidated.getChildAt(0) is Image))) {
                    // 保留大皇上二皇上大娘娘二娘娘提示
                    tempCardCandidated.removeAllChildren();
                }
            	for each (var eachPoker:String in pokerBox.cardsOfPlayers[startIndex]) {
                    var pokerInHand:PokerButton = new PokerButton();
                    pokerInHand.source = PokerResource.load(eachPoker);
                    pokerInHand.allowSelect = false;
                    tempCardCandidated.addChild(pokerInHand);
            	}
            	startIndex++;
            }
            // 按游戏排名显示头衔
            if (gameSetting == Red5GameSetting.NO_RUSH) {
                /*
                var winLabel:Label = new Label();
                winLabel.text = "大娘娘";
                winLabel.setStyle("color", 0xff0000);
                */
                var winnerImage:Image = new Image();
                winnerImage.source = Red5GameResource.WINNER3;
                if ((cardsCandidatedArray[thirdPlaceNumber - 1] as Container).numChildren > 0 &&
                    (cardsCandidatedArray[thirdPlaceNumber - 1] as Container).getChildAt(0) is Image) {
                } else {
                    // (cardsCandidatedArray[thirdPlaceNumber - 1] as Container).addChild(winLabel);
                    (cardsCandidatedArray[thirdPlaceNumber - 1] as Container).addChild(winnerImage);
                }
                /*
                winLabel = new Label();
                winLabel.text = "二娘娘";
                winLabel.setStyle("color", 0xff6699);
                */
                winnerImage = new Image();
                winnerImage.source = Red5GameResource.WINNER4;
                if ((cardsCandidatedArray[forthPlaceNumber - 1] as Container).numChildren > 0 &&
                    (cardsCandidatedArray[forthPlaceNumber - 1] as Container).getChildAt(0) is Image) {
                } else {
                    // (cardsCandidatedArray[forthPlaceNumber - 1] as Container).addChild(winLabel);
                    (cardsCandidatedArray[forthPlaceNumber - 1] as Container).addChild(winnerImage);
                }
            }
            // 显示记分牌
            var misc:Object = {GAME_TYPE : "Red5Game",
            		GAME_SETTING : gameSetting, 
            		GAME_FINAL_SETTING_PLAYER_NUMBER : gameFinalSettingPlayerNumber,
            		TITLE : Red5GameSetting.getDisplayName(gameSetting)}; 
			this._myPuppet.dispatchEvent(new GamePinocchioEvent(
				GamePinocchioEvent.GAME_END, 
				null, 
				new Scoreboard().popUp(localNumber, scoreboardInfo, currentGameId,
		            function():void {
		            	gameClient.currentState = 'LOBBY';
		            }, misc)));
            // 显示游戏积分
            if (gameSetting != Red5GameSetting.NO_RUSH) {
                var rushResult:String = null;
                if (firstPlaceNumber == gameFinalSettingPlayerNumber) {
                    rushResult = "成功！";
                } else {
                    rushResult = "失败！";
                }
                // 游戏结束，并且当前玩家不是最终的游戏规则设置者
                gameClient.txtSysMessage.text += Red5GameSetting.getDisplayName(gameSetting) + rushResult + "\n";
            } else {
                gameClient.txtSysMessage.text += [firstPlaceNumber, 
                                                  secondPlaceNumber, 
                                                  thirdPlaceNumber, 
                                                  forthPlaceNumber].join(",") + "\n";
            }
            if (otherTimer.running) {
                otherTimer.stop();
            }
            CursorManager.removeBusyCursor();
        }

        /**
         *
         * 没有独牌或天独或天外天的情况下，游戏中产生获胜者
         *
         * @param event
         *
         */
        private function gameWinnerProducedHandler(event:Red5GameEvent):void {
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
                isWinnerFollowed = true;
            }
            // 更新画面表现
            gameBringOutHandler(event);
            // 设置游戏获胜者信息
            var winnerImage:Image = new Image();
            // var winLabel:Label = new Label();
            if (firstPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                firstPlaceNumber = currentNumber;
                /*
                winLabel.text = "大皇上";
                winLabel.setStyle("color", 0xffff00);
                */
                winnerImage.source = Red5GameResource.WINNER1;
                (cardsCandidatedArray[firstPlaceNumber - 1] as Container).addChild(winnerImage);
            } else if (secondPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                secondPlaceNumber = currentNumber;
                /*
                winLabel.text = "二皇上";
                winLabel.setStyle("color", 0xffffcc);
                */
                winnerImage.source = Red5GameResource.WINNER2;
                (cardsCandidatedArray[secondPlaceNumber - 1] as Container).addChild(winnerImage);
            } else if (thirdPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                thirdPlaceNumber = currentNumber;
                var placeNumberPattern:RegExp = new RegExp("[" + firstPlaceNumber + secondPlaceNumber + thirdPlaceNumber + "]", "g");
                forthPlaceNumber = Number("1234".replace(placeNumberPattern, ""));
                /*
                winLabel.text = "大娘娘";
                winLabel.setStyle("color", 0xff0000);
                */
                winnerImage.source = Red5GameResource.WINNER3;
                (cardsCandidatedArray[thirdPlaceNumber - 1] as Container).addChild(winnerImage);
                /*
                winLabel = new Label();
                winLabel.text = "二娘娘";
                winLabel.setStyle("color", 0xff6699);
                */
                winnerImage = new Image();
                winnerImage.source = Red5GameResource.WINNER4;
                (cardsCandidatedArray[forthPlaceNumber - 1] as Container).addChild(winnerImage);
            }
        }

        /**
         *
         * 游戏创建，为客户端玩家分配游戏id号与当前游戏玩家序号以及下家玩家序号
         *
         * @param event
         *
         */
        private function gameCreateHandler(event:GameEvent):void {
            var results:Array = null;
            if (event.incomingData != null) {
                results = event.incomingData.split("~");
            }
            Red5GameStateManager.resetInitInfo();
            Red5GameStateManager.currentGameId = results[0];
            Red5GameStateManager.localNumber = results[1];
            Red5GameStateManager.playerCogameNumber = results[2];
            if (Red5GameStateManager.playerCogameNumber == Red5GameStateManager.localNumber) {
                Red5GameStateManager.localNextNumber = 1;
            } else {
                Red5GameStateManager.localNextNumber = Red5GameStateManager.localNumber + 1;
            }
            gameClient.currentState = "RED5GAME";
        }

        /**
         *
         * @param event
         *
         */
        private function gameWaitHandler(event:GameEvent):void {
            gameClient.txtSysMessage.text += event.incomingData + "\n";
            // gameClient.txtSysMessage.selectionEndIndex = gameClient.txtSysMessage.length - 1;
            gameClient.progressBarMatching.indeterminate = false;
            gameClient.progressBarMatching.setProgress(parseInt(event.incomingData.replace(/\D/g, "")), 100);
            gameClient.progressBarMatching.visible = true;
        }

        /**
         *
         * 扑克操作
         *
         * 1#cardSeq#2#cardSeq#3#cardSeq#4#cardSeq#
         *
         * cardSeq = 1V3,2V3,3V3,4V3|2V3,3V4,4V5,3V6
         *
         * @param event
         *
         */
        private function itemClick(event:ItemClickEvent):void {
            if (!currentGame.btnBarPokers.visible) {
                return;
            }
            var card:PokerButton;
            var isGameOver:Boolean = false;
            switch (event.index) {
                case 0:
                    // 重选
                    for each (card in currentGame.candidatedDown.getChildren()) {
                        card.setSelected(false);
                    }
                    break;
                case 1:
                    // 不要
                    if (isWinnerFollowed) {
                        // 如果当前玩家上家是获胜者时，需要重新设置获胜者发出的消息
                        // 将获胜者牌更为当前玩家牌，以便在所有玩家“不要”的情况下
                        // 可以由获胜者的直接下家出牌
                        socketProxy.sendGameData(Red5GameCommand.GAME_BRING_OUT, localNumber + "~" + currentBoutCards + "~" + localNextNumber + "~pass~" + localNumber);
                        isWinnerFollowed = false;
                    } else if (gameSetting == Red5GameSetting.EXTINCT_RUSH && localNextNumber == currentNumber && currentGame.candidatedRight.getChildren().length == 0) {
                        // 设置游戏冠军玩家
                        firstPlaceNumber = currentNumber;
                        // 游戏设置为天外天，且所有非独牌者均不要时
                        socketProxy.sendGameData(Red5GameCommand.GAME_WIN_AND_END, currentNumber + "~" + cards + "~" + localNextNumber + "~pass~" + localNumber);
                        isGameOver = true;
                    } else {
                        socketProxy.sendGameData(Red5GameCommand.GAME_BRING_OUT, currentNumber + "~" + currentBoutCards + "~" + localNextNumber + "~pass~" + localNumber);
                        if (currentNumber == localNextNumber) {
// 2009/10/13 该功能可能需要保留
//                            // 当前玩家在本回合中不要，且之前所有的玩家均不要的时候
//                            for each (var cardsDealed:Container in cardsDealedArray) {
//                                cardsDealed.removeAllChildren();
//                            }
//                            currentGame.btnBarPokers.visible = false;
//                            return;
                        }
                    }
                    // 在发牌区域显示"不要"标签
                    var currentIndex:int = (localNumber - 1);
//                    var passLabel:Label = new Label();
//                    passLabel.text = "PASS";
//                    passLabel.setStyle("fontSize", 24);
                    var passImage:Image = new Image();
                    passImage.source = Red5GameResource.PASS;
                    Container(cardsDealedArray[currentIndex]).removeAllChildren();
                    Container(cardsDealedArray[currentIndex]).addChild(passImage);
                    // 出牌操作结束后，关闭扑克操作栏
                    currentGame.btnBarPokers.visible = false;
                    // 更新显示提示
                    updateOtherTip(currentNumber, localNextNumber);
                    break;
                case 2:
					// 提示
                    // 将所有牌设置为非选中状态
                    itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, Red5Game.OPTR_RESELECT));
					if (currentBoutCards == null || currentBoutCards.split(",").length == 0) {
						// 轮到当前玩家发牌时
						PokerButton(currentGame.candidatedDown.getChildAt(0)).setSelected(true);
					} else {
						// 轮到当前玩家接牌时
                        var tipArray:Array = Red5Game.getBrainPowerTip(
                                currentGame.candidatedDown.getChildren().join(",").split(","), currentBoutCards.split(","), false);
                        var i:int = 0;
                        var eachPokerButton:PokerButton = null;
                        if (tipArray) {
                            for each (eachPokerButton in currentGame.candidatedDown.getChildren()) {
                                // 不计花色比较
                                if (eachPokerButton.value.replace(/\d/, "") == tipArray[i] || eachPokerButton.value == tipArray[i]) {
                                    eachPokerButton.setSelected(true);
                                    i++;
                                }
                            }
                        } else {
                            // 没有备选牌的情况下，自动放弃
                            itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, Red5Game.OPTR_GIVEUP));
                        }
                    }
                    break;
                case 3:
                    // 出牌
                    // 选择要出的牌
                    var cards:String = "";
                    for each (card in currentGame.candidatedDown.getChildren()) {
                        if (card.isSelected()) {
                            cards += card.value + ",";
                        }
                    }
                    cards = cards.replace(/,$/, "");
                    // 未作任何选择时，直接退出处理
                    if (cards.length == 0) {
                        return;
                    }
                    // 规则验证
                    if (!Red5Game.isRuleFollowed(cards, currentBoutCards)) {
                        // 不满足出牌规则时进行重选操作
                        itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, Red5Game.OPTR_RESELECT));
                        return;
                    }
                    // 设置出牌结果
                    // 当前剩余的牌数
                    var cardsCandicateNumber:int = currentGame.candidatedDown.getChildren().length;
                    // 即将打出的牌数
                    var cardsDealedNumber:int = cards.split(",").length;
                    // 打出后剩余牌数
                    var cardsLeftNumber:int = cardsCandicateNumber - cardsDealedNumber;
                    // 更新内存模型
                    for each (var eachCard:String in cards.split(/,/g)) {
                    	pokerBox.exportPoker(localNumber - 1, eachCard);
                    }
                    // 发送出牌消息
                    if (gameSetting > Red5GameSetting.RUSH && gameFinalSettingPlayerNumber != localNumber) {
                        // 设置游戏冠军玩家
                        firstPlaceNumber = localNumber;
                        // 游戏设置为天独或天外天时，且有非独牌者出牌的情况
                        socketProxy.sendGameData(Red5GameCommand.GAME_WIN_AND_END, localNumber + "~" + cards + "~" + localNextNumber);
                        isGameOver = true;
                    } else if (cardsLeftNumber == 0 && (gameSetting == Red5GameSetting.RUSH || gameSetting == Red5GameSetting.DEADLY_RUSH)) {
                        // 设置游戏冠军玩家
                        firstPlaceNumber = localNumber;
                        // 游戏设置为独牌或天独时，且有玩家胜出的情况
                        socketProxy.sendGameData(Red5GameCommand.GAME_WIN_AND_END, localNumber + "~" + cards + "~" + localNextNumber);
                        isGameOver = true;
                    } else if (cardsLeftNumber == 0 && gameSetting == Red5GameSetting.NO_RUSH) {
                        // 没有独牌或天独或天外天的情况，判断是否还有剩余牌
                        if (firstPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                            // 第一名未产生时，设置firstPlace
                            firstPlaceNumber = localNumber;
                            // 要出的牌数与剩余牌数相同时，发送获胜信息
                            socketProxy.sendGameData(Red5GameCommand.GAME_WIN, localNumber + "~" + cards + "~" + localNextNumber);
                        } else if (secondPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                            // 第二名未产生时，设置secondPlace
                            secondPlaceNumber = localNumber;
                            // 如果是secondPlace，则发生获胜以及游戏结束信息
                            socketProxy.sendGameData(Red5GameCommand.GAME_WIN, localNumber + "~" + cards + "~" + localNextNumber);
                        } else if (thirdPlaceNumber == UNOCCUPIED_PLACE_NUMBER) {
                            // 第三名未产生时，设置thirdPlace
                            thirdPlaceNumber = localNumber;
                            // 设置forthPlace
                            var placePattern:RegExp = new RegExp("[abc]".replace(/a/, firstPlaceNumber).replace(/b/, secondPlaceNumber).replace(/c/, thirdPlaceNumber), "g");
                            forthPlaceNumber = int("1234".replace(placePattern, ""));
                            // 如果是thirdPlace，则发生获胜以及游戏结束信息
                            socketProxy.sendGameData(Red5GameCommand.GAME_WIN_AND_END, localNumber + "~" + cards + "~" + localNextNumber);
                            isGameOver = true;
                        }
                        if (!isGameOver) {
                            var placeNumbers:Array = new Array(firstPlaceNumber, secondPlaceNumber, thirdPlaceNumber, forthPlaceNumber);
                            // Alert.show("玩家[" + placeNumbers.join(",") + "]胜出！", "消息");
                        }
                    } else if (cardsLeftNumber > 0 || gameSetting == Red5GameSetting.EXTINCT_RUSH) {
                        // 当前规则下，出牌玩家手中还有剩余牌，并未获胜，正常出牌的情况
                        // 或者是天外天时，独牌者进行发牌
                        if (isWinnerFollowed) {
                            // 没有独牌或天独，并且第一个获胜者牌最大
                            // 构造出牌数据，当前玩家序号~牌名,牌名...~下家玩家序号
                            socketProxy.sendGameData(Red5GameCommand.GAME_BRING_OUT, localNumber + "~" + cards + "~" + localNextNumber);
                            isWinnerFollowed = false;
                        } else {
                            // 构造出牌数据，当前玩家序号~牌名,牌名...~下家玩家序号
                            socketProxy.sendGameData(Red5GameCommand.GAME_BRING_OUT, localNumber + "~" + cards + "~" + localNextNumber);
                        }
                    } else {
                        throw Error("其他无法预测的出牌动作！");
                    }
                    // 更新客户端扑克显示
                    currentGame.dealedDown.removeAllChildren();
                    for each (card in currentGame.candidatedDown.getChildren()) {
                        if (card.isSelected()) {
                            currentGame.candidatedDown.removeChild(card);
                            currentGame.dealedDown.addChild(card);
                            card.allowSelect = false;
                        }
                    }
                    if (gameSetting == Red5GameSetting.NO_RUSH) {
                        // var winLabel:Label = new Label();
                        var winnerImage:Image = new Image();
                        switch (localNumber) {
                            case firstPlaceNumber:
                                /*
                                winLabel.text = "大皇上";
                                winLabel.setStyle("color", 0xffff00);
                                */
                                winnerImage.source = Red5GameResource.WINNER1;
                                currentGame.candidatedDown.addChild(winnerImage);
                                break;
                            case secondPlaceNumber:
                                /*
                                winLabel.text = "二皇上";
                                winLabel.setStyle("color", 0xffffcc);
                                */
                                winnerImage.source = Red5GameResource.WINNER2;
                                currentGame.candidatedDown.addChild(winnerImage);
                                break;
                            case thirdPlaceNumber:
                                /*
                                winLabel.text = "大娘娘";
                                winLabel.setStyle("color", 0xff0000);
                                */
                                /*
                                winnerImage.source = Red5GameResource.WINNER3;
                                currentGame.candidatedDown.addChild(winnerImage);
                                */
                                /*
                                winLabel = new Label();
                                winLabel.text = "二娘娘";
                                winLabel.setStyle("color", 0xff6699);
                                */
                                winnerImage = new Image();
                                winnerImage.source = Red5GameResource.WINNER4;
                                (cardsCandidatedArray[forthPlaceNumber - 1] as Container).addChild(winnerImage);
                                break;
                        }
                    }
                    // 出牌操作结束后，关闭扑克操作栏
                    currentGame.btnBarPokers.visible = false;
                    // 更新显示提示
                    updateOtherTip(localNumber, localNextNumber);
                    break;
            }
        }
        
        /**
         * 
         * 响应用户自主选牌提示
         * 
         * @param event
         * 
         */
        private function btnBarPokersTipHandler(event:ItemClickEvent):void {
            itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, Red5Game.OPTR_RESELECT));
            var tipArray:Array = null;
            if (event.currentTarget == currentGame.btnBarPokersTipA) {
                // 对子、三同张、四同张、五同张、六同张、七同张、八同张
                tipArray = Red5Game.nextTipCards(event.index + 101);
            } else if (event.currentTarget == currentGame.btnBarPokersTipB) {
                // 四连顺、五连顺、对子三连顺、对子四连顺、对子五连顺
                tipArray = Red5Game.nextTipCards(event.index + 201);
            } else if (event.currentTarget == currentGame.btnBarPokersTipC) {
                // 三同张三连顺、三同张四连顺、三同张五连顺、四同张三连顺
                tipArray = Red5Game.nextTipCards(event.index + 301);
            }
            var i:int = 0;
            var eachPokerButton:PokerButton = null;
            if (tipArray) {
                for each (eachPokerButton in currentGame.candidatedDown.getChildren()) {
                    // 不计花色比较
                    if (eachPokerButton.value.replace(/\d/, "") == tipArray[i]) {
                        eachPokerButton.setSelected(true);
                        i++;
                    } else if (event.currentTarget == currentGame.btnBarPokersTipA && 
                            (event.index + 101) == Red5Game.TIPA_MUTIPLE2 && 
                            eachPokerButton.value == tipArray[i]) {
                        // 对子，且目标值带有花色，即大小王和红五时
                        eachPokerButton.setSelected(true);
                        i++;
                    }
                }
            }
        }

        /**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
         * 
         * @param event
		 * 
		 */
		private function show(event:FlexEvent):void {
            // 清除当前玩家出牌区域
            currentGame.dealedDown.removeAllChildren();
			// 显示进度条，倒计时开始开始
            currentGame.timerTip.setProgress(MAX_CARDS_SELECT_TIME, MAX_CARDS_SELECT_TIME);
			currentGame.timerTip.label = "剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME);
			currentGame.timerTip.visible = true;
            if (timer.running) {
                timer.stop();
                timer.reset();
            }
            timer.start();
            CursorManager.removeBusyCursor();
            // 计算提示
            Red5Game.refreshTips(currentGame.candidatedDown.getChildren().join(","));
            // 激活PUPPET引擎
            this._myPuppet.dispatchEvent(new GamePinocchioEvent(
                GamePinocchioEvent.GAME_BOUT, null));
        }

		/**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
         * 
         * @param event
		 * 
		 */
		private function hide(event:FlexEvent):void {
			// 进度条隐藏，并重置计时器
			currentGame.timerTip.visible = false;
            timer.stop();
			timer.reset();
            CursorManager.setBusyCursor();
		}

        /**
         * 
         * 更新游戏提示信息 ，该方法在调用时，均处于调用方法的底部
         * 
         * @param lastNumber 最后出牌或游戏设置玩家编号
         * @param nextNumber 准备出牌的玩家编号
         * @param showOtherTime 是否应用等待其他玩家信息
         * 
         */
        private function updateOtherTip(lastNumber:int, nextNumber:int, showOtherTime:Boolean = true):void {
            // 参数初始化
            currentNextNumber = nextNumber; // TODO Should this line be removed?
            // 从画面中清除已经使用过的倒计时
            for each (var eachDealed:Container in cardsDealedArray) {
                if (eachDealed.numChildren > 0 && eachDealed.getChildAt(eachDealed.numChildren - 1) is GameWaiting) {
                    eachDealed.removeChildAt(eachDealed.numChildren - 1);
                }
            }
            currentGame.candidatedTipDownExt.removeAllChildren();
//            // 显示游戏提示
//            var tipString:String = "准备出牌玩家：#，\n最后出牌玩家：#。";
//            var playerDirection:Array = new Array("下", "右", "上", "左");
//            var index:int = 0;
//            while (index != localNumber - 1) {
//                var temp:Object = null;
//                temp = playerDirection.pop();
//                playerDirection.unshift(temp);
//                index++;
//            }
//            // 显示游戏提示：指示当前要出牌的玩家
//            tipString = tipString.replace(/#/, playerDirection[nextNumber - 1]);
//            // 显示游戏提示：指示最后出了牌的玩家，首次发牌时，lastBoutedNumber小于零
//            tipString = tipString.replace(/#/, lastNumber < 0 ? "无" : playerDirection[lastNumber - 1]);

            if (showOtherTime && !currentGame.btnBarPokers.visible) {
                // 非当前玩家出牌时，显示动态提示
                if (otherTimer.running) {
                    otherTimer.stop();
                }
//                // 将出牌玩家出牌区域清空并添加倒计时提示
//                var otherTimeTipLabel:Label = new Label();
//                otherTimeTipLabel.text = "【" + MAX_CARDS_SELECT_TIME + "】";
//                otherTimeTipLabel.setStyle("color", 0x0000ff);
//                otherTimeTipLabel.opaqueBackground = 0xffffcc;
//                // 保留已出牌，并显示倒计时
//                var currentDealed:Container = Container(cardsDealedArray[nextNumber - 1]);
//                while (currentDealed.numChildren > 0) {
//                    if (currentDealed.getChildAt(currentDealed.numChildren - 1) is Label) {
//                        currentDealed.removeChildAt(currentDealed.numChildren - 1);
//                    } else {
//                        otherTimeTipLabel.setStyle("paddingLeft", 100);
//                        break;
//                    }
//                }
//                currentDealed.addChild(otherTimeTipLabel);
//                // 将出牌玩家出牌区域清空并添加倒计时提示
//                var gameWaitingClock:GameWaiting = new GameWaiting();
//                gameWaitingClock.tipText = MAX_CARDS_SELECT_TIME.toString();
                // 保留已出牌，并显示倒计时
                var currentDealed:Container = Container(cardsDealedArray[nextNumber - 1]);
                if (currentDealed.numChildren > 0 && currentDealed.getChildAt(currentDealed.numChildren - 1) is GameWaiting) {
                    (currentDealed.getChildAt(currentDealed.numChildren - 1) as GameWaiting).tipText = MAX_CARDS_SELECT_TIME.toString();
                } else {
                    var gameWaitingClock:GameWaiting = new GameWaiting();
                    gameWaitingClock.tipText = MAX_CARDS_SELECT_TIME.toString();
                    currentDealed.addChild(gameWaitingClock);
                }
                otherTimer.reset();
                otherTimer.start();
            }
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
            gameSetting = -1;
            gameFinalSettingPlayerNumber = -1;
            gameSettingUpdateTimes = 0;
            currentGameId = null;
            firstPlayerNumber = 0;
            localNumber = 0;
            localNextNumber = 0;
            currentNumber = 0;
            currentBoutCards = null;
            currentNextNumber = 0;
            firstPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            secondPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            thirdPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            forthPlaceNumber = UNOCCUPIED_PLACE_NUMBER;
            isWinnerFollowed = false;
            for each (var cardsDealed:Container in cardsDealedArray) {
                cardsDealed.removeAllChildren();
            }
            for each (var cardsCandidated:Box in cardsCandidatedArray) {
                cardsCandidated.removeAllChildren();
            }
            for each (var cardsCandidatedTip:Box in cardsCandidatedTipArray) {
                cardsCandidatedTip.removeAllChildren();
            }
            if (currentGame) {
                currentGame.infoBoardText.text = "";
            }
        }
    }
}
