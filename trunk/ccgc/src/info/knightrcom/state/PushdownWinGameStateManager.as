package info.knightrcom.state {
    import component.MahjongButton;
    import component.Scoreboard;
    
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.filters.DropShadowFilter;
    import flash.utils.Timer;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.assets.MahjongResource;
    import info.knightrcom.command.PushdownWinGameCommand;
    import info.knightrcom.event.GameEvent;
    import info.knightrcom.event.PushdownWinGameEvent;
    import info.knightrcom.puppet.GamePinocchioEvent;
    import info.knightrcom.state.pushdownwingame.PushdownWinGame;
    import info.knightrcom.state.pushdownwingame.PushdownWinGameSetting;
    import info.knightrcom.state.pushdownwingame.PushdownWinMahjongBox;
    import info.knightrcom.util.ListenerBinder;
    import info.knightrcom.util.TimeTicker;
    
    import mx.containers.Box;
    import mx.containers.VBox;
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.controls.ProgressBarMode;
    import mx.core.Application;
    import mx.core.Container;
    import mx.events.FlexEvent;
    import mx.events.ItemClickEvent;
    import mx.managers.CursorManager;
    import mx.states.State;
    import mx.styles.StyleManager;

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
         * 消息中的执行放弃的玩家序号
         */
        public static var currentGiveupIndice:String;

        /**
         * 是否自摸
         */
        public static var isNarrowWin:Boolean = false;

        /**
         * 杠牌标识，用于判断从牌墙的哪个方向摸牌
         */
        public static var isKongFlag:Boolean = false;

        /**
         * 未占用的位置
         */
        public static const UNOCCUPIED_PLACE_NUMBER:int = -1;

		/**
		 * 用户发牌最大等待时间(秒)
		 */
		// private static const MAX_CARDS_SELECT_TIME:int = 15;
		private static const MAX_CARDS_SELECT_TIME:int = 999;

        /**
         * 发牌提示区域
         */
        private static var mahjongsTipArray:Array = null;

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
		private static var timer:Timer = new Timer(1000, MAX_CARDS_SELECT_TIME);
        
        /**
         * 计时器(用于显示其他玩家出牌所用时间)
         */
        private static var otherTimer:Timer = new Timer(1000, MAX_CARDS_SELECT_TIME);

        /**
         * 当前游戏模块
         */
		private static var currentGame:CCGamePushdownWin = null;

        /**
         *
         * @param socketProxy
         * @param currentGame
         * @param myState
         *
         */
        public function PushdownWinGameStateManager(socketProxy:GameSocketProxy, myState:State):void {
            super(socketProxy, myState);
            ListenerBinder.bind(myState, FlexEvent.ENTER_STATE, init);
            batchBindGameEvent(PushdownWinGameEvent.EVENT_TYPE, new Array(
                    GameEvent.GAME_WAIT, gameWaitHandler,
                    GameEvent.GAME_CREATE, gameCreateHandler,
            		GameEvent.GAME_STARTED, gameStartedHandler,
            		GameEvent.GAME_FIRST_PLAY, gameFirstPlayHandler,
            		GameEvent.GAME_BRING_OUT, gameBringOutHandler,
            		GameEvent.GAME_INTERRUPTED, gameInterruptedHandler,
            		GameEvent.GAME_OVER, gameOverHandler));
        }

        /**
         *
         * @param event
         *
         */
        private function init(event:Event):void {
            if (!isInitialized()) {
                currentGame = gameClient.pushdownWinGameModule;
                // 配置事件监听
                // 注册非可视组件监听事件
				ListenerBinder.bind(timer, TimerEvent.TIMER, function(event:TimerEvent):void {
                    for each (var eachTipArea:Container in mahjongsTipArray) {
                        if (eachTipArea == currentGame.tipDown) {
                            continue;
                        }
                        if (eachTipArea.numChildren > 0 && eachTipArea.getChildAt(eachTipArea.numChildren - 1) is GameWaiting) {
                            eachTipArea.removeChildAt(eachTipArea.numChildren - 1);
                        }
                    }
                    if (currentGame.tipDown.numChildren > 0) {
                        (currentGame.tipDown.getChildAt(0) as GameWaiting).tipText = String(MAX_CARDS_SELECT_TIME - timer.currentCount);
                    } else {
                        var gameWaitingClock:GameWaiting = new GameWaiting();
                        gameWaitingClock.tipText = String(MAX_CARDS_SELECT_TIME - timer.currentCount);
                        currentGame.tipDown.addChild(gameWaitingClock);
                    }
					if (currentGame.btnBarMahjongs.visible && timer.currentCount == MAX_CARDS_SELECT_TIME) {
                        var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
                        if (Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_GIVEUP)).enabled) {
                            // 执行放弃动作
                            dummyEvent.index = PushdownWinGame.OPTR_GIVEUP;
                            itemClick(dummyEvent);
                        }
					    if (Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_RAND)).enabled) {
					        // 执行摸牌动作
                            dummyEvent.index = PushdownWinGame.OPTR_RAND;
                            itemClick(dummyEvent);
					    }
                        if (currentGame.randDown.numChildren > 0) {
                            // 摸牌区域有牌时，将摸到的牌打出
                            dealMahjong(MahjongButton(currentGame.randDown.getChildAt(0)));
                        }
					}
				});
                ListenerBinder.bind(otherTimer, TimerEvent.TIMER, function(e:TimerEvent):void {
                    if (currentGame.btnBarMahjongs.visible) {
                        return;
                    }
                    var otherGameWaitingClockParent:Container = Container(mahjongsTipArray[currentNextNumber - 1]);
                    var lastChildIndex:int = otherGameWaitingClockParent.numChildren - 1;
                    if (otherGameWaitingClockParent.numChildren > 0 && otherGameWaitingClockParent.getChildAt(lastChildIndex) is GameWaiting) {
                        GameWaiting(otherGameWaitingClockParent.getChildAt(lastChildIndex)).tipText = String(MAX_CARDS_SELECT_TIME - otherTimer.currentCount);// Label(otherGameWaitingClockParent.getChildAt(lastChildIndex)).text.replace(/【\d+】/g, "【#】".replace(/#/, String(MAX_CARDS_SELECT_TIME - otherTimer.currentCount)));
                    }
                });
                // 可视组件
                ListenerBinder.bind(currentGame.btnBarMahjongs, ItemClickEvent.ITEM_CLICK, itemClick);
                ListenerBinder.bind(currentGame.btnBarMahjongs, FlexEvent.SHOW, show);
                ListenerBinder.bind(currentGame.btnBarMahjongs, FlexEvent.HIDE, hide);
// TEST SIMULATION CODE IS BEGIN
                ListenerBinder.bind(currentGame.testFresh, MouseEvent.CLICK, function(e:MouseEvent):void {
                    if (!currentGame.testArea.visible) {
                        currentGame.testArea.visible = true;
                    }
                    currentGame.testArea.text = 
                    new Array(
                        "Number of mahjong left: " + mahjongBox.mahjongsOnTable.length,
                        "Local Number: " + localNumber,
                        "Current Number: " + currentNumber,
                        new Array(mahjongBox.mahjongsOfPlayers[0].join(","), 
                                  mahjongBox.mahjongsOfPlayers[0].length, 
                                  mahjongBox.mahjongsOfDais[0].join(","), 
                                  mahjongBox.mahjongsOfDais[0].length).join("\t"),
                        new Array(mahjongBox.mahjongsOfPlayers[1].join(","), 
                                  mahjongBox.mahjongsOfPlayers[1].length, 
                                  mahjongBox.mahjongsOfDais[1].join(","), 
                                  mahjongBox.mahjongsOfDais[1].length).join("\t"),
                        new Array(mahjongBox.mahjongsOfPlayers[2].join(","), 
                                  mahjongBox.mahjongsOfPlayers[2].length, 
                                  mahjongBox.mahjongsOfDais[2].join(","), 
                                  mahjongBox.mahjongsOfDais[2].length).join("\t"),
                        new Array(mahjongBox.mahjongsOfPlayers[3].join(","), 
                                  mahjongBox.mahjongsOfPlayers[3].length,
                                  mahjongBox.mahjongsOfDais[3].join(","),
                                  mahjongBox.mahjongsOfDais[3].length).join("\t")).join("\n");
                });
// TEST SIMULATION CODE IS END
                for each (var eachContainer:Container in [currentGame.toolTipChow1, currentGame.toolTipChow2, currentGame.toolTipChow3,
                        currentGame.toolTipKong1, currentGame.toolTipKong2, currentGame.toolTipKong3]) {
                    ListenerBinder.bind(eachContainer, MouseEvent.MOUSE_OVER, function (event:MouseEvent):void {
                        eachContainer.filters = [new DropShadowFilter(2, 90, StyleManager.getColorName("darkorange"))];
                    });
                    ListenerBinder.bind(eachContainer, MouseEvent.MOUSE_OUT, function (event:MouseEvent):void {
                        eachContainer.filters = null;
                    });
                }
                for each (var eachToolKongTip:Box in [currentGame.toolTipKong1, currentGame.toolTipKong2, currentGame.toolTipKong3]) {
                    ListenerBinder.bind(MahjongButton(eachToolKongTip.getChildAt(0)), MouseEvent.CLICK, toolTipKongClick);
                    ListenerBinder.bind(MahjongButton(eachToolKongTip.getChildAt(1)), MouseEvent.CLICK, toolTipKongClick);
                    ListenerBinder.bind(MahjongButton(eachToolKongTip.getChildAt(2)), MouseEvent.CLICK, toolTipKongClick);
                    ListenerBinder.bind(MahjongButton(eachToolKongTip.getChildAt(3)), MouseEvent.CLICK, toolTipKongClick);
                }
                for each (var eachToolChowTip:Box in [currentGame.toolTipChow1, currentGame.toolTipChow2, currentGame.toolTipChow3]) {
                    ListenerBinder.bind(MahjongButton(eachToolChowTip.getChildAt(0)), MouseEvent.CLICK, toolTipChowClick);
                    ListenerBinder.bind(MahjongButton(eachToolChowTip.getChildAt(1)), MouseEvent.CLICK, toolTipChowClick);
                    ListenerBinder.bind(MahjongButton(eachToolChowTip.getChildAt(2)), MouseEvent.CLICK, toolTipChowClick);
                }
                ListenerBinder.bind(currentGame, FlexEvent.UPDATE_COMPLETE, function (event:Event):void {
                    var eachButton:Button = null;
                    for each (eachButton in currentGame.btnBarMahjongs.getChildren()) {
                        eachButton.styleName = "gameBigButton";
                    }
                });
                currentGame.greatWall.initWalls();
                setInitialized(true);
            }
            
            // 洗牌，创建牌墙
            currentGame.greatWall.createWalls(localNumber); // 内存更新
            // FIXME animation currentGame.greatWall.showAllMahjongs(); // 显示更新

            // 按照当前玩家序号，进行画面座次安排
            var tempMahjongsTip:Array = new Array(currentGame.tipDown, currentGame.tipRight, currentGame.tipUp, currentGame.tipLeft);
            var tempMahjongsCandidated:Array = new Array(currentGame.candidatedDown, currentGame.candidatedRight, currentGame.candidatedUp, currentGame.candidatedLeft);
            var tempMahjongsDais:Array = new Array(currentGame.daisDown, currentGame.daisRight, currentGame.daisUp, currentGame.daisLeft);
            var tempMahjongsRand:Array = new Array(currentGame.randDown, currentGame.randRight, currentGame.randUp, currentGame.randLeft);
            var tempPlayerDirection:Array = new Array("down", "right", "up", "left")

            // 进行位移操作
            var index:int = 0;
            while (index != localNumber - 1) {
                var temp:Object = null;
                temp = tempMahjongsTip.pop();
                tempMahjongsTip.unshift(temp);
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
            mahjongsTipArray = new Array(playerCogameNumber);
            for (index = 0; index < mahjongsTipArray.length; index++) {
                mahjongsTipArray[index] = tempMahjongsTip[index];
            }
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
            // FIXME TEST PART BEGIN
//            mahjongBox.mahjongsOfPlayers = new Array("EAST,EAST,EAST,EAST,W1,W1,W3,W4,W5,W6,W8,W8,W8",
//                                                     "SOUTH,SOUTH,SOUTH,B1,B1,B1,B3,B4,B5,B7,B7,B7,RED",
//                                                     "WEST,WEST,WEST,T1,T1,T1,T3,T4,T5,T7,T7,T7,RED", 
//                                                     "NORTH,NORTH,NORTH,W2,W3,W4,B2,B3,B4,T2,T3,T4,T4");
//            mahjongBox.mahjongsSpared = "W8,W8,B3,RED,NORTH,B4,W5,B6,W2,T5,W6,T4,T3,W6,B5,W3,WEST,B8,B8,T8,T8,WHITE,W6,W8,GREEN,W4,W9,W2,WHITE,T5,W2,T7,W5,W1,T9,W5,W4,GREEN,W7,T8,W8,W9,GREEN,W9,B5,B7,B2,B2,B1,B8,W9,B6,B2,B6,B6,B5,B4,B8,B9,B9,B9,B9,T9,T2,T2,T5,T3,B3,T9,WHITE,W3,T6,T1,T6,T6,T6,T8,WHITE,W6,GREEN,EAST,T2,T9,SOUTH".split(",");
//
//            results[0] = mahjongBox.mahjongsOfPlayers[0];
//            results[1] = mahjongBox.mahjongsOfPlayers[1];
//            results[2] = mahjongBox.mahjongsOfPlayers[2];
//            results[3] = mahjongBox.mahjongsOfPlayers[3];
//            results[4] = mahjongBox.mahjongsSpared;
//
//            mahjongBox.mahjongsOfPlayers[0] = "EAST,EAST,EAST,EAST,W1,W1,W3,W4,W5,W6,W8,W8,W8".split(/,/);
//            mahjongBox.mahjongsOfPlayers[1] = "B5,B4,W1,B3,W3,B4,B6,W2,B6,W1,T5,T7,T8,T9".split(/,/);
//            results[localNumber - 1] = "EAST,EAST,EAST,EAST,W1,W1,W3,W4,W5,W6,W8,W8,W8";
//            mahjongBox.mahjongsOfPlayers[localNumber - 1] = "EAST,EAST,EAST,EAST,W1,W1,W3,W4,W5,W6,W8,W8,W8".split(/,/);
            // FIXME TEST PART END
            var mahjongSequence:String = results[localNumber - 1];
            var mahjongNames:Array = PushdownWinGame.sortMahjongs(mahjongSequence);

            // 为当前玩家发牌
            for each (var mahjongName:String in mahjongNames) {
                addMahjongDown(currentGame.candidatedDown, "down", "standard", mahjongName);
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
                    addMahjongExceptDown(mahjongsCandidated, playerDirectionArray[index], "standard", "DEFAULT");
                }
                index++;
            }
            // 操作按钮初始化
            resetBtnBar();

            this._myPuppet.dealMahjong = dealMahjong; // 将打出麻将操作赋值给puppet对象
            this._myPuppet.dispatchEvent(new GamePinocchioEvent(
                GamePinocchioEvent.GAME_START, 
                null, 
                currentGame.candidatedDown.getChildren()));
        }

        /**
         * 
         * 游戏开始后为当前玩家添加麻将组件
         * 
         * @param container
         * @param picPath
         * @return 
         * 
         */
        private function addMahjongDown(
                container:DisplayObjectContainer, 
                direction:String,
                style:String,
                name:String):MahjongButton {
            var mahjong:MahjongButton = new MahjongButton();
            mahjong.source = MahjongResource.load(direction, style, name);
            ListenerBinder.bind(mahjong, MouseEvent.CLICK, function (event:MouseEvent):void {
                dealMahjong(mahjong);
            });
            container.addChild(mahjong);
            return mahjong;
        }

        /**
         * 
         * 游戏开始后为非当前玩家添加麻将组件
         *  
         * @param container
         * @param picPath
         * @return 
         * 
         */
        private function addMahjongExceptDown(
                container:DisplayObjectContainer, 
                direction:String,
                style:String,
                name:String):MahjongButton {
            var mahjong:MahjongButton = new MahjongButton();
            mahjong.allowSelect = false;
            mahjong.source = MahjongResource.load(direction, style, name);
            container.addChild(mahjong);
            return mahjong;
        }

        /**
         *
         * 当前玩家为第一个发牌者时，开始进行游戏设置
         *
         * @param event
         *
         */
        private function gameFirstPlayHandler(event:PushdownWinGameEvent):void {
            var firstPlayerNumber:int = parseInt(event.incomingData);
            if (localNumber == firstPlayerNumber) {
                // 开始摸牌
                var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
                dummyEvent.index = PushdownWinGame.OPTR_RAND;
                itemClick(dummyEvent);
                // 显示操作按钮
                currentGame.btnBarMahjongs.visible = true;
                timer.reset();
                timer.start();
            } else {
                updateOtherTip(-1, firstPlayerNumber);
            }
        }

        /**
         *
         * 接收到系统通知当前玩家出牌的消息<br>
         * 数据格式为：
         * <ul>
         * <li>摸牌：发牌玩家序号~牌名</li>
         * <li>发牌：发牌玩家序号~牌名~发牌玩家的下家序号(pass)?</li>
         * <li>吃碰杠：发牌玩家序号~牌序~发牌玩家的下家序号~被发牌玩家执行了操作的玩家序号~被操作牌~动作索引</li>
         * <li>放弃：发牌玩家序号~牌名~发牌玩家的下家序号~执行放弃操作的玩家索引列表(列表内容为：012或01或0……)</li>
         * </ul>
         * 
         * @param event
         *
         */
        private function gameBringOutHandler(event:PushdownWinGameEvent):void {
            // 接收上家出牌序列，显示出牌结果
            var results:Array = event.incomingData.split("~");
            currentNumber = results[0];
            currentBoutMahjong = results[1];
            if (results.length > 2) {
                currentNextNumber = results[2];
            }

            // 处理消息
            switch (results.length) {
                case 2:
                	// 摸牌
                	handleBoutRand();
                    break;
                case 3:
                	// 出牌
                	handleBoutDeal();
                    break;
                case 6:
                	// 吃碰杠
            	    handleBoutOperation(int(results[3]), results[4], results[5]);
                    break;
                case 4:
                	// 放弃
                	currentGiveupIndice = results[3]; 
                    handleBoutDeal(false);
                    break;
                default:
                    throw Error("其他无法预测的接牌动作！");
            }
        }

		/**
		 * 
		 * 响应玩家摸牌动作
		 * 
		 */
		private function handleBoutRand():void {
            // 玩家摸牌时，更新模型
            mahjongBox.randomMahjong();
            currentGame.leftNumber.text = String(parseInt(currentGame.leftNumber.text) - 1);
            mahjongBox.importMahjong(currentNumber - 1, currentBoutMahjong);
            // 更新牌墙
            if (isKongFlag) {
                currentGame.greatWall.hideTailMahjong();
                isKongFlag = !isKongFlag;
            } else {
                currentGame.greatWall.hideHeadMahjong();
            }
            // 玩家摸牌时，更新布局
        	var boutMahjongButton:MahjongButton = new MahjongButton();
            boutMahjongButton.allowSelect = false;
            boutMahjongButton.source = MahjongResource.load(playerDirectionArray[currentNumber - 1], "standard", "DEFAULT");
            Box(mahjongsRandArray[currentNumber - 1]).removeAllChildren();
            Box(mahjongsRandArray[currentNumber - 1]).addChild(boutMahjongButton);
		}

		/**
		 * 
		 * 响应玩家出牌、放弃动作
		 * 
         * @param notGiveUp 是否针对放弃操作
         * 
		 */
		private function handleBoutDeal(notGiveUp:Boolean = true):void {
            if (notGiveUp) {
                // 玩家出牌时，更新模型与布局
                mahjongBox.exportMahjong(currentNumber - 1, currentBoutMahjong);
                mahjongBox.discardMahjong(currentBoutMahjong);
            	var boutMahjongButton:MahjongButton = new MahjongButton();
                boutMahjongButton.allowSelect = false;
                boutMahjongButton.source = MahjongResource.load("down", "dealed", currentBoutMahjong);
            	currentGame.dealed.addChild(boutMahjongButton);
            	// 移除摸牌区域的牌
            	currentGame.randRight.removeAllChildren();
            	currentGame.randUp.removeAllChildren();
            	currentGame.randLeft.removeAllChildren();
            }

            // 初始化操作按钮
            resetBtnBar();

			// 从非出牌玩家中，找出唯一一个可以进行胡牌、杠牌或碰牌操作的玩家
			// 玩家的优先权取决于操作权（如胡牌优先权最高，其次是杠牌，再次是碰牌）
//			var finalMixedIndex:int = -1, winMixedIndex:int = -1, kongMixedIndex:int = -1, pongMixedIndex:int = -1;
//			var canWin:Boolean = false, canKong:Boolean = false, canPong:Boolean = false;
//			var indexWin:int = -1, indexKong:int = -1, indexPong:int = -1;
//			// 胡牌情况
//			indexWin = PushdownWinGame.isWin(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + (notGiveUp ? "" : currentGiveupIndice));
//			canWin = indexWin > -1;
//			if (canWin) {
//			    winMixedIndex = indexWin;
//			}
//		    // 杠牌情况
//			indexKong = PushdownWinGame.isKong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + (notGiveUp ? "" : currentGiveupIndice));
//			canKong = indexKong > -1;
//			if (canKong) {
//			    kongMixedIndex = indexKong;
//			}
//		    // 碰牌情况
//			indexPong = PushdownWinGame.isPong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + (notGiveUp ? "" : currentGiveupIndice));
//			canPong = indexPong > -1;
//			if (canPong) {
//			    pongMixedIndex = indexPong;
//			}
//			// 确定优先级最高的玩家混合索引值，混合值的构成为：玩家索引 × 10 + 动作编号
//			if (canWin) {
//			    finalMixedIndex = indexWin;
//			} else if (canKong) {
//			    finalMixedIndex = indexKong;
//			} else if (canPong) {
//			    finalMixedIndex = indexPong;
//			}
            var nextContext:Object = findNextOperationContext(String(currentNumber - 1) + (notGiveUp ? "" : currentGiveupIndice));
            var finalMixedIndex:int = nextContext.finalMixedIndex;
            var canWin:Boolean = nextContext.canWin, canKong:Boolean = nextContext.canKong, canPong:Boolean = nextContext.canPong; 

			// 准备胡杠碰操作
			// 最终执行操作的玩家索引
			var playerIndex:int = finalMixedIndex % 10;
            if (finalMixedIndex > -1 && playerIndex == localNumber - 1) {
	     		// 胡牌、杠牌、碰牌玩家为当前玩家时

				// 更改操作按钮状态
	  			var operationList:Array = [
		  			function ():void {
						if (canWin) {
							// 胡牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_WIN)).enabled = true;
						}
		  			},
		  			function ():void {
						if (canKong) {
							// 杠牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_KONG)).enabled = true;
						}
		  			},
		  			function ():void {
						if (canPong) {
							// 碰牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_PONG)).enabled = true;
						}
		  			}
		     	];
		     	for (var i:int = finalMixedIndex / 10; i < 3; i++) {
		     		operationList[i]();
		     	}
		     	if (currentNextNumber == localNumber) {
		     	    // 当前玩家为出牌玩家的下家时
		     	    // 启用摸牌按钮
	     		    Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_RAND)).enabled = true;
		     		// 启用吃牌按钮
	     		    var canChow:Boolean = PushdownWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])
	     		    Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_CHOW)).enabled = canChow;
		     	} else {
		     	    // 当前玩家不是出牌玩家下家时
                    // 启用放弃按钮
	     		    Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_GIVEUP)).enabled = true;
	     		}
                currentGame.btnBarMahjongs.visible = true;
	     	} else if (finalMixedIndex < 0 && currentNextNumber == localNumber) {
	     		// 没有玩家胡牌、杠牌、胡牌时，为当前玩家出牌做准备
				// 吃牌判断
		     	if (PushdownWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])) {
		     		// 启用吃牌按钮
		     		Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_CHOW)).enabled = true;
		     		// 启用摸牌按钮
		     		Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_RAND)).enabled = true;
                	// 为出牌玩家设置麻将操作按钮外观
                    currentGame.btnBarMahjongs.visible = true;
		     	} else {
                	// 为出牌玩家设置麻将操作按钮外观
                    currentGame.btnBarMahjongs.visible = true;
                    // 自动摸牌
    	            var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
    	            dummyEvent.index = PushdownWinGame.OPTR_RAND;
    	            itemClick(dummyEvent);
	            }
            } else {
                // 更新提示
                updateOtherTip(-1, playerIndex > -1 ? playerIndex + 1 : currentNextNumber);
            }
		}

		/**
		 * 
		 * 响应玩家吃杠碰牌动作
		 * 
		 * @param operatedNumber 消息中被当前玩家操作了的玩家序号
		 * @param operatedMahjong 消息中被当前玩家操作了的麻将值
		 * @param operationIndex 消息中所执行的操作动作索引
		 * 
		 */
		private function handleBoutOperation(operatedNumber:int, operatedMahjong:String, operationIndex:int):void {
        	// 玩家杠牌时
        	var eachMahjongValue:String = null;
        	var boutMahjongButton:MahjongButton = null;
        	var sourcePath:Class = null;
        	var removedCount:int = -1;
        	if (operationIndex == PushdownWinGame.OPTR_KONG) {
        		// 杠牌时
                // 更新杠牌标识
                isKongFlag = !isKongFlag;
        		// 基于碰牌的杠牌，更新模型与布局
        		if (currentNumber == operatedNumber && 
        		        Box(mahjongsDaisArray[currentNumber - 1]).getChildren().join(",").indexOf(operatedMahjong + "," + operatedMahjong + "," + operatedMahjong) > -1) {
        		    mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
        		    // 移除玩家摸牌区域的牌
		            Box(mahjongsRandArray[currentNumber - 1]).removeAllChildren();
        		    // 为亮牌区域添加杠牌
                	boutMahjongButton = new MahjongButton();
		            boutMahjongButton.allowSelect = false;
		            boutMahjongButton.source = MahjongResource.load(playerDirectionArray[currentNumber - 1], "dealed", operatedMahjong);
		            for (var i:int = 0; i < Box(mahjongsDaisArray[currentNumber - 1]).getChildren().length; i++) {
        			    if (boutMahjongButton.value == Box(mahjongsDaisArray[currentNumber - 1]).getChildAt(i).toString()) {
        			        Box(mahjongsDaisArray[currentNumber - 1]).addChildAt(boutMahjongButton, i);
        			        break;
        			    }
		            }
		            return;
        		}
                // 普通明杠和暗杠，更新模型与布局
            	if (currentNumber == operatedNumber) {
	                // 玩家暗杠时
                    mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
		            sourcePath = MahjongResource.load(playerDirectionArray[currentNumber - 1], "dealed", "DEFAULT");
		            // 移除玩家摸牌区域的牌
		            Box(mahjongsRandArray[currentNumber - 1]).removeAllChildren();
            	} else {
	                // 玩家明杠时
	                mahjongBox.mahjongsOnTable.pop();
                    mahjongBox.importMahjong(currentNumber - 1, operatedMahjong);
                    mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
		            sourcePath = MahjongResource.load(playerDirectionArray[currentNumber - 1], "dealed", operatedMahjong);
                    // 移除桌面中最后一张打出的牌
                    currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1);
            	}
                for each (eachMahjongValue in currentBoutMahjong.split(",")) {
                	boutMahjongButton = new MahjongButton();
		            boutMahjongButton.allowSelect = false;
		            boutMahjongButton.source = sourcePath;
        			Box(mahjongsDaisArray[currentNumber - 1]).addChild(boutMahjongButton);
                }
                // 移除玩家手中牌
                removedCount = 3;
                while (removedCount > 0) {
                    Box(mahjongsCandidatedArray[currentNumber - 1]).removeChildAt(0);
                    removedCount--;
                }
            } else if (operationIndex == PushdownWinGame.OPTR_PONG) {
        		// 碰牌时
                // 更新模型
                mahjongBox.mahjongsOnTable.pop();
                mahjongBox.importMahjong(currentNumber - 1, operatedMahjong);
                mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
                // 更新布局
	            sourcePath = MahjongResource.load(playerDirectionArray[currentNumber - 1], "dealed", operatedMahjong);
                for each (eachMahjongValue in currentBoutMahjong.split(",")) {
                	boutMahjongButton = new MahjongButton();
		            boutMahjongButton.allowSelect = false;
		            boutMahjongButton.source = sourcePath;
        			Box(mahjongsDaisArray[currentNumber - 1]).addChild(boutMahjongButton);
                }
                // 移除玩家手中牌
                removedCount = 2;
                while (removedCount > 0) {
                    Box(mahjongsCandidatedArray[currentNumber - 1]).removeChildAt(0);
                    removedCount--;
                }
                // 移除桌面中最后一张打出的牌
                currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1);
        	} else if (operationIndex == PushdownWinGame.OPTR_CHOW) {
        		// 吃牌时
                // 更新模型
                mahjongBox.mahjongsOnTable.pop();
                mahjongBox.importMahjong(currentNumber - 1, operatedMahjong);
                mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
                // 更新布局
                for each (eachMahjongValue in currentBoutMahjong.split(",")) {
                	boutMahjongButton = new MahjongButton();
		            boutMahjongButton.allowSelect = false;
		            boutMahjongButton.source = MahjongResource.load(playerDirectionArray[currentNumber - 1], "dealed", eachMahjongValue);
        			Box(mahjongsDaisArray[currentNumber - 1]).addChild(boutMahjongButton);
                }
                // 移除玩家手中牌
                removedCount = 2;
                while (removedCount > 0) {
                    Box(mahjongsCandidatedArray[currentNumber - 1]).removeChildAt(0);
                    removedCount--;
                }
                // 移除桌面中最后一张打出的牌
                currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1);
        	} else {
        		throw Error("无法处理当前动作类型！");
        	}
		}

//		/**
//		 * 
//		 * 响应玩家放弃动作
//		 * 
//		 * @param giveupPlayerNumbers
//		 * @param isPass
//		 * 
//		 */
//		private function handleBoutGiveup():void {
//            // 初始化操作按钮
//            resetBtnBar();
//
//			// 从非出牌玩家中，找出唯一一个可以进行胡牌、杠牌或碰牌操作的玩家
//			// 玩家的优先权取决于操作权（如胡牌优先权最高，其次是杠牌，再次是碰牌）
//			var finalMixedIndex:int = -1, winMixedIndex:int = -1, kongMixedIndex:int = -1, pongMixedIndex:int = -1;
//			var canWin:Boolean = false, canKong:Boolean = false, canPong:Boolean = false;
//			var indexWin:int = -1, indexKong:int = -1, indexPong:int = -1;
//			// 胡牌情况
//			indexWin = PushdownWinGame.isWin(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + currentGiveupIndice);
//			canWin = indexWin > -1;
//			if (canWin) {
//			    winMixedIndex = indexWin;
//			}
//		    // 杠牌情况
//			indexKong = PushdownWinGame.isKong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + currentGiveupIndice);
//			canKong = indexKong > -1;
//			if (canKong) {
//			    kongMixedIndex = indexKong;
//			}
//		    // 碰牌情况
//			indexPong = PushdownWinGame.isPong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + currentGiveupIndice);
//			canPong = indexPong > -1;
//			if (canPong) {
//			    pongMixedIndex = indexPong;
//			}
//			// 确定优先级最高的玩家混合索引值，混合值的构成为：玩家索引 × 10 + 动作编号
//			if (canWin) {
//			    finalMixedIndex = indexWin;
//			} else if (canKong) {
//			    finalMixedIndex = indexKong;
//			} else if (canPong) {
//			    finalMixedIndex = indexPong;
//			}
//
//			// 准备胡杠碰操作
//			// 最终执行操作的玩家索引
//			var playerIndex:int = finalMixedIndex % 10;
//	     	if (finalMixedIndex > -1 && playerIndex == localNumber - 1) {
//	     		// 胡牌、杠牌、碰牌玩家为当前玩家时
//
//				// 更改操作按钮状态
//	  			var operationList:Array = [
//		  			function ():void {
//						if (canWin) {
//							// 胡牌，为出牌玩家设置麻将操作按钮外观
//							Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_WIN)).enabled = true;
//						}
//		  			},
//		  			function ():void {
//						if (canKong) {
//							// 杠牌，为出牌玩家设置麻将操作按钮外观
//							Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_KONG)).enabled = true;
//						}
//		  			},
//		  			function ():void {
//						if (canPong) {
//							// 碰牌，为出牌玩家设置麻将操作按钮外观
//							Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_PONG)).enabled = true;
//						}
//		  			}
//		     	];
//		     	for (var i:int = finalMixedIndex / 10; i < 3; i++) {
//		     		operationList[i]();
//		     	}
//		     	if (currentNextNumber == localNumber) {
//		     	    // 当前玩家为出牌玩家的下家时
//                    // 启用摸牌按钮
//	     		    Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_RAND)).enabled = true;
//                    // 启用吃牌按钮
//	     		    var canChow:Boolean = PushdownWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])
//	     		    Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_CHOW)).enabled = canChow;
//		     	} else {
//		     	    // 当前玩家不是出牌玩家下家时
//                    // 启用放弃按钮
//	     		    Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_GIVEUP)).enabled = true;
//	     		}
//                currentGame.btnBarMahjongs.visible = true;
//	     	} else if (finalMixedIndex < 0 && currentNextNumber == localNumber) {
//	     		// 没有玩家胡牌、杠牌、胡牌时，为当前玩家出牌做准备
//				// 吃牌判断
//		     	if (PushdownWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])) {
//		     		// 启用吃牌按钮
//		     		Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_CHOW)).enabled = true;
//		     		// 启用摸牌按钮
//		     		Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_RAND)).enabled = true;
//                	// 为出牌玩家设置麻将操作按钮外观
//                    currentGame.btnBarMahjongs.visible = true;
//		     	} else {
//                	// 为出牌玩家设置麻将操作按钮外观
//                    currentGame.btnBarMahjongs.visible = true;
//                    // 自动摸牌
//    	            var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
//    	            dummyEvent.index = PushdownWinGame.OPTR_RAND;
//    	            itemClick(dummyEvent);
//                }
//            } else {
//                // 更新提示
//                updateOtherTip(-1, playerIndex > -1 ? playerIndex + 1 : currentNextNumber);
//            }
//		}

        /**
         *
         * 接收到当前玩家为第一个发牌者通知
         *
         * @param event
         *
         */
        private function gameInterruptedHandler(event:PushdownWinGameEvent):void {
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
        private function gameOverHandler(event:PushdownWinGameEvent):void {
            // 格式：发牌玩家~牌序(~接牌玩家)?~得分结果
            // 得分结果样例(编号，得分，系统积分，玩家积分【仅显示当前玩家积分，其他玩家为空】)：3,30,0;2,30,0;4,30,0;1,30,0
            var results:Array = event.incomingData.split("~");
            var scoreboardInfo:Array = String(results[results.length - 1]).split(/;/);
            // 显示记分牌
            if ((results.length == 3) || (results.length == 4)) {
                // 显示记分牌
//	            new Scoreboard().popUp(localNumber, scoreboardInfo, currentGameId,
//			            function():void {
//			            	gameClient.currentState = 'LOBBY';
//			            });
	            currentNumber = results[0];
	            currentBoutMahjong = results[1];
	            if (results.length == 4) {
	            	currentNextNumber = results[2];
	            }
            }
            var gameResult:int = -1;
            switch (results.length) {
                case 3:
                    gameResult = PushdownWinGameSetting.CLEAR_VICTORY;
                    break;
                case 4:
                    gameResult = PushdownWinGameSetting.NARROW_VICTORY;
                    break;
                default:
                    gameResult = PushdownWinGameSetting.NOBODY_VICTORY;
                    break;
            }
            var misc:Object = {GAME_TYPE : "PushdownWinGame",
                TITLE : PushdownWinGameSetting.getDisplayName(gameResult)};
            this._myPuppet.dispatchEvent(
                new GamePinocchioEvent(
                    GamePinocchioEvent.GAME_END, 
                    null, 
                    new Scoreboard().popUp(
                        localNumber, 
                        scoreboardInfo, 
                        currentGameId,
                        function():void {
                            gameClient.currentState = 'LOBBY';
                        }, 
                        misc)
                )
            );

            // 停止提示
            if (otherTimer.running) {
                otherTimer.stop();
            }
            CursorManager.removeBusyCursor();
            // 显示游戏积分
            var currentIndex:int = -1;
			var winnerMahjongSeq:Array = null;
            var mahjongValue:String = null;
            var mahjongButton:MahjongButton = null;
            if (results.length == 3) {
            	// 自摸
            	gameClient.txtSysMessage.text += "推倒胡游戏结束，玩家#1自摸获胜！\n".replace(/#1/, currentNumber);
            	if (currentNumber == localNumber) {
            	    return;
            	}
				// 显示获胜玩家牌
				currentIndex = currentNumber - 1;
				winnerMahjongSeq = (mahjongBox.mahjongsOfPlayers[currentIndex] as Array);
				mahjongValue = winnerMahjongSeq.pop();
				winnerMahjongSeq = PushdownWinGame.sortMahjongs(winnerMahjongSeq.join(",")).reverse();
				// 摸牌区域
				Box(mahjongsRandArray[currentIndex]).removeAllChildren();
				mahjongButton = new MahjongButton();
				mahjongButton.allowSelect = false;
				mahjongButton.source = MahjongResource.load(playerDirectionArray[currentIndex], "dealed", mahjongValue);
				Box(mahjongsRandArray[currentIndex]).addChild(mahjongButton);
				// 待发牌区域
				Box(mahjongsCandidatedArray[currentIndex]).removeAllChildren();
                if (mahjongsCandidatedArray[currentIndex] is VBox) {
                    VBox(mahjongsCandidatedArray[currentIndex]).setStyle("verticalGap", -8);
                }
				for each (mahjongValue in winnerMahjongSeq) {
					mahjongButton = new MahjongButton();
					mahjongButton.allowSelect = false;
					mahjongButton.source = MahjongResource.load(playerDirectionArray[currentIndex], "dealed", mahjongValue);
					mahjongButton.setStyle("padding-bottom", 20);
					Box(mahjongsCandidatedArray[currentIndex]).addChild(mahjongButton);
				}
            } else if (results.length == 4) {
            	// 点炮
            	gameClient.txtSysMessage.text += "推倒胡游戏结束，玩家#1为玩家#2点炮！\n".replace(/#1/, results[2]).replace(/#2/, results[0]);
            	if (currentNumber == localNumber) {
            	    return;
            	}
				// 显示获胜玩家牌
				currentIndex = currentNumber - 1;
				winnerMahjongSeq = (mahjongBox.mahjongsOfPlayers[currentIndex] as Array);
				winnerMahjongSeq = PushdownWinGame.sortMahjongs(winnerMahjongSeq.join(",")).reverse();
				// 待发牌区域
				Box(mahjongsCandidatedArray[currentIndex]).removeAllChildren();
                if (mahjongsCandidatedArray[currentIndex] is VBox) {
                    VBox(mahjongsCandidatedArray[currentIndex]).setStyle("verticalGap", -8);
                }
				for each (mahjongValue in winnerMahjongSeq) {
					mahjongButton = new MahjongButton();
					mahjongButton.allowSelect = false;
					mahjongButton.source = MahjongResource.load(playerDirectionArray[currentIndex], "dealed", mahjongValue);
					Box(mahjongsCandidatedArray[currentIndex]).addChild(mahjongButton);
				}
            } else {
            	gameClient.txtSysMessage.text += "推倒胡游戏结束，没有玩家获胜，流局！\n";
            }
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
            resetBtnBar();
            switch (event.index) {
                case 0:
                    // 胡牌
                    if (isNarrowWin) {
                        // 自摸
                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END, 
                            localNumber + "~" + MahjongButton(currentGame.randDown.getChildAt(0)).value +
                            "~" + mahjongBox.mahjongsStringOfPlayers);
                    } else {
                        // 非自摸
                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END, 
                            localNumber + "~" + currentBoutMahjong + "~" + currentNumber +
                            "~" + mahjongBox.mahjongsStringOfPlayers);
                    }
                    currentGame.btnBarMahjongs.visible = false;
                    break;
                case 1:
                    // 杠
                    // 更新杠牌标识
                    isKongFlag = !isKongFlag;
                    var randValueForKong:String = currentGame.randDown.numChildren > 0 ? currentGame.randDown.getChildAt(0).toString() : null;
                    if (randValueForKong/* && currentNextNumber == localNumber*/) {
                        i = 0;
                        isKongFlag = !isKongFlag; // 还原杠标识，因为尚未实施杠操作
                        var eachKongableMahjongs:String = null;
                        var kongableMahjongArray:Array = [];
                        // 显示提示
                        for each (eachKongableMahjongs in currentGame.candidatedDown.getChildren().join(",").match(/(\w+),\1,\1,\1/g)) {
                            // 延迟暗杠
                            // *四张候选牌
                            kongableMahjongArray[i++] = eachKongableMahjongs.split(",")[0];
                        }
                        for each (eachKongableMahjongs in currentGame.daisDown.getChildren().join(",").match(/(\w+),\1,\1/g)) {
                            // 延迟明杠
                            if (currentGame.candidatedDown.getChildren().join(",").concat(",").indexOf(eachKongableMahjongs.split(",")[0] + ",") > -1) {
                                // *一张候选牌配合三张碰牌
                                kongableMahjongArray[i++] = eachKongableMahjongs.split(",")[0];
                            } else if (randValueForKong == eachKongableMahjongs.split(",")[0]) {
                                // *一张摸牌配合三张碰牌
                                kongableMahjongArray[i++] = eachKongableMahjongs.split(",")[0];
                            }
                        }
                        for each (eachKongableMahjongs in currentGame.candidatedDown.getChildren().join(",").match(/(\w+),\1,\1/g)) {
                            // 即时暗杠
                            if (randValueForKong == eachKongableMahjongs.split(",")[0]) {
                                // *一张摸牌配合三张候选牌
                                kongableMahjongArray[i++] = eachKongableMahjongs.split(",")[0];
                                break;
                            }
                        }
                        // 显示杠牌提示栏
                        while (i-- > 0) {
                            for each (var eachKangableMahjong:MahjongButton in (currentGame["toolTipKong" + (i + 1)] as Container).getChildren()) {
                                eachKangableMahjong.source = MahjongResource.load(null, null, kongableMahjongArray[i], eachKangableMahjong.source);
                            }
                            (currentGame["toolTipKong" + (i + 1)] as Container).visible = true;
                        }
                        return;
//                    } else if (randValueForKong && 
//                            currentGame.daisDown.getChildren().join(",").indexOf(randValueForKong + "," + randValueForKong + "," + randValueForKong) > -1) {
//                        // 基于碰牌的杠，更新内存模型与外观
//                        mahjongBox.moveMahjongToDais(localNumber - 1, randValueForKong);
//                        var randMahjongButton:MahjongButton = MahjongButton(currentGame.randDown.getChildAt(0));
//                        randMahjongButton.source = MahjongResource.load(null, "dais", null, randMahjongButton.source);
//                        for (i = 0; i < currentGame.daisDown.getChildren().length; i++) {
//                            if (currentGame.daisDown.getChildAt(i).toString() == randMahjongButton.value) {
//                                currentGame.daisDown.addChildAt(randMahjongButton, i);
//                                break;
//                            }
//                        }
//                        // 移除摸牌区域中参与杠操作的牌
//                        currentGame.randDown.removeAllChildren();
//                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
//                                new Array(randValueForKong, randValueForKong, randValueForKong, randValueForKong).join(",") + "~" + 
//                                localNextNumber + "~" + localNumber + "~" + randValueForKong + "~" + PushdownWinGame.OPTR_KONG);
                    } else {
//                        // 直接的明杠和暗杠，更新内存模型与外观
//                        if (randValueForKong) {
//                            // 暗杠时
//                            mahjongBox.moveMahjongToDais(localNumber - 1, new Array(randValueForKong, 
//                                                                                    randValueForKong, 
//                                                                                    randValueForKong, 
//                                                                                    randValueForKong).join(","));
//                            for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
//                                if (randValueForKong == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
//                                    break;
//                                }
//                            }
//                        } else {
                            // 明杠时
                            mahjongBox.mahjongsOnTable.pop();
                            mahjongBox.importMahjong(localNumber - 1, currentBoutMahjong);
                            mahjongBox.moveMahjongToDais(localNumber - 1, new Array(currentBoutMahjong, 
                                                                                    currentBoutMahjong, 
                                                                                    currentBoutMahjong, 
                                                                                    currentBoutMahjong).join(","));
                            for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                                if (currentBoutMahjong == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                                    break;
                                }
                            }
//                        }
                        var mahjongKong1:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 2));
                        var mahjongKong2:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 1));
                        var mahjongKong3:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i));
                        var mahjongKong4:MahjongButton = new MahjongButton();
                        mahjongKong4.source = MahjongResource.load(null, null, null, mahjongKong1.source);
                        for each (var eachMahjongKong:MahjongButton in [mahjongKong1, mahjongKong2, mahjongKong3, mahjongKong4]) {
                            eachMahjongKong.allowSelect = false;
                            eachMahjongKong.source = MahjongResource.load(null, "dais", null, eachMahjongKong.source);
                            currentGame.daisDown.addChild(eachMahjongKong);
                        }
                        if (currentGame.randDown.numChildren > 0) {
                            // 暗杠
                            mahjongKong1.source = MahjongResource.load(null, null, "DEFAULT", mahjongKong1.source);
                            mahjongKong4.source = MahjongResource.load(null, null, "DEFAULT", mahjongKong4.source);
                        } else {
                            // 明杠
                            // 移除桌面中最后一张打出的牌
                            currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1);
                        }
                        // 发送杠牌命令(吃碰杠：发牌玩家序号~牌序~发牌玩家的下家序号~被发牌玩家执行了操作的玩家序号~被操作牌~动作索引)
//                        if (currentGame.randDown.numChildren > 0) {
//                            // 暗杠
//                            // 移除摸牌区域中参与杠操作的牌
//                            currentGame.randDown.removeAllChildren();
//                            socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
//                                    new Array(mahjongKong2, mahjongKong2, mahjongKong3, mahjongKong3).join(",") + "~" + 
//                                    localNextNumber + "~" + localNumber + "~" + mahjongKong1.value + "~" + PushdownWinGame.OPTR_KONG);
//                        } else {
                            // 明杠
                            socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
                                    new Array(mahjongKong1, mahjongKong2, mahjongKong3, mahjongKong4).join(",") + "~" + 
                                    localNextNumber + "~" + currentNumber + "~" + mahjongKong1.value + "~" + PushdownWinGame.OPTR_KONG);
//                        }
                    }
    		        // 开始摸牌
    		        event = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
                    event.index = PushdownWinGame.OPTR_RAND;
                    itemClick(event);
                    break;
                case 2:
                    // 碰
                    // 更新内存模型
                    mahjongBox.mahjongsOnTable.pop();
                    mahjongBox.importMahjong(localNumber - 1, currentBoutMahjong);
                    mahjongBox.moveMahjongToDais(localNumber - 1, 
                            [currentBoutMahjong, currentBoutMahjong, currentBoutMahjong].join(","));
                    // 更新外观
                    for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                        if (currentBoutMahjong == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                            break;
                        }
                    }
                    for each (var eachMahjongPong:MahjongButton in [currentGame.candidatedDown.getChildAt(i + 1), 
                                                                    currentGame.candidatedDown.getChildAt(i),
                                                                    currentGame.dealed.getChildAt(currentGame.dealed.numChildren - 1)]) {
                        eachMahjongPong.allowSelect = false;
                        eachMahjongPong.source = MahjongResource.load(null, "dais", null, eachMahjongPong.source);
                        currentGame.daisDown.addChild(eachMahjongPong);
                    }
//                    var mahjongPong1:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 1));
//                    var mahjongPong2:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i));
//                    var mahjongPong3:MahjongButton = MahjongButton(currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1)); // 
//                    mahjongPong1.allowSelect = false;
//                    mahjongPong2.allowSelect = false;
//                    mahjongPong3.allowSelect = false;
//                    mahjongPong1.source = MahjongResource.load(null, "dais", null, mahjongPong1.source);
//                    mahjongPong2.source = MahjongResource.load(null, "dais", null, mahjongPong2.source);
//                    mahjongPong3.source = MahjongResource.load(null, "dais", null, mahjongPong1.source);
//                    currentGame.daisDown.addChild(mahjongPong1);
//                    currentGame.daisDown.addChild(mahjongPong2);
//                    currentGame.daisDown.addChild(mahjongPong3);
                    // 发送杠牌命令(吃碰杠：发牌玩家序号~牌序~发牌玩家的下家序号~被发牌玩家执行了操作的玩家序号~被操作牌~动作索引)
                    socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
                            [eachMahjongPong, eachMahjongPong, eachMahjongPong].join(",") + "~" + 
                            localNextNumber + "~" + currentNumber + "~" + eachMahjongPong.value + "~" + PushdownWinGame.OPTR_PONG);
                    break;
                case 3:
                    // 吃
		        	var color:String = currentBoutMahjong.charAt(0);
		        	var value:int = int(currentBoutMahjong.charAt(1));
		        	var headHeadMahjong:String = color + (value - 2);
		        	var headMahjong:String = color + (value - 1);
		        	var tailMahjong:String = color + (value + 1);
		        	var tailTailMahjong:String = color + (value + 2);
		        	// 左左吃
		        	var leftLeftValue:Array = new Array(headHeadMahjong, headMahjong, currentBoutMahjong);
		        	// 左吃右
		        	var leftValueRight:Array = new Array(headMahjong, currentBoutMahjong, tailMahjong);
		        	// 吃右右
		        	var valueRightRight:Array = new Array(currentBoutMahjong, tailMahjong, tailTailMahjong);
		        	// 当前玩家手中的牌
		        	var fullSeq:Array = (mahjongBox.mahjongsOfPlayers[localNumber - 1] as Array).slice(0);
		        	// 将当前玩家手中的牌与上家打出的牌合并
		        	fullSeq.push(currentBoutMahjong);
		        	fullSeq = fullSeq.sort();
					// 构造出牌提示
					var eachMahjongButton:MahjongButton = null;
					var eachIndex:int = 0;
                    for each (var eachCombination:* in [{values: leftLeftValue, tip: currentGame.toolTipChow1}, 
                                                        {values: leftValueRight, tip: currentGame.toolTipChow2}, 
                                                        {values: valueRightRight, tip: currentGame.toolTipChow3}]) {
                        if (fullSeq.join(",").replace(/(,?\w+)(,\1)/g, "$1").indexOf("" + eachCombination.values) > -1) {
                            for each (eachMahjongButton in (eachCombination.tip as Container).getChildren()) {
                                eachIndex = (eachCombination.tip as Container).getChildIndex(eachMahjongButton);
                                eachMahjongButton.source = MahjongResource.load(null, null, eachCombination.values[eachIndex], eachMahjongButton.source);
                            }
                            // 显示操作提示栏
                            (eachCombination.tip as Container).visible = true;
                        }
                    }
		        	// 激活操作栏中的放弃按钮
    		        Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_GIVEUP)).enabled = true;
                    break;
                case 4:
	            	// 放弃
        		    if ((!Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_WIN)).enabled &&
        		        !Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_KONG)).enabled &&
        		        !Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_PONG)).enabled) &&
        		        (Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_CHOW)).enabled || 
        		        currentGame.toolTipChow1.visible || currentGame.toolTipChow2.visible || currentGame.toolTipChow3.visible)) {
        		        // 在非胡牌、杠牌、碰牌的情况下，吃牌时。即除了吃牌动作外，无其他任何动作可以操作
	            	    resetBtnBar();
        		        currentGame.toolTipChow1.visible = false;
        		        currentGame.toolTipChow2.visible = false;
        		        currentGame.toolTipChow3.visible = false;
        		        // 开始摸牌
        		        event = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
                        event.index = PushdownWinGame.OPTR_RAND;
                        itemClick(event);
        		    } else {
            		    // 放弃：发牌玩家序号~牌名~发牌玩家的下家序号~执行放弃操作的玩家序号列表(列表内容为：123或12或1……)
            		    currentGiveupIndice += (localNumber - 1);
    	            	if (PushdownWinGame.isWin(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, (currentNumber - 1) + currentGiveupIndice) > -1) {
    	            	    // 有其他可以胡牌或杠牌或碰牌的玩家
    	            	    currentGame.btnBarMahjongs.visible = false;
                		    socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, 
                		        currentNumber + "~" + currentBoutMahjong + "~" + currentNextNumber + "~" + currentGiveupIndice);
    	            	} else if (PushdownWinGame.isKong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, (currentNumber - 1) + currentGiveupIndice) > -1) {
    	            	    // 有其他可以杠牌的玩家
    	            	    currentGame.btnBarMahjongs.visible = false;
                		    socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, 
                		        currentNumber + "~" + currentBoutMahjong + "~" + currentNextNumber + "~" + currentGiveupIndice);
    	            	} else if (PushdownWinGame.isPong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, (currentNumber - 1) + currentGiveupIndice) > -1) {
    	            	    // 有其他可以碰牌的玩家
    	            	    currentGame.btnBarMahjongs.visible = false;
                		    socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, 
                		        currentNumber + "~" + currentBoutMahjong + "~" + currentNextNumber + "~" + currentGiveupIndice);
    	            	} else if (currentNextNumber == localNumber) {
    	            	    // 当前玩家为发牌玩家下家时
    	            	    resetBtnBar();
            		        currentGame.toolTipChow1.visible = false;
            		        currentGame.toolTipChow2.visible = false;
            		        currentGame.toolTipChow3.visible = false;
            		        // 开始摸牌
            		        event = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
                            event.index = PushdownWinGame.OPTR_RAND;
                            itemClick(event);
    	            	} else {
    	            	    // 放弃当前(碰、杠)优先权，将优先权返还给发牌玩家的下家
    	            	    currentGame.btnBarMahjongs.visible = false;
    	            	    Alert.show("放弃当前优先权，将优先权返还给发牌玩家的下家");
                		    socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, 
                		        currentNumber + "~" + currentBoutMahjong + "~" + currentNextNumber + "~" + currentGiveupIndice);
                            var nextContext:Object = findNextOperationContext(String(localNumber - 1) + currentGiveupIndice);
                            var playerIndex:int = nextContext.finalMixedIndex > -1 ? nextContext.finalMixedIndex % 10 : nextContext.finalMixedIndex;
                            updateOtherTip(-1, playerIndex > -1 ? playerIndex + 1: currentNextNumber);
    	            	}
                    }
                    break;
                case 5:
                    // 摸牌
                    // 更新内存
                    var mahjongRandValue:String = mahjongBox.randomMahjong();
                    // 更新牌墙
                    if (isKongFlag) {
                        currentGame.greatWall.hideTailMahjong();
                        isKongFlag = !isKongFlag;
                    } else {
                        currentGame.greatWall.hideHeadMahjong();
                    }
                    if (mahjongRandValue == null) {
                        // 扑、流局
                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_WIN_AND_END);
                    } else {
                        // 更新内存
                        mahjongBox.importMahjong(localNumber - 1, mahjongRandValue);
                        // 更新布局
                        currentGame.leftNumber.text = String(parseInt(currentGame.leftNumber.text) - 1);
                        var mahjongRand:MahjongButton = new MahjongButton();
                        mahjongRand.source = MahjongResource.load("down", "standard", mahjongRandValue);
                        ListenerBinder.bind(mahjongRand, MouseEvent.CLICK, function (event:MouseEvent):void {
                            dealMahjong(mahjongRand);
                        });
                        currentGame.randDown.addChild(mahjongRand);
                        // 判断是否可以自摸、杠
                        if (PushdownWinGame.canWinNow(mahjongBox.mahjongsOfPlayers[localNumber - 1])) {
                        	// 自摸
                        	isNarrowWin = true;
                        	Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_WIN)).enabled = true;
                        }
                        if (PushdownWinGame.canKongNow(mahjongRandValue, currentGame.candidatedDown.getChildren().join(","), currentGame.daisDown.getChildren().join(","))) {
                        	// 杠
                        	Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_KONG)).enabled = true;
                        }
                        // TODO 显示操作按钮栏
                        currentGame.btnBarMahjongs.visible = true;
                        // 发送游戏命令
                        socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + mahjongRandValue);
                    }
                    break;
            }
        }

		/**
		 * 
		 * 根据选择的提示内容进行杠牌操作(该杠方案仅在当前玩家摸牌触发杠操作时有效)
		 * 
		 * @param event     事件对象
         * @param quickKong 专门处理
		 * 
		 */
		private function toolTipKongClick(event:MouseEvent, quickKong:Boolean = false):void {
		    if (!(event.currentTarget is MahjongButton)) {
		        return;
		    }
		    // 重置操作按钮栏
		    resetBtnBar();
		    // 隐藏所有提示栏
		    currentGame.toolTipKong1.visible = false;
		    currentGame.toolTipKong2.visible = false;
		    currentGame.toolTipKong3.visible = false;

			// 更新内存模型与视图
            var mahjongValue:String = (event.currentTarget as MahjongButton).toString();
            var mahjongCount:int = 0;
            var i:int = 0;
            var mahjongKong1:MahjongButton = null;
            var mahjongKong2:MahjongButton = null;
            var mahjongKong3:MahjongButton = null;
            var mahjongKong4:MahjongButton = null;
            var addSleepingKongMahjongs:Function = function (mahjongs:Array):void {
                for each (var eachMahjongKong:MahjongButton in mahjongs) {
                    eachMahjongKong.allowSelect = false;
                    eachMahjongKong.source = MahjongResource.load(null, "dais", null, eachMahjongKong.source);
                    currentGame.daisDown.addChild(eachMahjongKong);
                }
                (mahjongs[0] as MahjongButton).source = MahjongResource.load(null, null, "DEFAULT", (mahjongs[0] as MahjongButton).source);
                (mahjongs[3] as MahjongButton).source = MahjongResource.load(null, null, "DEFAULT", (mahjongs[3] as MahjongButton).source);
                this["called"] = true;
            };
            // 执行杠操作
            if (currentGame.candidatedDown.getChildren().join(",").match(new RegExp("(" + mahjongValue + "),\\1,\\1,\\1", "g")).length > 0) {
                // 完全延迟暗杠
                mahjongBox.moveMahjongToDais(localNumber - 1, [mahjongValue, mahjongValue, mahjongValue, mahjongValue].join(","));
                for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                    if (mahjongValue == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                        break;
                    }
                }
                mahjongKong1 = MahjongButton(currentGame.candidatedDown.getChildAt(i + 3));
                mahjongKong2 = MahjongButton(currentGame.candidatedDown.getChildAt(i + 2));
                mahjongKong3 = MahjongButton(currentGame.candidatedDown.getChildAt(i + 1));
                mahjongKong4 = MahjongButton(currentGame.candidatedDown.getChildAt(i));
                addSleepingKongMahjongs([mahjongKong1, mahjongKong2, mahjongKong3, mahjongKong4]);
            } else if (currentGame.candidatedDown.getChildren().join(",").match(new RegExp("(" + mahjongValue + "),\\1,\\1", "g")).length > 0 &&
                currentGame.randDown.getChildAt(0).toString() == mahjongValue) {
                // 摸牌引起即时暗杠
                mahjongBox.moveMahjongToDais(localNumber - 1, [mahjongValue, mahjongValue, mahjongValue, mahjongValue].join(","));
                for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                    if (mahjongValue == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                        break;
                    }
                }
                mahjongKong1 = MahjongButton(currentGame.candidatedDown.getChildAt(i + 2));
                mahjongKong2 = MahjongButton(currentGame.candidatedDown.getChildAt(i + 1));
                mahjongKong3 = MahjongButton(currentGame.candidatedDown.getChildAt(i));
                mahjongKong4 = MahjongButton(currentGame.randDown.getChildAt(0));
                addSleepingKongMahjongs([mahjongKong1, mahjongKong2, mahjongKong3, mahjongKong4]);
            } else if (currentGame.daisDown.getChildren().join(",").match(new RegExp("(" + mahjongValue + "),\\1,\\1", "g")).length > 0 &&
                currentGame.randDown.getChildAt(0).toString() == mahjongValue) {
                // 摸牌引起即时明杠
                mahjongBox.moveMahjongToDais(localNumber - 1, mahjongValue);
                for (i = 0; i < currentGame.daisDown.getChildren().length; i++) {
                    if (mahjongValue == MahjongButton(currentGame.daisDown.getChildAt(i)).value) {
                        break;
                    }
                }
                mahjongKong1.source = MahjongButton(currentGame.randDown.getChildAt(0));
                currentGame.daisDown.addChildAt(mahjongKong1, i);
                mahjongKong1.allowSelect = false;
                mahjongKong1.source = MahjongResource.load(null, "dais", null, mahjongKong1.source);
            } else if (currentGame.daisDown.getChildren().join(",").match(new RegExp("(" + mahjongValue + "),\\1,\\1", "g")).length > 0 &&
                currentGame.candidatedDown.getChildren().join(",").concat(",").indexOf(mahjongValue + ",") > -1) {
                // 候选牌引起延迟明杠 
                mahjongBox.moveMahjongToDais(localNumber - 1, mahjongValue);
                for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                    if (mahjongValue == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                        mahjongKong1 = MahjongButton(currentGame.candidatedDown.getChildAt(i));
                        break;
                    }
                }
                for (i = 0; i < currentGame.daisDown.getChildren().length; i++) {
                    if (mahjongValue == MahjongButton(currentGame.daisDown.getChildAt(i)).value) {
                        break;
                    }
                }
                currentGame.daisDown.addChildAt(mahjongKong1, i);
                mahjongKong1.allowSelect = false;
                mahjongKong1.source = MahjongResource.load(null, "dais", null, mahjongKong1.source);
            } else {
                throw new Error("未知杠操作！");
            }

            // 发送杠牌命令(吃碰杠：发牌玩家序号~牌序~发牌玩家的下家序号~被发牌玩家执行了操作的玩家序号~被操作牌~动作索引)
            if (addSleepingKongMahjongs["called"]) {
                // 暗杠
                socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
                    new Array(mahjongValue, mahjongValue, mahjongValue, mahjongValue).join(",") + "~" + 
                    localNextNumber + "~" + localNumber + "~" + 
                    [mahjongValue, mahjongValue, mahjongValue, mahjongValue].join(",") + "~" + 
                    PushdownWinGame.OPTR_KONG);
            } else {
                // 明杠
                socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
                    new Array(mahjongValue, mahjongValue, mahjongValue, mahjongValue).join(",") + "~" + 
                    localNextNumber + "~" + localNumber + "~" + mahjongValue + "~" + PushdownWinGame.OPTR_KONG);
            }

            // 将玩家摸牌区域与放牌区域的麻将合并后重新排序
            if (currentGame.randDown.numChildren > 0) {
                var mahjongsDown:Array = currentGame.candidatedDown.getChildren();
                var mahjongsNewDown:Array = mahjongsDown.concat(currentGame.randDown.getChildren());
                currentGame.candidatedDown.removeAllChildren();
                // 重新排序
                for each (var eachMahjongButton:MahjongButton in PushdownWinGame.sortMahjongButtons(mahjongsNewDown)) {
                    currentGame.candidatedDown.addChild(eachMahjongButton);
                }
            }

            // 更新杠标识
            isKongFlag = !isKongFlag;
            
            // 开始摸牌
            var randEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
            randEvent.index = PushdownWinGame.OPTR_RAND;
            itemClick(randEvent);
		}

        /**
         * 
         * 根据选择的提示内容进行吃牌操作
         * 
         * @param event
         * 
         */
        private function toolTipChowClick(event:MouseEvent):void {
            if (!(event.currentTarget is MahjongButton)) {
                return;
            }
            // 重置操作按钮栏
            resetBtnBar();
            // 隐藏所有提示栏
            currentGame.toolTipChow1.visible = false;
            currentGame.toolTipChow2.visible = false;
            currentGame.toolTipChow3.visible = false;
            
            // 更新内存模型与视图
            mahjongBox.importMahjong(localNumber - 1, mahjongBox.mahjongsOnTable.pop());
            mahjongBox.moveMahjongToDais(localNumber - 1, Box(MahjongButton(event.currentTarget).parent).getChildren().join(","));
            
            currentGame.dealed.getChildren().pop();
            var eachMahjongButton:MahjongButton = null;
            
            for each (eachMahjongButton in Box(MahjongButton(event.currentTarget).parent).getChildren()) {
                // 删除玩家手中参与吃牌动作的牌
                if (eachMahjongButton.value == currentBoutMahjong) {
                    // 跳过当前被吃的牌
                    continue;
                }
                for each (var eachMahjongToRemove:MahjongButton in currentGame.candidatedDown.getChildren()) {
                    // 移除吃牌序列中非被吃牌
                    if (eachMahjongButton.value == eachMahjongToRemove.value) {
                        currentGame.candidatedDown.removeChild(eachMahjongToRemove);
                        break;
                    }
                }
            }
            
            for each (eachMahjongButton in Box(MahjongButton(event.currentTarget).parent).getChildren()) {
                // 添加吃牌区域内容
                var daisMahjongButton:MahjongButton = new MahjongButton();
                daisMahjongButton.allowSelect = false;
                daisMahjongButton.source = MahjongResource.load(null, "dais", null, eachMahjongButton.source);
                currentGame.daisDown.addChild(daisMahjongButton);
            }
            
            // 移除桌面中最后一张打出的牌
            currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1);
            
            // 发牌玩家序号~牌序~发牌玩家的下家序号~被发牌玩家执行了操作的玩家序号~被操作牌~动作索引
            var message:String = localNumber + "~" + Box(MahjongButton(event.currentTarget).parent).getChildren().join(",") + "~" +localNextNumber + "~" + 
            currentNumber + "~" + currentBoutMahjong + "~" + PushdownWinGame.OPTR_CHOW; 
            socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, message);
        }

		/**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
		 * 
		 */
		private function show(event:FlexEvent):void {
			// 显示进度条，倒计时开始开始
            if (timer.running) {
                timer.stop();
                timer.reset();
            }
            timer.start();
            CursorManager.removeBusyCursor();
            // 激活PUPPET引擎
            this._myPuppet.dispatchEvent(new GamePinocchioEvent(GamePinocchioEvent.GAME_BOUT, null));
		}

		/**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动发牌<br>
		 * 打出摸牌区域的牌或按东南西北中发白万饼条打出最左边的一张
		 * 
         * @param event
         * 
		 */
		private function hide(event:FlexEvent):void {
			// 隐藏提示区域所有内容
            for each (var tipContainer:Container in currentGame.toolTipBar.getChildren()) {
                tipContainer.visible = false;
            }
            timer.stop();
            timer.reset();
            CursorManager.setBusyCursor();
		}

        /**
         *
         * 打出选中的麻将牌
         * 
         * @param mahjong
         * @return 
         * 
         */
        private function dealMahjong(mahjong:MahjongButton, callbackFunc:Function = null):void {
            // 发牌条件判断 
            if (!currentGame.btnBarMahjongs.visible || !mahjong.allowSelect) {
                return;
            }
            if (Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_GIVEUP)).enabled) {
                return;
            }
            if (Button(currentGame.btnBarMahjongs.getChildAt(PushdownWinGame.OPTR_RAND)).enabled) {
                return;
            }

            // 隐藏操作按钮
            currentGame.btnBarMahjongs.visible = false;

			// 更新布局
            // 从玩家手中牌删除选中牌
            mahjong.parent.removeChild(mahjong);
            // 将牌显示在桌面
            mahjong.allowSelect = false;
            mahjong.source = MahjongResource.load(null, "dealed", null, mahjong.source);
            currentGame.dealed.addChild(mahjong);

            // 将玩家摸牌区域与放牌区域的麻将合并后重新排序
            if (currentGame.randDown.numChildren > 0) {
                var mahjongsDown:Array = currentGame.candidatedDown.getChildren();
                var mahjongsNewDown:Array = mahjongsDown.concat(currentGame.randDown.getChildren());
                currentGame.candidatedDown.removeAllChildren();
                // 重新排序
                for each (var eachMahjongButton:MahjongButton in PushdownWinGame.sortMahjongButtons(mahjongsNewDown)) {
                    currentGame.candidatedDown.addChild(eachMahjongButton);
                }
            }

            // 更新内存模型
            mahjongBox.exportMahjong(localNumber - 1, mahjong.value);
            mahjongBox.discardMahjong(mahjong.value);

            // 发送出牌命令
            var nextContext:Object = findNextOperationContext(String(localNumber - 1));
            var playerIndex:int = nextContext.finalMixedIndex > -1 ? nextContext.finalMixedIndex % 10 : nextContext.finalMixedIndex;
            socketProxy.sendGameData(PushdownWinGameCommand.GAME_BRING_OUT, localNumber + "~" + mahjong.value + "~" + localNextNumber);
            
            // 执行回调函数
            if (callbackFunc != null) {
                callbackFunc();
            }
            
            // 更新提示信息
            updateOtherTip(-1, playerIndex > -1 ? playerIndex + 1: localNextNumber);
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
         * 更新游戏提示信息 ，该方法在调用时，均处于调用方法的底部
         * 
         * @param lastNumber 最后出牌或游戏设置玩家编号
         * @param nextNumber 准备出牌的玩家编号
         * @param showOtherTime 是否应用等待其他玩家信息
         * 
         */
        private function updateOtherTip(lastNumber:int, nextNumber:int, showOtherTime:Boolean = true):void {
            // 参数初始化
            currentNextNumber = nextNumber;
            // 从画面中清除已经使用过的倒计时
            for each (var eachTipArea:Container in mahjongsTipArray) {
                if (eachTipArea.numChildren > 0 && eachTipArea.getChildAt(eachTipArea.numChildren - 1) is GameWaiting) {
                    eachTipArea.removeChildAt(eachTipArea.numChildren - 1);
                }
            }
            
            if (showOtherTime && !currentGame.btnBarMahjongs.visible) {
                // 非当前玩家出牌时，显示动态提示
                if (otherTimer.running) {
                    otherTimer.stop();
                }
                // 保留已出牌，并显示倒计时
                var currentTipArea:Container = Container(mahjongsTipArray[nextNumber - 1]);
                if (currentTipArea.numChildren > 0 && currentTipArea.getChildAt(currentTipArea.numChildren - 1) is GameWaiting) {
                    (currentTipArea.getChildAt(currentTipArea.numChildren - 1) as GameWaiting).tipText = MAX_CARDS_SELECT_TIME.toString();
                } else {
                    var gameWaitingClock:GameWaiting = new GameWaiting();
                    gameWaitingClock.tipText = MAX_CARDS_SELECT_TIME.toString();
                    currentTipArea.addChild(gameWaitingClock);
                }
                otherTimer.reset();
                otherTimer.start();
            }
        }

        /**
         * 
         * 找出下一个可以优先操作牌的玩家
         * 
         * @param excludedIndice
         * @return 
         * 
         */
        private function findNextOperationContext(excludedIndice:String):Object {
            // 从非出牌玩家中，找出唯一一个可以进行胡牌、杠牌或碰牌操作的玩家
            // 玩家的优先权取决于操作权（如胡牌优先权最高，其次是杠牌，再次是碰牌）
            var finalMixedIndex:int = -1, winMixedIndex:int = -1, kongMixedIndex:int = -1, pongMixedIndex:int = -1;
            var canWin:Boolean = false, canKong:Boolean = false, canPong:Boolean = false;
            var indexWin:int = -1, indexKong:int = -1, indexPong:int = -1;
            // 胡牌情况
            indexWin = PushdownWinGame.isWin(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, excludedIndice);
            canWin = indexWin > -1;
            if (canWin) {
                winMixedIndex = indexWin;
            }
            // 杠牌情况
            indexKong = PushdownWinGame.isKong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, excludedIndice);
            canKong = indexKong > -1;
            if (canKong) {
                kongMixedIndex = indexKong;
            }
            // 碰牌情况
            indexPong = PushdownWinGame.isPong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, excludedIndice);
            canPong = indexPong > -1;
            if (canPong) {
                pongMixedIndex = indexPong;
            }
            // 确定优先级最高的玩家混合索引值，混合值的构成为：玩家索引 × 10 + 动作编号
            if (canWin) {
                finalMixedIndex = indexWin;
            } else if (canKong) {
                finalMixedIndex = indexKong;
            } else if (canPong) {
                finalMixedIndex = indexPong;
            }
            return {
                finalMixedIndex: finalMixedIndex,
                         canWin: canWin,
                        canKong: canKong,
                        canPong: canPong
            };
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
            currentGameId = null;
            localNumber = 0;
            localNextNumber = 0;
            currentNumber = 0;
            currentBoutMahjong = null;
            currentNextNumber = 0;
            currentGiveupIndice = null;
            isNarrowWin = false;
            for each (var containerArray:Array in [mahjongsCandidatedArray, mahjongsDaisArray, mahjongsRandArray, mahjongsTipArray]) {
                for each (var eachContainer:Container in containerArray) {
                    eachContainer.removeAllChildren();
                }
            }
            if (currentGame) {
                currentGame.dealed.removeAllChildren();
                currentGame.greatWall.hideAllMahjongs();
                currentGame.leftNumber.text = String(84);
            }
        }
    }
}