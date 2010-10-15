package component.service
{
    import component.MahjongButton;
    
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import info.knightrcom.assets.MahjongResource;
    import info.knightrcom.service.LocalSystemInfoService;
    import info.knightrcom.state.BaseStateManager;
    import info.knightrcom.state.pushdownwingame.PushdownWinGame;
    import info.knightrcom.state.pushdownwingame.PushdownWinGameSetting;
    import info.knightrcom.util.HttpServiceProxy;
    import info.knightrcom.util.ListenerBinder;
    
    import mx.containers.Box;
    import mx.controls.Alert;
    import mx.controls.Label;
    import mx.events.CloseEvent;
    import mx.events.FlexEvent;
    import mx.formatters.DateFormatter;
    import mx.rpc.events.ResultEvent;

    /**
     * 
     * 
     */
    public class PushdownWinGameVedioWindow extends BasePushdownWinGameVedioWindow
    {

        private static const DEFAULT_DELAY:int = 5000;
        
        private var gamePlayers:String;
        
        private var gameRecord:String;
        
        private var candidatedArray:Array = new Array(candidatedDown, candidatedRight, candidatedUp, candidatedLeft);
        
        private var daisArray:Array = new Array(daisDown, daisRight, daisUp, daisLeft);
        
        private var randArray:Array = new Array(randDown, randRight, randUp, randLeft);
        
        private var directionArray:Array = new Array("down", "right", "up", "left");
        
        private var playingTimer:Timer
        
        /**
         * 
         * 
         */
        public function PushdownWinGameVedioWindow() {
            super();
            ListenerBinder.bind(this, mx.events.FlexEvent.CREATION_COMPLETE, this.creationCompleteHandler);
        }

        /**
         * 
         * @param event
         * 
         */
        private function creationCompleteHandler(event:FlexEvent):void {
            // 数据初始化
            candidatedArray = new Array(candidatedDown, candidatedRight, candidatedUp, candidatedLeft);
            daisArray = new Array(daisDown, daisRight, daisUp, daisLeft);
            randArray = new Array(randDown, randRight, randUp, randLeft);
            // 事件监听初始化
            ListenerBinder.bind(btnSetting, MouseEvent.CLICK, function():void {
                settingWindow.visible = !settingWindow.visible;
            });
            ListenerBinder.bind(settingWindow, CloseEvent.CLOSE, function():void {
                settingWindow.visible = false; 
            });
            ListenerBinder.bind(btnExecute, MouseEvent.CLICK, btnExecuteClickHandler);
            ListenerBinder.bind(btnTerminate, MouseEvent.CLICK, btnTerminateClickHandler);
        }

        /**
         * 
         * @param event
         * 
         */
        private function btnExecuteClickHandler(event:MouseEvent):void {
            if (btnExecute.label == "暂停") {
                btnExecute.label = "继续";
                if (playingTimer.running) {
                    playingTimer.stop();
                }
                return;
            } else if (btnExecute.label == "继续") {
                btnExecute.label = "暂停";
                playingTimer.start();
                return;
            } else if (btnExecute.label == "播放") {
                btnExecute.label = "暂停";
            } else {
                throw Error("按钮状态错误！");
            }
            // 录像机初始化
            if (playingTimer != null && playingTimer.running) {
                playingTimer.stop();
                throw Error("Timer组件错误！");
            }
            // 清空历史录像信息
            lblGameSetting.text = "";
            // 清除历史录像播放信息
            var eachBox:Box = null;
            for each (eachBox in candidatedArray) {
                eachBox.removeAllChildren();
            }
            for each (eachBox in daisArray) {
                eachBox.removeAllChildren();
            }
            for each (eachBox in randArray) {
                eachBox.removeAllChildren();
            }
            dealed.removeAllChildren();
            // 游戏玩家
            // 1~user4~2~user3~3~user2~4~user1~
            lblGameSetting.text = "数据加载中……";
            btnExecute.enabled = false;
            HttpServiceProxy.send(
                LocalSystemInfoService.LOAD_GAME_RECORD,
                {GAME_ID : gameId.text, CURRENT_PROFILE_ID: BaseStateManager.currentProfileId}, 
                null, 
                function (event:ResultEvent):void {
                    var e4xResult:XML = new XML(event.result);
                    var gameType:String = e4xResult.entity.gameType.text();
                    gamePlayers = e4xResult.entity.players.text();
                    gameRecord = e4xResult.entity.record.text();
                    gameRecord = gameRecord.replace(/#.*$/, "") // 删除最终所有玩家的亮牌信息
                    lblGameSetting.text = PushdownWinGameSetting.getDisplayName(e4xResult.entity.gameSetting.text());
                    // 确定游戏名称
                    if (gameType == "PushdownWinGame") {
                        var part1:String = gameRecord.replace(/^([^;]*).*$/, "$1");
                        var part2:String = part1.replace(/^.*~([^~]*)$/, "$1");
                        var part3:String = gameRecord.replace(/^[^;]*(.*)$/, "$1");
                        part1 = removeBothSides(part1.replace(/^(.*~)[^~]*$/, "$1"));
                        part2 = removeBothSides(part2);
                        part3 = removeBothSides(part3);
                        btnExecute.enabled = true;
                        playPushdownWinGame(part1, part2, part3);
                    } else {
                        throw Error("未知游戏类型！无法播放游戏历史录像！");
                    }
                    settingWindow.visible = false;
                },
                null,
                "POST",
                true
            );
        }
        
        /**
         * 
         * @param event
         * 
         */
        private function btnTerminateClickHandler(event:MouseEvent):void {
            if (playingTimer != null) {
                playingTimer.reset();
            }
            lblGameSetting.text = "";
            btnExecute.label = "播放";
        }
        
        /**
         * 
         * @param part1
         * @param part2
         * @param part3
         * 
         */
        private function playPushdownWinGame(part1:String, part2:String, part3:String):void {
            // T5,W5,NORTH,B4,W5,RED,W6,W2,SOUTH,RED,EAST,W9,B7~W9,B3,B1,T3,T1,B7,B4,W3,W2,B1,B1,SOUTH,B2~B3,W1,T7,W3,W2,T4,NORTH,W9,B9,T7,T9,W1,EAST~B6,T7,T6,W8,W6,W4,NORTH,T1,T9,W4,T3,T1,W7~B8,WEST,B5,B4,B7,T8,EAST,W7,W3,T3,B6,B2,B9,WEST,W8,WHITE,W7,B5,T8,W6,T8,GREEN,B6,T3,WHITE,T4,T2,T2,NORTH,W5,B5,W1,B1,GREEN,W1,W8,RED,SOUTH,B9,GREEN,T8,W2,W6,GREEN,T1,SOUTH,W7,B9,W8,B8,B5,W5,W9,T9,RED,T2,WEST,T2,T7,T5,T4,WHITE,WEST,B2,B3,B2,B3,B6,B4,T5,W3,B8,T6,T6,B7,WHITE,B8,T4,T9,EAST,W4,T5,W4,T6;1~B8;1~EAST~2;2~WEST;2~WEST~3;3~B5;3~EAST~4;4~B4;4~NORTH~1;1~B7;1~NORTH~2;2~T8;2~SOUTH~3;3~EAST;3~EAST~4;4~W7;4~T9~1;1~W3;1~SOUTH~2;2~T3;2~W9~3;3~B6;3~NORTH~4;4~B2;4~B4~1;1~B9;1~B4~2;2~WEST;2~WEST~3;3~W8;3~B9~4;4~WHITE;4~WHITE~1;1~W7;1~T5~2;2~B5;2~T8~3;3~T7,T8,T9~4~2~T8~3;3~T4~4;4~T8;4~T3~1;1~W6;1~B7~2;2~T8;2~T8~3;3~GREEN;3~GREEN~4;4~B6;4~B2~1;1~T3;1~T3~2;2~WHITE;2~WHITE~3;3~T4;3~T4~4;4~T2;4~T2~1;1~T2;1~T2~2;2~T1,T2,T3~3~1~T2~3;2~T3~3;3~NORTH;3~NORTH~4;4~W5;4~W4~1;1~B5;1~B5~2;2~W1;2~W1~3;3~W1,W2,W3~4~2~W1~3;3~T7~4;4~T6,T7,T8~1~3~T7~3;4~T7~1;1~B1;1~B1~2;2~GREEN;2~GREEN~3;3~W1;3~W1~4;4~W8;4~W8~1;1~RED;1~RED~2;2~SOUTH;2~SOUTH~3;3~B9;3~B9~4;4~GREEN;4~GREEN~1;1~T8;1~T8~2;2~W2;2~W2~3;3~W6;3~W6~4;4~GREEN;4~GREEN~1;1~T1;1~T1~2;2~SOUTH;2~SOUTH~3;3~W7;3~B3~4;4~B9;4~B9~1;1~W8;1~W5~2;2~B8;2~W3~3;3~B5;3~B6~4;4~W5;4~W7~1;1~W7,W8,W9~2~4~W7~3;1~W6~2;2~W9;2~W9~3;3~T9;3~T9~4;4~RED;4~RED~1;1~T2;1~T2~2;2~WEST;2~WEST~3;3~T2;3~T2~4;4~T7;4~T7~1;1~T5;1~T5~2;2~T4;2~W2~3;3~WHITE;3~WHITE~4;4~WEST;4~WEST~1;1~B2;1~B2~2;2~B3;2~B3~3;3~B2;3~B2~4;4~B3;4~B3~1;1~B6;1~B6~2;2~B6,B7,B8~3~1~B6~3;2~T4~3;3~B4;3~B4~4;4~T5;4~T5~1;1~W3;1~W2~2;2~B8;2~B8~3;3~T6;3~T6~4;2~T6~3;
            // 完整的记录
            // T5,W5,NORTH,B4,W5,RED,W6,W2,SOUTH,RED,EAST,W9,B7~W9,B3,B1,T3,T1,B7,B4,W3,W2,B1,B1,SOUTH,B2~B3,W1,T7,W3,W2,T4,NORTH,W9,B9,T7,T9,W1,EAST~B6,T7,T6,W8,W6,W4,NORTH,T1,T9,W4,T3,T1,W7~
            // 记录第一部分：游戏初始时各个玩家手中的牌
            // B8,WEST,B5,B4,B7,T8,EAST,W7,W3,T3,B6,B2,B9,WEST,W8,WHITE,W7,B5,T8,W6,T8,GREEN,B6,T3,WHITE,T4,T2,T2,NORTH,W5,B5,W1,B1,GREEN,W1,W8,RED,SOUTH,B9,GREEN,T8,W2,W6,GREEN,T1,SOUTH,W7,B9,W8,B8,B5,W5,W9,T9,RED,T2,WEST,T2,T7,T5,T4,WHITE,WEST,B2,B3,B2,B3,B6,B4,T5,W3,B8,T6,T6,B7,WHITE,B8,T4,T9,EAST,W4,T5,W4,T6
            // 记录第二部分：除玩家手中牌以外，剩余可供抓取的牌
            // ;1~B8;1~EAST~2;2~WEST;2~WEST~3;3~B5;3~EAST~4;4~B4;4~NORTH~1;1~B7;1~NORTH~2;2~T8;2~SOUTH~3;3~EAST;3~EAST~4;4~W7;4~T9~1;1~W3;1~SOUTH~2;2~T3;2~W9~3;3~B6;3~NORTH~4;4~B2;4~B4~1;1~B9;1~B4~2;2~WEST;2~WEST~3;3~W8;3~B9~4;4~WHITE;4~WHITE~1;1~W7;1~T5~2;2~B5;2~T8~3;3~T7,T8,T9~4~2~T8~3;3~T4~4;4~T8;4~T3~1;1~W6;1~B7~2;2~T8;2~T8~3;3~GREEN;3~GREEN~4;4~B6;4~B2~1;1~T3;1~T3~2;2~WHITE;2~WHITE~3;3~T4;3~T4~4;4~T2;4~T2~1;1~T2;1~T2~2;2~T1,T2,T3~3~1~T2~3;2~T3~3;3~NORTH;3~NORTH~4;4~W5;4~W4~1;1~B5;1~B5~2;2~W1;2~W1~3;3~W1,W2,W3~4~2~W1~3;3~T7~4;4~T6,T7,T8~1~3~T7~3;4~T7~1;1~B1;1~B1~2;2~GREEN;2~GREEN~3;3~W1;3~W1~4;4~W8;4~W8~1;1~RED;1~RED~2;2~SOUTH;2~SOUTH~3;3~B9;3~B9~4;4~GREEN;4~GREEN~1;1~T8;1~T8~2;2~W2;2~W2~3;3~W6;3~W6~4;4~GREEN;4~GREEN~1;1~T1;1~T1~2;2~SOUTH;2~SOUTH~3;3~W7;3~B3~4;4~B9;4~B9~1;1~W8;1~W5~2;2~B8;2~W3~3;3~B5;3~B6~4;4~W5;4~W7~1;1~W7,W8,W9~2~4~W7~3;1~W6~2;2~W9;2~W9~3;3~T9;3~T9~4;4~RED;4~RED~1;1~T2;1~T2~2;2~WEST;2~WEST~3;3~T2;3~T2~4;4~T7;4~T7~1;1~T5;1~T5~2;2~T4;2~W2~3;3~WHITE;3~WHITE~4;4~WEST;4~WEST~1;1~B2;1~B2~2;2~B3;2~B3~3;3~B2;3~B2~4;4~B3;4~B3~1;1~B6;1~B6~2;2~B6,B7,B8~3~1~B6~3;2~T4~3;3~B4;3~B4~4;4~T5;4~T5~1;1~W3;1~W2~2;2~B8;2~B8~3;3~T6;3~T6~4;2~T6~3;
            // 记录第三部分：游戏进行中所有的出牌记录
            
            // 开始发牌
            var initMahjongs:Array = part1.split(/~/);
            for (var eachMahjongsIndex:String in initMahjongs) {
                // eachMahjongs样式：4V2,3V2,2V2,1V2,2V5
                // 为每位玩家进行发牌，并对已发的牌进行排序
                var mahjongs:Array = PushdownWinGame.sortMahjongs(initMahjongs[eachMahjongsIndex].toString());
                for each (var eachMahjongName:String in mahjongs) {
                    var mahjong:MahjongButton = createMahjongButton(directionArray[eachMahjongsIndex], eachMahjongName);
                    mahjong.allowSelect = false;
                    candidatedArray[eachMahjongsIndex].addChild(mahjong);
                }
            }
            // 录像播放
            // 进行游戏设置
            var itrIndex:int = 0;
            // 游戏过程回放
            initMahjongs = part3.split(/;/);
            var playerIndex:int = -1;
            playingTimer = new Timer(DEFAULT_DELAY / gameSpeed.value);
            ListenerBinder.bind(playingTimer, TimerEvent.TIMER, function (event:TimerEvent):void {
                if (itrIndex == initMahjongs.length - 1) {
                    playingTimer.stop();
                    Alert.show("录像回放完毕！");
                    btnExecute.label = "播放";
                    return;
                }
                // 取得当前玩家出牌内容
                var currentTurn:Array = initMahjongs[itrIndex++].split("~");
                // 设置当前玩家编号、当前牌、当前玩家下家编号
                var currentNumber:int = currentTurn[0];
                var currentBoutMahjong:String = currentTurn[1];
                if (currentTurn.length > 2) {
                    var currentNextNumber:int = currentTurn[2];
                }
                var playerIndex:int = currentNumber - 1;
                var userDirection:String = directionArray[playerIndex];
                switch (currentTurn.length) {
                    case 2:
                        // 摸牌
                        addMahjong2Rand(playerIndex, userDirection, currentBoutMahjong);
                        break;
                    case 3:
                        // 出牌
                        removeMahjongFromCandidatedAndRand(playerIndex, currentBoutMahjong);
                        addMahjong2Dealed(currentBoutMahjong);
                        break;
                    case 6:
                        // 吃碰杠
                        var operatedNumber:int = currentTurn[3];
                        var operatedMahjong:String = currentTurn[4];
                        var operationIndex:int = currentTurn[5];
                        if (operationIndex == PushdownWinGame.OPTR_KONG) {
                            if (currentNumber == operatedNumber) {
                                // 暗杠
                                removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                                removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                                removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                                removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                                addMahjong2Dais(playerIndex, userDirection, operatedMahjong, true);
                                addMahjong2Dais(playerIndex, userDirection, operatedMahjong, true);
                                addMahjong2Dais(playerIndex, userDirection, operatedMahjong, true);
                                addMahjong2Dais(playerIndex, userDirection, operatedMahjong, true);
                            } else {
                                // 明杠
                                removeMahjongFromDealed();
                                removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                                removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                                removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                                addMahjong2Dais(playerIndex, userDirection, operatedMahjong, true);
                                addMahjong2Dais(playerIndex, userDirection, operatedMahjong, true);
                                addMahjong2Dais(playerIndex, userDirection, operatedMahjong, true);
                                addMahjong2Dais(playerIndex, userDirection, operatedMahjong, true);
                            }
                        } else if (operationIndex == PushdownWinGame.OPTR_PONG) {
                            removeMahjongFromDealed();
                            removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                            removeMahjongFromCandidatedAndRand(playerIndex, operatedMahjong);
                            addMahjong2Dais(playerIndex, userDirection, operatedMahjong);
                            addMahjong2Dais(playerIndex, userDirection, operatedMahjong);
                            addMahjong2Dais(playerIndex, userDirection, operatedMahjong);
                        } else if (operationIndex == PushdownWinGame.OPTR_CHOW) {
                            removeMahjongFromDealed();
                            for each (var eachMahjongValue:String in currentBoutMahjong.split(",")) {
                                if (eachMahjongValue != operatedMahjong) {
                                    removeMahjongFromCandidatedAndRand(playerIndex, eachMahjongValue);
                                }
                                addMahjong2Dais(playerIndex, userDirection, eachMahjongValue);
                            }
                        } else {
                            throw Error("无法处理当前动作类型！");
                        }
                        break;
                    case 4:
                        // 放弃（玩家争抢优先权）
                        // 没有进行动作操作，不做任何处理
                        break;
                    default:
                        throw Error("其他无法预测的接牌动作！[" + currentTurn.join("~") + "]");
                }
                // 取得当前玩家索引号
                
            });
            // 游戏录像开始
            playingTimer.start();
            btnExecute.enabled = true;
        }

        /**
         * 
         * @param direction
         * @param mahjongName
         * @param style
         * @return 
         * 
         */
        private function createMahjongButton(direction:String, mahjongName:String, style:String = null):MahjongButton {
            var mahjong:MahjongButton = new MahjongButton();
            if (!style) {
                style = "dealed";
            }
            mahjong.source = MahjongResource.load(direction, style, mahjongName);
            mahjong.allowSelect = false;
            return mahjong;
        }
        
        /**
         * 
         * @param playerIndex
         * @param direction
         * @param mahjongName
         * 
         */
        private function addMahjong2Rand(playerIndex:int, direction:String, mahjongName:String):void {
            Box(randArray[playerIndex]).addChild(createMahjongButton(direction, mahjongName));
        }
        
        /**
         * 
         * @param playerIndex
         * @param direction
         * @param mahjongName
         * @param useBack
         * 
         */
        private function addMahjong2Dais(playerIndex:int, direction:String, mahjongName:String, useBack:Boolean = false):void {
            if (useBack) {
                Box(daisArray[playerIndex]).addChild(createMahjongButton(direction, "DEFAULT"));
            } else {
                Box(daisArray[playerIndex]).addChild(createMahjongButton(direction, mahjongName));
            }
        }
        
        /**
         * 
         * @param mahjongName
         * 
         */
        private function addMahjong2Dealed(mahjongName:String):void {
            dealed.addChild(createMahjongButton("down", mahjongName));
        }
        
        /**
         * 
         * 
         */
        private function removeMahjongFromDealed():void {
            dealed.removeChildAt(dealed.numChildren - 1);
        }
        
        /**
         * 
         * @param playerIndex
         * @param mahjongName
         * 
         */
        private function removeMahjongFromCandidatedAndRand(playerIndex:int, mahjongName:String):void {
            if (Box(randArray[playerIndex]).numChildren > 0) {
                Box(candidatedArray[playerIndex]).addChild(Box(randArray[playerIndex]).getChildAt(0));
                Box(randArray[playerIndex]).removeAllChildren();
            }
            for each (var eachMahjongButton:MahjongButton in Box(candidatedArray[playerIndex]).getChildren()) {
                if (mahjongName == eachMahjongButton.value) {
                    Box(candidatedArray[playerIndex]).removeChild(eachMahjongButton);
                    break;
                }
            }
            var mahjongButtons:Array = Box(candidatedArray[playerIndex]).getChildren();
            Box(candidatedArray[playerIndex]).removeAllChildren();
            for each (eachMahjongButton in PushdownWinGame.sortMahjongButtons(mahjongButtons)) {
                Box(candidatedArray[playerIndex]).addChild(eachMahjongButton);
            }
        }
        
        /**
         * 
         * @param target
         * @return 
         * 
         */
        private function removeBothSides(target:String):String {
            return target.replace(/^[;~]|[;~]$/g, "");
        }
        
    }
}

