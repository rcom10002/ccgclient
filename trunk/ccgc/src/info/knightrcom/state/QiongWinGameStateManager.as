package info.knightrcom.state {
    import component.MahjongButton;
    import component.Scoreboard;
    
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.command.QiongWinGameCommand;
    import info.knightrcom.event.GameEvent;
    import info.knightrcom.event.QiongWinGameEvent;
    import info.knightrcom.state.qiongwingame.QiongWinGame;
    import info.knightrcom.state.qiongwingame.QiongWinMahjongBox;
    import info.knightrcom.util.ListenerBinder;
    
    import mx.containers.Box;
    import mx.containers.VBox;
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.controls.ProgressBarMode;
    import mx.events.FlexEvent;
    import mx.events.ItemClickEvent;
    import mx.states.State;

    /**
     *
     * 穷胡游戏状态管理器
     *
     */
    public class QiongWinGameStateManager extends AbstractGameStateManager {

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
         * 未占用的位置
         */
        public static const UNOCCUPIED_PLACE_NUMBER:int = -1;

		/**
		 * 用户发牌最大等待时间(秒)
		 */
		// private static const MAX_CARDS_SELECT_TIME:int = 15;
		// 测试用时间为10分钟
		private static const MAX_CARDS_SELECT_TIME:int = 5;// * 60;

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
		private static var mahjongBox:QiongWinMahjongBox;

		/**
		 * 计时器
		 */
		private static var timer:Timer = new Timer(1000, MAX_CARDS_SELECT_TIME);

        /**
         * 当前游戏模块
         */
		private static var currentGame:CCGameQiongWin = null;

        /**
         *
         * @param socketProxy
         * @param currentGame
         * @param myState
         *
         */
        public function QiongWinGameStateManager(socketProxy:GameSocketProxy, myState:State):void {
            super(socketProxy, myState);
            ListenerBinder.bind(myState, FlexEvent.ENTER_STATE, init);
            batchBindGameEvent(QiongWinGameEvent.EVENT_TYPE, new Array(
                    GameEvent.GAME_WAIT, gameWaitHandler,
                    GameEvent.GAME_CREATE, gameCreateHandler,
            		GameEvent.GAME_STARTED, gameStartedHandler,
            		GameEvent.GAME_FIRST_PLAY, gameFirstPlayHandler,
            		GameEvent.GAME_BRING_OUT, gameBringOutHandler,
            		GameEvent.GAME_INTERRUPTED, gameInterruptedHandler,
//            		GameEvent.GAME_WINNER_PRODUCED, gameWinnerProducedHandler,
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
            	currentGame = gameClient.qiongWinGameModule;
				ListenerBinder.bind(timer, TimerEvent.TIMER, function(event:TimerEvent):void {
					currentGame.timerTip.setProgress(MAX_CARDS_SELECT_TIME - timer.currentCount, MAX_CARDS_SELECT_TIME);
					// DROP THIS LINE currentGame.timerTip.label = "剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME - timer.currentCount);
					if (timer.currentCount == MAX_CARDS_SELECT_TIME) {
                        var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
					    if (Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_RAND)).enabled) {
					        // 执行摸牌动作
                            dummyEvent.index = QiongWinGame.OPTR_RAND;
                            itemClick(dummyEvent);
                            timer.reset();
                            timer.start();
					    } else if (Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_GIVEUP)).enabled) {
					        // 执行放弃动作
                            dummyEvent.index = QiongWinGame.OPTR_GIVEUP;
                            itemClick(dummyEvent);
                            timer.reset();
                            timer.start();
					    } else if (currentGame.randDown.numChildren > 0) {
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
// TEST SIMULATION CODE IS BEGIN
                ListenerBinder.bind(currentGame.testFresh, MouseEvent.CLICK, function(e:MouseEvent):void {
                    currentGame.testArea.text = 
                    new Array(
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
                                  mahjongBox.mahjongsOfDais[3].length).join("\t"),
                        mahjongBox.mahjongsOnTable.join(",")).join("\n");
                });
// TEST SIMULATION CODE IS END
                for each (var eachToolTip:Box in new Array(currentGame.toolTip1, currentGame.toolTip2, currentGame.toolTip3)) {
                    ListenerBinder.bind(MahjongButton(eachToolTip.getChildAt(0)), MouseEvent.CLICK, toolTipClick);
                    ListenerBinder.bind(MahjongButton(eachToolTip.getChildAt(1)), MouseEvent.CLICK, toolTipClick);
                    ListenerBinder.bind(MahjongButton(eachToolTip.getChildAt(2)), MouseEvent.CLICK, toolTipClick);
                    // TODO These codes can be uncommect when mouse over or mouse out effects are needed. 
//                    ListenerBinder.bind(eachToolTip, MouseEvent.MOUSE_OVER, toolTipMouseOver);
//                    ListenerBinder.bind(eachToolTip, MouseEvent.MOUSE_OUT, toolTipMouseOut);
                }
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
            currentGame.timerTip.label = "剩余时间："; // DROP THIS LINE!!! TODO
		    currentGame.timerTip.minimum = 0;
            currentGame.timerTip.maximum = MAX_CARDS_SELECT_TIME;
            currentGame.timerTip.mode = ProgressBarMode.MANUAL;
            mahjongBox = new QiongWinMahjongBox();
        }

        /**
         *
         * 游戏开始时，将系统分配的麻将进行排序
         *
         * @param event
         *
         */
        private function gameStartedHandler(event:QiongWinGameEvent):void {
            // 显示系统洗牌后的结果，格式为：一号玩家待发牌 + "~" + 二号玩家待发牌 + "~" + 
            // 三号玩家待发牌 + "~" + 四号玩家待发牌 + "~" + 其余未分配的牌 
            var results:Array = event.incomingData.split("~");
            mahjongBox.mahjongsOfPlayers = new Array(results[0], results[1], results[2], results[3]);
            mahjongBox.mahjongsSpared = results[4].toString().split(",");
            // FIXME TEST PART BEGIN
            mahjongBox.mahjongsOfPlayers = new Array("EAST,EAST,EAST,W1,W1,W1,W3,W4,W5,W7,W7,W7,RED",
                                                     "SOUTH,SOUTH,SOUTH,B1,B1,B1,B3,B4,B5,B7,B7,B7,RED",
                                                     "WEST,WEST,WEST,T1,T1,T1,T3,T4,T5,T7,T7,T7,RED", 
                                                     "NORTH,NORTH,NORTH,W2,W3,W4,B2,B3,B4,T2,T3,T4,T4");
            mahjongBox.mahjongsSpared = "W8,W8,B3,RED,NORTH,B4,W5,B6,W2,T5,W6,T4,T3,W6,B5,W3,WEST,B8,B8,T8,T8,WHITE,W6,W8,GREEN,W4,W9,W2,WHITE,T5,W2,T7,W5,W1,T9,W5,W4,GREEN,W7,T8,W8,W9,GREEN,W9,B5,B7,B2,B2,B1,B8,W9,B6,B2,B6,B6,B5,B4,B8,B9,B9,B9,B9,T9,T2,T2,T5,T3,B3,T9,WHITE,W3,T6,T1,T6,T6,T6,T8,WHITE,W6,GREEN,EAST,T2,T9,SOUTH".split(",");
            results[0] = mahjongBox.mahjongsOfPlayers[0];
            results[1] = mahjongBox.mahjongsOfPlayers[1];
            results[2] = mahjongBox.mahjongsOfPlayers[2];
            results[3] = mahjongBox.mahjongsOfPlayers[3];
            results[4] = mahjongBox.mahjongsSpared;
            // FIXME TEST PART END
            var mahjongSequence:String = results[localNumber - 1];
            var mahjongNames:Array = QiongWinGame.sortMahjongs(mahjongSequence);

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
         * 游戏开始后为当前玩家添加麻将组件
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
         * 游戏开始后为非当前玩家添加麻将组件
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
         * 当前玩家为第一个发牌者时，开始进行游戏设置
         *
         * @param event
         *
         */
        private function gameFirstPlayHandler(event:QiongWinGameEvent):void {
            // 开始摸牌
            var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
            dummyEvent.index = QiongWinGame.OPTR_RAND;
            itemClick(dummyEvent);
            // 显示操作按钮
            currentGame.btnBarMahjongs.visible = true;
            currentGame.timerTip.visible = true;
            timer.reset();
            timer.start();
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
        private function gameBringOutHandler(event:QiongWinGameEvent):void {
            // 接收上家出牌序列，显示出牌结果
            var results:Array = event.incomingData.split("~");
            currentNumber = results[0];
            currentBoutMahjong = results[1];
            if (results.length > 2) {
                currentNextNumber = results[2];
            }
            var boutMahjongButton:MahjongButton, eachMahjongValue:String = null;

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
                	handleBoutGiveup();
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
            mahjongBox.importMahjong(currentNumber - 1, currentBoutMahjong);
            // 玩家摸牌时，更新布局
        	var boutMahjongButton:MahjongButton = new MahjongButton();
            boutMahjongButton.allowSelect = false;
            boutMahjongButton.source = "image/mahjong/" + playerDirectionArray[currentNumber - 1] + "/standard/DEFAULT.jpg";
            Box(mahjongsRandArray[currentNumber - 1]).removeAllChildren();
            Box(mahjongsRandArray[currentNumber - 1]).addChild(boutMahjongButton);
		}

		/**
		 * 
		 * 响应玩家出牌动作
		 * 
		 */
		private function handleBoutDeal():void {
            // 玩家出牌时，更新模型与布局
            mahjongBox.exportMahjong(currentNumber - 1, currentBoutMahjong);
            mahjongBox.discardMahjong(currentBoutMahjong);
        	var boutMahjongButton:MahjongButton = new MahjongButton();
            boutMahjongButton.allowSelect = false;
            boutMahjongButton.source = "image/mahjong/down/dealed/" + currentBoutMahjong + ".jpg"
        	currentGame.dealed.addChild(boutMahjongButton);
        	// 移除摸牌区域的牌
        	currentGame.randRight.removeAllChildren();
        	currentGame.randUp.removeAllChildren();
        	currentGame.randLeft.removeAllChildren();

            // 初始化操作按钮
            resetBtnBar();

			// 从非出牌玩家中，找出唯一一个可以进行胡牌、杠牌或碰牌操作的玩家
			// 玩家的优先权取决于操作权（如胡牌优先权最高，其次是杠牌，再次是碰牌）
			var finalMixedIndex:int = -1, winMixedIndex:int = -1, kongMixedIndex:int = -1, pongMixedIndex:int = -1;
			var canWin:Boolean = false, canKong:Boolean = false, canPong:Boolean = false;
			var indexWin:int = -1, indexKong:int = -1, indexPong:int = -1;
			// 胡牌情况
			indexWin = QiongWinGame.isWin(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1));
			canWin = indexWin > -1;
			if (canWin) {
			    winMixedIndex = indexWin;
			}
		    // 杠牌情况
			indexKong = QiongWinGame.isKong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1));
			canKong = indexKong > -1;
			if (canKong) {
			    kongMixedIndex = indexKong;
			}
		    // 碰牌情况
			indexPong = QiongWinGame.isPong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1));
			canPong = indexPong > -1;
			if (canPong) {
			    pongMixedIndex = indexPong;
			}
			// 确定优先级最高的玩家混合索引值
			if (canWin) {
			    finalMixedIndex = indexWin;
			} else if (canKong) {
			    finalMixedIndex = indexKong;
			} else if (canPong) {
			    finalMixedIndex = indexPong;
			}

			// 准备胡杠碰操作
			// 玩家索引
			var playerIndex:int = finalMixedIndex % 10;
	     	if (finalMixedIndex > -1 && playerIndex != localNumber - 1) {
	     		// 胡牌、杠牌、碰牌玩家非当前玩家时，不执行任何操作
	     		return;
	     	} else if (finalMixedIndex > -1 && playerIndex == localNumber - 1) {
	     		// 胡牌、杠牌、碰牌玩家为当前玩家时

				// 更改操作按钮状态
	  			var operationList:Array = new Array(
		  			function ():void {
						if (canWin && playerIndex == localNumber - 1) {
							// 胡牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_WIN)).enabled = true;
						}
		  			},
		  			function ():void {
						if (canKong && playerIndex == localNumber - 1) {
							// 杠牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_KONG)).enabled = true;
						}
		  			},
		  			function ():void {
						if (canPong && playerIndex == localNumber - 1) {
							// 碰牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_PONG)).enabled = true;
						}
		  			}
		     	);
		     	for (var i:int = finalMixedIndex / 10; i < 3; i++) {
		     		operationList[i]();
		     	}
                // 判断其他玩家是否可以进行胡牌操作动作
                var isOthersWin:Boolean = QiongWinGame.isWin(
                        currentBoutMahjong, 
                        mahjongBox.mahjongsOfPlayers, 
                        String(currentNumber - 1) + String(localNumber - 1)) > -1;
                var eachButton:Button = null;
		     	if (currentNextNumber == localNumber) {
		     	    // 当前玩家为出牌玩家的下家时
                    if (isOthersWin) {
                        // 存在其他玩家可以进行胡牌操作动作时
                        for each (eachButton in currentGame.btnBarMahjongs.getChildren()) {
                            eachButton.enabled = false;
                        }
                        Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_WIN)).enabled = true;
                        Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_GIVEUP)).enabled = true;
                    } else {
    		     	    // 启用摸牌按钮
    	     		    Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_RAND)).enabled = true;
    		     		// 启用吃牌按钮
    	     		    var canChow:Boolean = QiongWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])
    	     		    Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_CHOW)).enabled = canChow;
    	     		    // 启用放弃按钮
    	     		    Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_GIVEUP)).enabled = true;
                    }
		     	} else {
		     	    // 当前玩家不是出牌玩家下家时
                    if (isOthersWin) {
                        // 存在其他玩家可以进行胡牌操作动作时
                        for each (eachButton in currentGame.btnBarMahjongs.getChildren()) {
                            eachButton.enabled = false;
                        }
                        Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_WIN)).enabled = true;
                        Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_GIVEUP)).enabled = true;
                    }
	     		    Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_GIVEUP)).enabled = true;
	     		}
                currentGame.btnBarMahjongs.visible = true;
	     	} else if (finalMixedIndex < 0 && currentNextNumber == localNumber) {
	     		// 没有玩家胡牌、杠牌、胡牌时，为当前玩家出牌做准备
				// 吃牌判断
		     	if (QiongWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])) {
		     		// 启用吃牌按钮
		     		Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_CHOW)).enabled = true;
		     		// 启用摸牌按钮
		     		Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_RAND)).enabled = true;
                	// 为出牌玩家设置麻将操作按钮外观
                    currentGame.btnBarMahjongs.visible = true;
		     		return;
		     	}
            	// 为出牌玩家设置麻将操作按钮外观
                currentGame.btnBarMahjongs.visible = true;
                // 自动摸牌
	            var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
	            dummyEvent.index = QiongWinGame.OPTR_RAND;
	            itemClick(dummyEvent);
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
        	var sourcePath:String = null;
        	var removedCount:int = -1;
        	if (operationIndex == QiongWinGame.OPTR_KONG) {
        		// 杠牌时
                // 更新模型与布局
            	if (currentNumber == operatedNumber) {
	                // 玩家暗杠时
                    mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
		            sourcePath = "image/mahjong/" + playerDirectionArray[currentNumber - 1] + "/dealed/DEFAULT.jpg"
            	} else {
	                // 玩家明杠时
	                mahjongBox.mahjongsOnTable.pop();
                    mahjongBox.importMahjong(currentNumber - 1, operatedMahjong);
                    mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
		            sourcePath = "image/mahjong/" + playerDirectionArray[currentNumber - 1] + "/dealed/" + operatedMahjong + ".jpg"
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
            } else if (operationIndex == QiongWinGame.OPTR_PONG) {
        		// 碰牌时
                // 更新模型
                mahjongBox.mahjongsOnTable.pop();
                mahjongBox.importMahjong(currentNumber - 1, operatedMahjong);
                mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
                // 更新布局
	            sourcePath = "image/mahjong/" + playerDirectionArray[currentNumber - 1] + "/dealed/" + operatedMahjong + ".jpg"
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
        	} else if (operationIndex == QiongWinGame.OPTR_CHOW) {
        		// 吃牌时
                // 更新模型
                mahjongBox.mahjongsOnTable.pop();
                mahjongBox.importMahjong(currentNumber - 1, operatedMahjong);
                mahjongBox.moveMahjongToDais(currentNumber - 1, currentBoutMahjong);
                // 更新布局
                for each (eachMahjongValue in currentBoutMahjong.split(",")) {
                	boutMahjongButton = new MahjongButton();
		            boutMahjongButton.allowSelect = false;
		            boutMahjongButton.source = "image/mahjong/" + playerDirectionArray[currentNumber - 1] + "/dealed/" + eachMahjongValue + ".jpg";
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

		/**
		 * 
		 * 响应玩家放弃动作
		 * 
		 * @param giveupPlayerNumbers
		 * @param isPass
		 * 
		 */
		private function handleBoutGiveup():void {
            // 初始化操作按钮
            resetBtnBar();

			// 从非出牌玩家中，找出唯一一个可以进行胡牌、杠牌或碰牌操作的玩家
			// 玩家的优先权取决于操作权（如胡牌优先权最高，其次是杠牌，再次是碰牌）
			var finalMixedIndex:int = -1, winMixedIndex:int = -1, kongMixedIndex:int = -1, pongMixedIndex:int = -1;
			var canWin:Boolean = false, canKong:Boolean = false, canPong:Boolean = false;
			var indexWin:int = -1, indexKong:int = -1, indexPong:int = -1;
			// 胡牌情况
			indexWin = QiongWinGame.isWin(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + currentGiveupIndice);
			canWin = indexWin > -1;
			if (canWin) {
			    winMixedIndex = indexWin;
			}
		    // 杠牌情况
			indexKong = QiongWinGame.isKong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + currentGiveupIndice);
			canKong = indexKong > -1;
			if (canKong) {
			    kongMixedIndex = indexKong;
			}
		    // 碰牌情况
			indexPong = QiongWinGame.isPong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, String(currentNumber - 1) + currentGiveupIndice);
			canPong = indexPong > -1;
			if (canPong) {
			    pongMixedIndex = indexPong;
			}
			// 确定优先级最高的玩家混合索引值
			if (canWin) {
			    finalMixedIndex = indexWin;
			} else if (canKong) {
			    finalMixedIndex = indexKong;
			} else if (canPong) {
			    finalMixedIndex = indexPong;
			}

			// 准备胡杠碰操作
			// 玩家索引
			var playerIndex:int = finalMixedIndex % 10;
	     	if (finalMixedIndex > -1 && playerIndex != localNumber - 1) {
	     		// 胡牌、杠牌、碰牌玩家非当前玩家时，不执行任何操作
	     		return;
	     	} else if (finalMixedIndex > -1 && playerIndex == localNumber - 1) {
	     		// 胡牌、杠牌、碰牌玩家为当前玩家时

				// 更改操作按钮状态
	  			var operationList:Array = new Array(
		  			function ():void {
						if (canWin && playerIndex == localNumber - 1) {
							// 胡牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_WIN)).enabled = true;
						}
		  			},
		  			function ():void {
						if (canKong && playerIndex == localNumber - 1) {
							// 杠牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_KONG)).enabled = true;
						}
		  			},
		  			function ():void {
						if (canPong && playerIndex == localNumber - 1) {
							// 碰牌，为出牌玩家设置麻将操作按钮外观
							Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_PONG)).enabled = true;
						}
		  			}
		     	);
		     	for (var i:int = finalMixedIndex / 10; i < 3; i++) {
		     		operationList[i]();
		     	}
		     	if (currentNextNumber == localNumber) {
		     	    // 当前玩家为出牌玩家的下家时
	     		    Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_RAND)).enabled = true;
	     		    var canChow:Boolean = QiongWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])
	     		    Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_RAND)).enabled = canChow;
		     	} else {
		     	    // 当前玩家不是出牌玩家下家时
	     		    Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_GIVEUP)).enabled = true;
	     		}
                currentGame.btnBarMahjongs.visible = true;
	     	} else if (finalMixedIndex < 0 && currentNextNumber == localNumber) {
	     		// 没有玩家胡牌、杠牌、胡牌时，为当前玩家出牌做准备
				// 吃牌判断
		     	if (QiongWinGame.isChow(currentBoutMahjong, mahjongBox.mahjongsOfPlayers[localNumber - 1])) {
		     		// 启用吃牌按钮
		     		Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_CHOW)).enabled = true;
		     		// 启用摸牌按钮
		     		Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_RAND)).enabled = true;
                	// 为出牌玩家设置麻将操作按钮外观
                    currentGame.btnBarMahjongs.visible = true;
		     		return;
		     	}
            	// 为出牌玩家设置麻将操作按钮外观
                currentGame.btnBarMahjongs.visible = true;
                // 自动摸牌
	            var dummyEvent:ItemClickEvent = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
	            dummyEvent.index = QiongWinGame.OPTR_RAND;
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
        private function gameInterruptedHandler(event:QiongWinGameEvent):void {
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
        private function gameOverHandler(event:QiongWinGameEvent):void {
            // 格式：发牌玩家~牌序(~接牌玩家)?~得分结果
            // 得分结果样例(编号，得分，系统积分)：3,30,0;2,30,0;4,30,0;1,30,0
            var results:Array = event.incomingData.split("~");
            var scoreboardInfo:Array = String(results[results.length - 1]).split(/;/);
            // 显示记分牌
            if ((results.length == 3) || (results.length == 4)) {
	            new Scoreboard().popUp(localNumber, scoreboardInfo, currentGameId, 
			            function():void {
			            	gameClient.currentState = 'LOBBY';
			            });
	            currentNumber = results[0];
	            currentBoutMahjong = results[1];
	            if (results.length == 4) {
	            	currentNextNumber = results[2];
	            }
            }
            // 显示游戏积分
            var currentIndex:int = -1;
			var winnerMahjongSeq:Array = null;
            var mahjongValue:String = null;
            var mahjongButton:MahjongButton = null;
            if (results.length == 3) {
            	// 自摸
            	gameClient.txtSysMessage.text += "穷胡游戏结束，玩家#1自摸获胜！\n".replace(/#1/, currentNumber);
            	if (currentNumber == localNumber) {
            	    return;
            	}
				// 显示获胜玩家牌
				currentIndex = currentNumber - 1;
				winnerMahjongSeq = (mahjongBox.mahjongsOfPlayers[currentIndex] as Array);
				mahjongValue = winnerMahjongSeq.pop();
				winnerMahjongSeq = QiongWinGame.sortMahjongs(winnerMahjongSeq.join(",")).reverse();
				// 摸牌区域
				Box(mahjongsRandArray[currentIndex]).removeAllChildren();
				mahjongButton = new MahjongButton();
				mahjongButton.allowSelect = false;
				mahjongButton.source = "image/mahjong/" + playerDirectionArray[currentIndex] + "/dealed/" + mahjongValue + ".jpg";
				Box(mahjongsRandArray[currentIndex]).addChild(mahjongButton);
				// 待发牌区域
				Box(mahjongsCandidatedArray[currentIndex]).removeAllChildren();
                if (mahjongsCandidatedArray[currentIndex] is VBox) {
                    VBox(mahjongsCandidatedArray[currentIndex]).setStyle("verticalGap", -8);
                }
				for each (mahjongValue in winnerMahjongSeq) {
					mahjongButton = new MahjongButton();
					mahjongButton.allowSelect = false;
					mahjongButton.source = "image/mahjong/" + playerDirectionArray[currentIndex] + "/dealed/" + mahjongValue + ".jpg";
					mahjongButton.setStyle("padding-bottom", 20);
					Box(mahjongsCandidatedArray[currentIndex]).addChild(mahjongButton);
				}
            } else if (results.length == 4) {
            	// 点炮
            	gameClient.txtSysMessage.text += "穷胡游戏结束，玩家#1为玩家#2点炮！\n".replace(/#1/, results[2]).replace(/#2/, results[0]);
            	if (currentNumber == localNumber) {
            	    return;
            	}
				// 显示获胜玩家牌
				currentIndex = currentNumber - 1;
				winnerMahjongSeq = (mahjongBox.mahjongsOfPlayers[currentIndex] as Array);
				winnerMahjongSeq = QiongWinGame.sortMahjongs(winnerMahjongSeq.join(",")).reverse();
				// 待发牌区域
				Box(mahjongsCandidatedArray[currentIndex]).removeAllChildren();
                if (mahjongsCandidatedArray[currentIndex] is VBox) {
                    VBox(mahjongsCandidatedArray[currentIndex]).setStyle("verticalGap", -8);
                }
				for each (mahjongValue in winnerMahjongSeq) {
					mahjongButton = new MahjongButton();
					mahjongButton.allowSelect = false;
					mahjongButton.source = "image/mahjong/" + playerDirectionArray[currentIndex] + "/dealed/" + mahjongValue + ".jpg";
					Box(mahjongsCandidatedArray[currentIndex]).addChild(mahjongButton);
				}
            } else {
            	gameClient.txtSysMessage.text += "穷胡游戏结束，没有玩家获胜，流局！\n";
            }
        }

        /**
         *
         * 没有独牌或天独的情况下，游戏中产生获胜者
         *
         * @param event
         *
         */
        private function gameWinnerProducedHandler(event:QiongWinGameEvent):void {
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
            QiongWinGameStateManager.resetInitInfo();
            QiongWinGameStateManager.currentGameId = results[0];
            QiongWinGameStateManager.localNumber = results[1];
            QiongWinGameStateManager.playerCogameNumber = results[2];
            // 为当前玩家的下家分配编号
            if (QiongWinGameStateManager.playerCogameNumber == QiongWinGameStateManager.localNumber) {
                QiongWinGameStateManager.localNextNumber = 1;
            } else {
                QiongWinGameStateManager.localNextNumber = QiongWinGameStateManager.localNumber + 1;
            }
            gameClient.currentState = "QIONGWINGAME";
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
                        socketProxy.sendGameData(QiongWinGameCommand.GAME_WIN_AND_END, 
                            localNumber + "~" + MahjongButton(currentGame.randDown.getChildAt(0)).value);
                    } else {
                        // 非自摸
                        socketProxy.sendGameData(QiongWinGameCommand.GAME_WIN_AND_END, 
                            localNumber + "~" + currentBoutMahjong + "~" + currentNumber);
                    }
                    currentGame.btnBarMahjongs.visible = false;
                    break;
                case 1:
                    // 杠
                    // 更新内存模型与外观
                    if (currentGame.randDown.numChildren > 0) {
                        // 暗杠时
                        var randValueForKong:String = MahjongButton(currentGame.randDown.getChildAt(0)).value;
                        mahjongBox.moveMahjongToDais(localNumber - 1, new Array(randValueForKong, 
                                                                                randValueForKong, 
                                                                                randValueForKong, 
                                                                                randValueForKong).join(","));
                        for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                            if (randValueForKong == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                                break;
                            }
                        }
                    } else {
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
                    }
                    var mahjongKong1:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 2));
                    var mahjongKong2:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 1));
                    var mahjongKong3:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i));
                    var mahjongKong4:MahjongButton = new MahjongButton();
                    mahjongKong4.source = mahjongKong1.source.toString();
                    mahjongKong1.allowSelect = false;
                    mahjongKong2.allowSelect = false;
                    mahjongKong3.allowSelect = false;
                    mahjongKong4.allowSelect = false;
                    mahjongKong1.source = mahjongKong1.source.toString().replace("standard", "dais");
                    mahjongKong2.source = mahjongKong2.source.toString().replace("standard", "dais");
                    mahjongKong3.source = mahjongKong3.source.toString().replace("standard", "dais");
                    mahjongKong4.source = mahjongKong4.source.toString().replace("standard", "dais");
                    if (currentGame.randDown.numChildren > 0) {
                        // 暗杠
                        mahjongKong1.source = mahjongKong1.source.toString().replace(mahjongKong1.value, "DEFAULT");
                        mahjongKong4.source = mahjongKong4.source.toString().replace(mahjongKong4.value, "DEFAULT");
                    } else {
                        // 明杠
                        // 移除桌面中最后一张打出的牌
                        currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1);
                    }
                    currentGame.daisDown.addChild(mahjongKong1);
                    currentGame.daisDown.addChild(mahjongKong2);
                    currentGame.daisDown.addChild(mahjongKong3);
                    currentGame.daisDown.addChild(mahjongKong4);
                    // 发送杠牌命令(吃碰杠：发牌玩家序号~牌序~发牌玩家的下家序号~被发牌玩家执行了操作的玩家序号~被操作牌~动作索引)
                    if (currentGame.randDown.numChildren > 0) {
                        // 暗杠
                        // 移除摸牌区域中参与杠操作的牌
                        currentGame.randDown.removeAllChildren();
                        socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
                                new Array(mahjongKong2, mahjongKong2, mahjongKong3, mahjongKong3).join(",") + "~" + 
                                localNextNumber + "~" + localNumber + "~" + mahjongKong1.value + "~" + QiongWinGame.OPTR_KONG);
                    } else {
                        // 明杠
                        socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
                                new Array(mahjongKong1, mahjongKong2, mahjongKong3, mahjongKong4).join(",") + "~" + 
                                localNextNumber + "~" + currentNumber + "~" + mahjongKong1.value + "~" + QiongWinGame.OPTR_KONG);
                    }
    		        // 开始摸牌
    		        event = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
                    event.index = QiongWinGame.OPTR_RAND;
                    itemClick(event);
                    break;
                case 2:
                    // 碰
                    // 更新内存模型
                    mahjongBox.mahjongsOnTable.pop();
                    mahjongBox.importMahjong(localNumber - 1, currentBoutMahjong);
                    mahjongBox.moveMahjongToDais(localNumber - 1, 
                            new Array(currentBoutMahjong, currentBoutMahjong, currentBoutMahjong).join(","));
                    // 更新外观
                    for (i = 0; i < currentGame.candidatedDown.getChildren().length; i++) {
                        if (currentBoutMahjong == MahjongButton(currentGame.candidatedDown.getChildAt(i)).value) {
                            break;
                        }
                    }
                    var mahjongPong1:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i + 1));
                    var mahjongPong2:MahjongButton = MahjongButton(currentGame.candidatedDown.getChildAt(i));
                    var mahjongPong3:MahjongButton = new MahjongButton();
                    mahjongPong1.allowSelect = false;
                    mahjongPong2.allowSelect = false;
                    mahjongPong3.allowSelect = false;
                    mahjongPong1.source = mahjongPong1.source.toString().replace("standard", "dais");
                    mahjongPong2.source = mahjongPong2.source.toString().replace("standard", "dais");
                    mahjongPong3.source = mahjongPong1.source.toString();
                    currentGame.daisDown.addChild(mahjongPong1);
                    currentGame.daisDown.addChild(mahjongPong2);
                    currentGame.daisDown.addChild(mahjongPong3);
                    // 移除桌面中最后一张打出的牌
                    currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1);
                    // 发送杠牌命令(吃碰杠：发牌玩家序号~牌序~发牌玩家的下家序号~被发牌玩家执行了操作的玩家序号~被操作牌~动作索引)
                    socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, localNumber + "~" + 
                            new Array(mahjongPong1, mahjongPong2, mahjongPong3).join(",") + "~" + 
                            localNextNumber + "~" + currentNumber + "~" + mahjongPong1.value + "~" + QiongWinGame.OPTR_PONG);
                    break;
                case 3:
                    // 吃
		        	var color:String = currentBoutMahjong.charAt(0);
		        	var value:int = int(currentBoutMahjong.charAt(1));
		        	var headHeadDealedMahjong:String = color + (value - 2);
		        	var headDealedMahjong:String = color + (value - 1);
		        	var tailDealedMahjong:String = color + (value + 1);
		        	var tailTailDealedMahjong:String = color + (value + 2);
		        	// 左左吃
		        	var leftLeftValue:Array = new Array(headHeadDealedMahjong, headDealedMahjong, currentBoutMahjong);
		        	// 左吃右
		        	var leftValueRight:Array = new Array(headDealedMahjong, currentBoutMahjong, tailDealedMahjong);
		        	// 吃右右
		        	var valueRightRight:Array = new Array(currentBoutMahjong, tailDealedMahjong, tailTailDealedMahjong);
		        	// 当前玩家手中的牌
		        	var fullSeq:Array = (mahjongBox.mahjongsOfPlayers[localNumber - 1] as Array).slice(0);
		        	// 将当前玩家手中的牌与上家打出的牌合并
		        	fullSeq.push(currentBoutMahjong);
		        	fullSeq = fullSeq.sort();
					// 构造出牌提示
					var eachMahjongButton:MahjongButton = null;
					var eachIndex:int = 0;
		        	if (fullSeq.join(",").match(new RegExp(leftLeftValue.join(".*")))) {
		        		for each (eachMahjongButton in currentGame.toolTip1.getChildren()) {
		        			eachIndex = currentGame.toolTip1.getChildIndex(eachMahjongButton);
		        			eachMahjongButton.source = eachMahjongButton.source.toString().replace(/\w+.jpg/, leftLeftValue[eachIndex] + ".jpg");
		        		}
		        	}
		        	if (fullSeq.join(",").match(new RegExp(leftValueRight.join(".*")))) {
		        		for each (eachMahjongButton in currentGame.toolTip2.getChildren()) {
		        			eachIndex = currentGame.toolTip2.getChildIndex(eachMahjongButton);
		        			eachMahjongButton.source = eachMahjongButton.source.toString().replace(/\w+.jpg/, leftValueRight[eachIndex] + ".jpg");
		        		}
		        	}
		        	if (fullSeq.join(",").match(new RegExp(valueRightRight.join(".*")))) {
		        		for each (eachMahjongButton in currentGame.toolTip3.getChildren()) {
		        			eachIndex = currentGame.toolTip3.getChildIndex(eachMahjongButton);
		        			eachMahjongButton.source = eachMahjongButton.source.toString().replace(/\w+.jpg/, valueRightRight[eachIndex] + ".jpg");
		        		}
		        	}
		        	// 显示操作提示栏
		        	currentGame.toolTip1.visible = Boolean(fullSeq.join(",").match(new RegExp(leftLeftValue.join(".*"))));
		        	currentGame.toolTip2.visible = Boolean(fullSeq.join(",").match(new RegExp(leftValueRight.join(".*"))));
		        	currentGame.toolTip3.visible = Boolean(fullSeq.join(",").match(new RegExp(valueRightRight.join("."))));
		        	// 激活操作栏中的放弃按钮
    		        Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_GIVEUP)).enabled = true;
                    break;
                case 4:
	            	// 放弃
        		    if ((!Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_WIN)).enabled &&
        		        !Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_KONG)).enabled &&
        		        !Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_PONG)).enabled) &&
        		        (Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_CHOW)).enabled || 
        		        currentGame.toolTip1.visible || currentGame.toolTip2.visible || currentGame.toolTip3.visible)) {
        		        // 在非胡牌、杠牌、碰牌的情况下，吃牌时。即除了吃牌动作外，无其他任何动作可以操作
	            	    resetBtnBar();
        		        currentGame.toolTip1.visible = false;
        		        currentGame.toolTip2.visible = false;
        		        currentGame.toolTip3.visible = false;
        		        // 开始摸牌
        		        event = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
                        event.index = QiongWinGame.OPTR_RAND;
                        itemClick(event);
                        return;
        		    }
        		    // 放弃：发牌玩家序号~牌名~发牌玩家的下家序号~执行放弃操作的玩家序号列表(列表内容为：123或12或1……)
        		    currentGiveupIndice += (localNumber - 1);
	            	if (QiongWinGame.isWin(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, (currentNumber - 1) + currentGiveupIndice) > 0) {
	            	    // 有其他可以胡牌或杠牌或碰牌的玩家
	            	    currentGame.btnBarMahjongs.visible = false;
            		    socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, 
            		        currentNumber + "~" + currentBoutMahjong + "~" + currentNextNumber + "~" + currentGiveupIndice);
	            	} else if (QiongWinGame.isKong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, (currentNumber - 1) + currentGiveupIndice) > 0) {
	            	    // 有其他可以杠牌的玩家
	            	    currentGame.btnBarMahjongs.visible = false;
            		    socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, 
            		        currentNumber + "~" + currentBoutMahjong + "~" + currentNextNumber + "~" + currentGiveupIndice);
	            	} else if (QiongWinGame.isPong(currentBoutMahjong, mahjongBox.mahjongsOfPlayers, (currentNumber - 1) + currentGiveupIndice) > 0) {
	            	    // 有其他可以碰牌的玩家
	            	    currentGame.btnBarMahjongs.visible = false;
            		    socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, 
            		        currentNumber + "~" + currentBoutMahjong + "~" + currentNextNumber + "~" + currentGiveupIndice);
	            	} else if (currentNextNumber == localNumber) {
	            	    // 当前玩家为发牌玩家下家时
	            	    resetBtnBar();
        		        currentGame.toolTip1.visible = false;
        		        currentGame.toolTip2.visible = false;
        		        currentGame.toolTip3.visible = false;
        		        // 开始摸牌
        		        event = new ItemClickEvent(ItemClickEvent.ITEM_CLICK);
                        event.index = QiongWinGame.OPTR_RAND;
                        itemClick(event);
	            	} else {
	            	    // 放弃当前优先权，将优先权返还给发牌玩家的下家
	            	    currentGame.btnBarMahjongs.visible = false;
	            	    Alert.show("放弃当前优先权，将优先权返还给发牌玩家的下家");
            		    socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, 
            		        currentNumber + "~" + currentBoutMahjong + "~" + currentNextNumber + "~" + currentGiveupIndice);
	            	}

                    break;
                case 5:
                    // 摸牌
                    // 更新内存
                    var mahjongRandValue:String = mahjongBox.randomMahjong();
                    if (mahjongRandValue == null) {
                        // 扑、流局
                        socketProxy.sendGameData(QiongWinGameCommand.GAME_WIN_AND_END);
                        return;
                    }
                    mahjongBox.importMahjong(localNumber - 1, mahjongRandValue);
                    // 更新布局
                    var mahjongRand:MahjongButton = new MahjongButton();
                    mahjongRand.source = "image/mahjong/down/standard/" + mahjongRandValue + ".jpg";
                    ListenerBinder.bind(mahjongRand, MouseEvent.CLICK, function (event:MouseEvent):void {
                        dealMahjong(mahjongRand);
                    });
                    currentGame.randDown.addChild(mahjongRand);
                    // 判断是否可以自摸、杠
                    if (QiongWinGame.canWinNow(mahjongBox.mahjongsOfPlayers[localNumber - 1])) {
                    	// 自摸
                    	isNarrowWin = true;
                    	Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_WIN)).enabled = true;
                    }
                    if (QiongWinGame.canKongNow(mahjongRandValue, mahjongBox.mahjongsOfPlayers[localNumber - 1])) {
                    	// 杠
                    	Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_KONG)).enabled = true;
                    }
                    // TODO 显示操作按钮栏
                    currentGame.btnBarMahjongs.visible = true;
                    // 发送游戏命令
                    socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, localNumber + "~" + mahjongRandValue);
                    break;
            }
        }

		/**
		 * 
		 * 根据选择的提示内容进行吃牌操作
		 * 
		 * @param event
		 * 
		 */
		private function toolTipClick(event:MouseEvent):void {
		    if (!(event.currentTarget is MahjongButton)) {
		        return;
		    }
		    // 重置操作按钮栏
		    resetBtnBar();
		    // 隐藏所有提示栏
		    currentGame.toolTip1.visible = false;
		    currentGame.toolTip2.visible = false;
		    currentGame.toolTip3.visible = false;

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
				daisMahjongButton.source = eachMahjongButton.source.toString().replace("standard", "dais");
				currentGame.daisDown.addChild(daisMahjongButton);
			}

            // 移除桌面中最后一张打出的牌
            currentGame.dealed.removeChildAt(currentGame.dealed.numChildren - 1);

			// 发牌玩家序号~牌序~发牌玩家的下家序号~被发牌玩家执行了操作的玩家序号~被操作牌~动作索引
			var message:String = localNumber + "~" + Box(MahjongButton(event.currentTarget).parent).getChildren().join(",") + "~" +localNextNumber + "~" + 
			        currentNumber + "~" + currentBoutMahjong + "~" + QiongWinGame.OPTR_CHOW; 
			socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, message);
		}

		/**
		 * 
		 * TODO 设置提示操作栏鼠标移上的样式
		 * 
		 * @param event
		 * 
		 */
		private function toolTipMouseOver(event:MouseEvent):void {
			Box(event.target).setStyle("horizontalGap", "8");
		}

		/**
		 * 
		 * TODO 设置提示操作栏鼠标移出的样式
		 * 
		 * @param event
		 * 
		 */
		private function toolTipMouseOut(event:MouseEvent):void {
			Box(event.target).setStyle("horizontalGap", "NaN");
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
			timer.reset();
			timer.start();
		}

		/**
		 * 
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动发牌<br>
		 * 打出摸牌区域的牌或按东南西北中发白万饼条打出最左边的一张
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
            if (Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_GIVEUP)).enabled) {
                return;
            }
            if (Button(currentGame.btnBarMahjongs.getChildAt(QiongWinGame.OPTR_RAND)).enabled) {
                return;
            }

            // 隐藏操作按钮
            currentGame.btnBarMahjongs.visible = false;

			// 更新布局
            // 从玩家手中牌删除选中牌
            mahjong.parent.removeChild(mahjong);
            // 将牌显示在桌面
            mahjong.allowSelect = false;
            mahjong.source = mahjong.source.toString().replace("standard", "dealed");
            currentGame.dealed.addChild(mahjong);

            // 将玩家摸牌区域与放牌区域的麻将合并后重新排序
            if (currentGame.randDown.numChildren > 0) {
                var mahjongsDown:Array = currentGame.candidatedDown.getChildren();
                var mahjongsNewDown:Array = mahjongsDown.concat(currentGame.randDown.getChildren());
                currentGame.candidatedDown.removeAllChildren();
                // 重新排序
                for each (var eachMahjongButton:MahjongButton in QiongWinGame.sortMahjongButtons(mahjongsNewDown)) {
                    currentGame.candidatedDown.addChild(eachMahjongButton);
                }
            }

            // 更新内存模型
            mahjongBox.exportMahjong(localNumber - 1, mahjong.value);
            mahjongBox.discardMahjong(mahjong.value);

            // 发送出牌命令
            socketProxy.sendGameData(QiongWinGameCommand.GAME_BRING_OUT, localNumber + "~" + mahjong.value + "~" + localNextNumber);
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
            var container:Box = null;
            for each (container in mahjongsCandidatedArray) {
                container.removeAllChildren();
                if (container is VBox) {
                    VBox(container).setStyle("verticalGap", -20);
                }
            }
            for each (container in mahjongsDaisArray) {
                container.removeAllChildren();
            }
            for each (container in mahjongsRandArray) {
                container.removeAllChildren();
            }
            if (currentGame) {
                currentGame.dealed.removeAllChildren();
            }
        }
    }
}