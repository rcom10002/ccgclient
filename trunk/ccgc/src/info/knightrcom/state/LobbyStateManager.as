package info.knightrcom.state {
    import component.service.PlayerInfoWindow;
    import component.service.SystemInfoWindow;
    
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.utils.Timer;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.command.FightLandlordGameCommand;
    import info.knightrcom.command.PlatformCommand;
    import info.knightrcom.command.PlayerCommand;
    import info.knightrcom.command.PushdownWinGameCommand;
    import info.knightrcom.command.QiongWinGameCommand;
    import info.knightrcom.command.Red5GameCommand;
    import info.knightrcom.event.PlatformEvent;
    import info.knightrcom.event.PlayerEvent;
    import info.knightrcom.util.ListenerBinder;
    import info.knightrcom.util.Model;
    
    import memorphic.xpath.XPathQuery;
    
    import mx.containers.Accordion;
    import mx.containers.Tile;
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.core.Container;
    import mx.events.CloseEvent;
    import mx.events.FlexEvent;
    import mx.formatters.DateFormatter;
    import mx.states.State;

    public class LobbyStateManager extends AbstractStateManager {

        public static const platform:Model = new Model();

        /**
         *
         * @param socketProxy
         * @param gameClient
         * @param myState
         *
         */
        public function LobbyStateManager(socketProxy:GameSocketProxy, myState:State):void {
            super(socketProxy, myState);
            ListenerBinder.bind(myState, FlexEvent.ENTER_STATE, init);
        }

        /**
         *
         * @param event
         *
         */
        private function init(event:Event):void {
            if (isInitialized()) {
                return;
            }

            ListenerBinder.bind(gameClient.gameControlBar.btnGameJoin, MouseEvent.CLICK, gameJoinClickHandler);
            ListenerBinder.bind(gameClient.gameControlBar.btnSystemInfo, MouseEvent.CLICK, systemInfoClickHandler);
            ListenerBinder.bind(gameClient.gameControlBar.btnPlayerInfo, MouseEvent.CLICK, playerInfoClickHandler);
            ListenerBinder.bind(gameClient.gameControlBar.btnOption, MouseEvent.CLICK, optionClickHandler);
            ListenerBinder.bind(gameClient.gameControlBar.btnLogout, MouseEvent.CLICK, logoutClickHandler);
            ListenerBinder.bind(gameClient.gameControlBar.btnHelp, MouseEvent.CLICK, helpClickHandler);

			ListenerBinder.bind(gameClient.btnHideLogWindow, MouseEvent.CLICK, btnHideLogWindowClickHandler);
			ListenerBinder.bind(gameClient.btnCleanLogWindow, MouseEvent.CLICK, btnCleanLogWindowClickHandler);

            ListenerBinder.bind(socketProxy, PlatformEvent.PLATFORM_ENVIRONMENT_INIT, platformEnvironmentInitHandler);
            ListenerBinder.bind(socketProxy, PlayerEvent.LOBBY_ENTER_ROOM, lobbyEnterRoomHandler);

            ListenerBinder.bind(gameClient.txtSysMessage, FlexEvent.VALUE_COMMIT, function (e:Event):void {
				// 滚动条移动到最下方
				gameClient.txtSysMessage.verticalScrollPosition = gameClient.txtSysMessage.maxVerticalScrollPosition;
				// 系统时间追加不需要执行后续动作
				if (gameClient.txtSysMessage.text.charAt(gameClient.txtSysMessage.text.length - 2) == "^" || gameClient.txtSysMessage.text.length == 0) {
					return;
				}
				// 为消息自动添加时间戳
				var dtFormatter:DateFormatter = new DateFormatter();
				dtFormatter.formatString = "YYY-MM-DD JJ:NN:SS";
				gameClient.txtSysMessage.text += "^" + dtFormatter.format(new Date()) + "^\n";
				// 日志窗口可见时不执行后续动作
				if (gameClient.txtSysMessage.visible) {
					return;
				}
				// 显示日志消息，限时0.75秒
				gameClient.btnHideLogWindow.enabled = false;
				gameClient.txtSysMessage.visible = true;
				var autoCloseTimer:Timer = new Timer(50, 15);
				ListenerBinder.bind(autoCloseTimer, TimerEvent.TIMER_COMPLETE, function (event:TimerEvent):void {
					if (autoCloseTimer.currentCount <= 5) {
						return;
					}
					gameClient.txtSysMessage.alpha = (autoCloseTimer.repeatCount - autoCloseTimer.currentCount) / 10.0;
					if (autoCloseTimer.currentCount == 15) {
						gameClient.txtSysMessage.visible = false;
						gameClient.txtSysMessage.alpha = 1;
						gameClient.btnHideLogWindow.enabled = true;
					}
				});
				autoCloseTimer.start();
            });
			ListenerBinder.bind(gameClient.txtSysMessage, FlexEvent.SHOW, function (e:Event):void {
				gameClient.btnHideLogWindow.label = "隐藏消息日志";
			});
			ListenerBinder.bind(gameClient.txtSysMessage, FlexEvent.HIDE, function (e:Event):void {
				gameClient.btnHideLogWindow.label = "显示消息日志";
			});

            // 请求平台信息
            socketProxy.sendPlatformData(PlatformCommand.PLATFORM_REQUEST_ENVIRONMENT);
            // TODO gameClient.loginState
            setInitialized(true);
        }

        /**
         *
         * @param event
         *
         */
        private function platformEnvironmentInitHandler(event:PlatformEvent):void {
            var e4xData:XML = new XML(event.incomingData);
            var lobbys:XMLList = XPathQuery.execQuery(e4xData, "//lobby");
            var rooms:XMLList = XPathQuery.execQuery(e4xData, "//room");
            var lobby:Model = null;
            var room:Model = null;
            var index:String = "";
            var lobbyKeys:Array = [];
            var roomKeys:Array = [];
            // 构造排序函数
            var sort:Function = function(container:Container):void {
            	// 构造临时数组
                var children:Array = [];
                var eachChild:DisplayObject = null;
                for each (eachChild in container.getChildren()) {
                	children.push(eachChild);
                }
                // 将临时数组排序
                children.sort(function (obj1:*, obj2:*):Number {
                	var displayIndex1:Number = Number(obj1["data"]);
                	var displayIndex2:Number = Number(obj2["data"]);
                	return displayIndex1 == displayIndex2 ? 0 : (displayIndex1 > displayIndex2 ? 1 : -1);
                });
                // 重新制定显示位置
                container.removeAllChildren();
                for each (eachChild in children) {
                	container.addChild(eachChild);
                }
            };
            // 构造游戏平台
            platform.id = e4xData.platform.id.toString();
            platform.name = e4xData.platform.name.toString();
            platform.modelCategory = e4xData.platform.modelCategory.toString();
            platform.data = e4xData.platform.displayIndex;
            // 构造游戏大厅
            for (index in lobbys) {
            	if (lobbys[index].disabled.toString().toLowerCase() == "true") {
            		continue;
            	}
                lobby = new Model();
                lobby.id = lobbys[index].id.toString();
                lobby.name = lobbys[index].name.toString();
                lobby.data = lobbys[index].displayIndex.toString();
                lobby.modelCategory = lobbys[index].modelCategory.toString();
                lobby.parentId = lobbys[index].parentId.toString();
                lobby.parent = platform;
                platform.childContainer[lobby.id] = lobby;
            }
            // 构造游戏房间
            for (index in rooms) {
            	if (rooms[index].disabled.toString().toLowerCase() == "true") {
            		continue;
            	}
                room = new Model();
                room.id = rooms[index].id.toString();
                room.name = rooms[index].name.toString();
                room.data = rooms[index].displayIndex.toString();
                room.modelCategory = rooms[index].modelCategory.toString();
                room.parentId = rooms[index].parentId.toString();
                lobby = platform.childContainer[room.parentId];
                if (!lobby) {
                    continue;
                }
                room.parent = lobby;
                lobby.childContainer[room.id] = room;
            }
            // 根据模型创建GUI
            var menu:Accordion = gameClient.acdnLobbys;
            for (var key:String in platform.childContainer) {
                // Tile大厅
                var tileModel:Model = platform.childContainer[key];
                var tile:Tile = new Tile();
                tile.data = tileModel.data;
                tile.name = tileModel.id;
                tile.label = tileModel.name;
                tile.percentWidth = 100;
                tile.percentHeight = 100;
                tile.setStyle("horizontalAlign", "center");
                tile.setStyle("verticalGap", 12);
                tile.setStyle("horizontalGap", 12);
                tile.setStyle("paddingTop", 12);
                tile.setStyle("paddingBottom", 12);
                tile.setStyle("paddingLeft", 12);
                tile.setStyle("paddingRight", 12);
                menu.addChild(tile);
                for (var innerKey:String in tileModel.childContainer) {
                    // Button房间
                    var buttonModel:Model = tileModel.childContainer[innerKey];
                    var button:Button = new Button();
                    button.data = buttonModel.data;
                    button.name = buttonModel.id;
                    button.label = buttonModel.name;
                    button.width = 80;
                    button.height = 80;
                    ListenerBinder.bind(button, MouseEvent.CLICK, roomClickHandler);
                    tile.addChild(button);
                }
                // Button排序
                sort(tile);
            }
            // Tile排序
            sort(menu);
        }

        /**
         *
         * @param event
         *
         */
        private function lobbyEnterRoomHandler(event:PlatformEvent):void {
            gameClient.txtSysMessage.text += event.incomingData + "\n";
        }

        /**
         *
         * @param event
         *
         */
        private function roomClickHandler(event:Event):void {
            if (gameClient.progressBarMatching.visible) {
                gameClient.txtSysMessage.text += "系统配对中，无法切换房间！\n";
                return;
            }
            var targetButton:Button = Button(event.target);
            var roomId:String = targetButton.name;
            var lobbyId:String = targetButton.parent.name;
            BaseStateManager.currentRoomId = roomId;
            BaseStateManager.currentLobbyId = lobbyId;
            socketProxy.sendPlayerData(PlayerCommand.LOBBY_ENTER_ROOM, roomId);
            gameClient.txtSysMessage.text += "欢迎进入" + targetButton.parent["label"] + "，" + targetButton.label + "！\n";
        }

        /**
         *
         * @param event
         *
         */
        private function gameJoinClickHandler(event:Event):void {
        	if (BaseStateManager.currentRoomId == null) {
        		Alert.show("请先选择要加入的房间！");
        		return;
        	}
            var roomIdFlag:String = BaseStateManager.currentRoomId.toLocaleLowerCase();
            if (roomIdFlag.toLocaleLowerCase().indexOf("red5") > -1) {
                socketProxy.sendGameData(Red5GameCommand.GAME_JOIN_MATCHING_QUEUE);
                gameClient.progressBarMatching.setProgress(0, 100);
                gameClient.progressBarMatching.indeterminate = true;
                gameClient.progressBarMatching.visible = true;
            } else if (roomIdFlag.indexOf("fightlandlord") > -1) {
                socketProxy.sendGameData(FightLandlordGameCommand.GAME_JOIN_MATCHING_QUEUE);
                gameClient.progressBarMatching.setProgress(0, 100);
                gameClient.progressBarMatching.indeterminate = true;
                gameClient.progressBarMatching.visible = true;
            } else if (roomIdFlag.indexOf("pushdownwin") > -1) {
                socketProxy.sendGameData(PushdownWinGameCommand.GAME_JOIN_MATCHING_QUEUE);
                gameClient.progressBarMatching.setProgress(0, 100);
                gameClient.progressBarMatching.indeterminate = true;
                gameClient.progressBarMatching.visible = true;
            } else if (roomIdFlag.indexOf("qiongwin") > -1) {
                socketProxy.sendGameData(QiongWinGameCommand.GAME_JOIN_MATCHING_QUEUE);
                gameClient.progressBarMatching.setProgress(0, 100);
                gameClient.progressBarMatching.indeterminate = true;
                gameClient.progressBarMatching.visible = true;
            } else {
                Alert.show("当前房间暂不开放！");
            }
        }

        /**
         *
         * @param event
         *
         */
        private function systemInfoClickHandler(event:Event):void {
        	var infoForm:SystemInfoWindow = new SystemInfoWindow();
        	infoForm.currentLayoutCanvas = gameClient.lobbyMain;
        	infoForm.popUp();
        }

        /**
         *
         * @param event
         *
         */
        private function playerInfoClickHandler(event:Event):void {
        	var infoForm:PlayerInfoWindow = new PlayerInfoWindow();
        	infoForm.currentLayoutCanvas = gameClient.lobbyMain;
        	infoForm.popUp();
        }

        /**
         *
         * @param event
         *
         */
        private function optionClickHandler(event:Event):void {
        }

        /**
         *
         * @param event
         *
         */
        private function logoutClickHandler(event:Event):void {
        	// FIXME This line is not necessary if the statement below works! socketProxy.disconnect();
        	// FIXME This line is not necessary if the statement below works! gameClient.currentState = "LOGIN";
        	Alert.yesLabel = "确认";
			Alert.noLabel = "取消";
		    Alert.show( "确定要注销登录？",
						"消息", 
						Alert.YES | Alert.NO,
						gameClient,
						function handleAlert(event:CloseEvent):void {
						    if(event.detail == Alert.YES)
						    {
						        flash.external.ExternalInterface.call("location.reload", true);
						    }
						},
						null,
						Alert.YES);
			
        }

        /**
         *
         * @param event
         *
         */
        private function helpClickHandler(event:Event):void {
            Alert.show("该功能尚未完成！");
            return;
        	gameClient.currentState = "CCGAMECLIENTHELP";
        }

		/**
		 * 
		 * @param event
		 * 
		 */
		private function btnHideLogWindowClickHandler(event:Event):void {
			if ("显示消息日志" == gameClient.btnHideLogWindow.label) {
				gameClient.btnHideLogWindow.label = "隐藏消息日志";
			} else {
				gameClient.btnHideLogWindow.label = "显示消息日志";
			}
			gameClient.txtSysMessage.visible = !gameClient.txtSysMessage.visible;
		}

		/**
		 * 
		 * @param event
		 * 
		 */
		private function btnCleanLogWindowClickHandler(event:Event):void {
			gameClient.txtSysMessage.text = "";
		}
    }
}