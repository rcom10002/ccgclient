package info.knightrcom.state {
    import component.service.PlayerInfoWindow;
    import component.service.SystemInfoWindow;
    
    import flash.display.DisplayObject;
    import flash.display.StageDisplayState;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.command.FightLandlordGameCommand;
    import info.knightrcom.command.PlatformCommand;
    import info.knightrcom.command.PlayerCommand;
    import info.knightrcom.command.Red5GameCommand;
    import info.knightrcom.event.FightLandlordGameEvent;
    import info.knightrcom.event.GameEvent;
    import info.knightrcom.event.PlatformEvent;
    import info.knightrcom.event.PlayerEvent;
    import info.knightrcom.event.Red5GameEvent;
    import info.knightrcom.util.Model;
    
    import memorphic.xpath.XPathQuery;
    
    import mx.containers.Accordion;
    import mx.containers.Tile;
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.core.Application;
    import mx.core.Container;
    import mx.events.FlexEvent;
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
        public function LobbyStateManager(socketProxy:GameSocketProxy, gameClient:CCGameClient, myState:State):void {
            super(socketProxy, gameClient, myState);
            myState.addEventListener(FlexEvent.ENTER_STATE, init);
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

            gameClient.gameControlBar.btnGameJoin.addEventListener(MouseEvent.CLICK, gameJoinClick);
            gameClient.gameControlBar.btnSystemInfo.addEventListener(MouseEvent.CLICK, systemInfoClick);
            gameClient.gameControlBar.btnPlayerInfo.addEventListener(MouseEvent.CLICK, playerInfoClick);
            gameClient.gameControlBar.btnOption.addEventListener(MouseEvent.CLICK, optionClick);
            gameClient.gameControlBar.btnLogout.addEventListener(MouseEvent.CLICK, logoutClick);
            gameClient.gameControlBar.btnHelp.addEventListener(MouseEvent.CLICK, helpClick);

            socketProxy.addEventListener(PlatformEvent.PLATFORM_ENVIRONMENT_INIT, platformEnvironmentInitHandler);
            socketProxy.addEventListener(PlayerEvent.LOBBY_ENTER_ROOM, lobbyEnterRoomHandler);
            socketProxy.addEventListener(GameEvent.GAME_CREATE, gameCreateHandler);
            socketProxy.addEventListener(GameEvent.GAME_WAIT, gameWaitHandler);

            // 请求平台信息
            socketProxy.sendPlatformData(PlatformCommand.PLATFORM_REQUEST_ENVIRONMENT);
        	PlayerInfoWindow.CURRENT_PROFILE_ID = BaseStateManager.currentProfileId;
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
            var lobbyKeys:Array = new Array();
            var roomKeys:Array = new Array();
            // 构造排序函数
            var sort:Function = function(container:Container):void {
                for each (var child:DisplayObject in container.getChildren()) {
                    container.setChildIndex(child, child["data"]);
                }
            };
            // 构造游戏平台
            platform.id = e4xData.platform.id.toString();
            platform.name = e4xData.platform.name.toString();
            platform.modelCategory = e4xData.platform.modelCategory.toString();
            platform.data = e4xData.platform.displayIndex;
            // TODO 内存问题
            // 构造游戏大厅
            for (index in lobbys) {
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
                room = new Model();
                room.id = rooms[index].id.toString();
                room.name = rooms[index].name.toString();
                room.data = rooms[index].displayIndex.toString();
                room.modelCategory = rooms[index].modelCategory.toString();
                var currentRoomParentId:String = rooms[index].parentId.toString();
                room.parentId = currentRoomParentId;
                lobby = platform.childContainer[currentRoomParentId];
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
                    button.addEventListener(MouseEvent.CLICK, roomClick);
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
            if (event is Red5GameEvent) {
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
            } else if (event is FightLandlordGameEvent) {
            	FightLandlordGameStateManager.resetInitInfo();
                FightLandlordGameStateManager.currentGameId = results[0];
                FightLandlordGameStateManager.localNumber = results[1];
                FightLandlordGameStateManager.playerCogameNumber = results[2];
                if (FightLandlordGameStateManager.playerCogameNumber == FightLandlordGameStateManager.localNumber) {
                    FightLandlordGameStateManager.localNextNumber = 1;
                } else {
                    FightLandlordGameStateManager.localNextNumber = FightLandlordGameStateManager.localNumber + 1;
                }
                gameClient.currentState = "FIGHTLANDLORDGAME";
            } else {
                Alert.show("未知游戏类型");
                return;
            }
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
         * @param event
         *
         */
        private function roomClick(event:Event):void {
            var targetButton:Button = Button(event.target);
            var roomId:String = targetButton.name;
            var lobbyId:String = targetButton.parent.name;
            BaseStateManager.currentRoomId = roomId;
            BaseStateManager.currentLobbyId = lobbyId;
            socketProxy.sendPlayerData(PlayerCommand.LOBBY_ENTER_ROOM, roomId);
            gameClient.txtSysMessage.text += "roomId=" + roomId + ", lobbyId=" + lobbyId + "\n";
        }

        /**
         *
         * @param event
         *
         */
        private function gameJoinClick(event:Event):void {
        	if (BaseStateManager.currentRoomId == null) {
        		Alert.show("请先选择要加入的房间！");
        		return;
        	}
            var roomIdFlag:String = BaseStateManager.currentRoomId.toLocaleLowerCase();
            if (roomIdFlag.toLocaleLowerCase().indexOf("red5") > -1) {
                socketProxy.sendGameData(Red5GameCommand.GAME_JOIN_MATCHING_QUEUE);
            } else if (roomIdFlag.indexOf("fightlandlord") > -1) {
                socketProxy.sendGameData(FightLandlordGameCommand.GAME_JOIN_MATCHING_QUEUE);
            } else {
                Alert.show("当前房间暂不开放！");
            }
        }

        /**
         *
         * @param event
         *
         */
        private function systemInfoClick(event:Event):void {
        	var infoForm:SystemInfoWindow = new SystemInfoWindow();
        	infoForm.currentLayoutCanvas = gameClient;
        	infoForm.popUp();
        }

        /**
         *
         * @param event
         *
         */
        private function playerInfoClick(event:Event):void {
        	var infoForm:PlayerInfoWindow = new PlayerInfoWindow();
        	infoForm.currentLayoutCanvas = gameClient;
        	infoForm.popUp();
        }

        /**
         *
         * @param event
         *
         */
        private function optionClick(event:Event):void {
        }

        /**
         *
         * @param event
         *
         */
        private function logoutClick(event:Event):void {
        	socketProxy.disconnect();
        	gameClient.currentState = "LOGIN";
        }

        /**
         *
         * @param event
         *
         */
        private function helpClick(event:Event):void {
        }

    }
}