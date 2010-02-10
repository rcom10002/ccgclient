// ActionScript file

import info.knightrcom.state.BaseStateManager;
import info.knightrcom.state.FightLandlordGameStateManager;
import info.knightrcom.state.LobbyStateManager;
import info.knightrcom.state.LoginStateManager;
import info.knightrcom.state.PushdownWinGameStateManager;
import info.knightrcom.state.QiongWinGameStateManager;
import info.knightrcom.state.Red5GameStateManager;
import info.knightrcom.util.PuppetEngine;
import info.knightrcom.GameSocketProxy;

import mx.events.FlexEvent;

/**
 * 
 * @param event
 */
protected override function applicationCompleteHandler(event:FlexEvent):void {
    var myApp:CCGameClient = application as CCGameClient;
    var socketProxy:GameSocketProxy = new GameSocketProxy(this._launchInfo.remoteAddr, 2009);
    // 基础状态管理器
    var baseStateManager:BaseStateManager = new BaseStateManager(socketProxy);
    // 登录状态管理器
    var loginStateManager:LoginStateManager = new LoginStateManager(socketProxy, myApp.loginState);
    // 大厅状态管理器
    var lobbyStateManager:LobbyStateManager = new LobbyStateManager(socketProxy, myApp.lobbyState);
    // 红五状态管理器
    var red5GameStateManager:Red5GameStateManager = new Red5GameStateManager(socketProxy, myApp.red5GameState);
    // 斗地主状态管理器
    var fightLandlordGameStateManager:FightLandlordGameStateManager = new FightLandlordGameStateManager(socketProxy, myApp.fightLandlordGameState);
    // 推到胡状态管理器
    var pushdownWinGameStateManager:PushdownWinGameStateManager = new PushdownWinGameStateManager(socketProxy, myApp.pushdownWinGameState);
    // 穷胡状态管理器
    var qiongWinGameStateManager:QiongWinGameStateManager = new QiongWinGameStateManager(socketProxy, myApp.qiongWinGameState);
    baseStateManager.init();
    // 全屏效果
    // PlatformRepresentationUtil.toggleStageDisplayState(Application.application.stage);
    // login the platform through a unique identifier
//    var securityPassword:String = BrowserAddressUtil.getParameterValue("securityPassword");
//    var classPrefix:String = BrowserAddressUtil.getParameterValue("classPrefix");
//    var username:String = BrowserAddressUtil.getParameterValue("username");
//    var password:String = BrowserAddressUtil.getParameterValue("password");
//    var roomId:String = BrowserAddressUtil.getParameterValue("roomId");
//    var gameSetting:String = BrowserAddressUtil.getParameterValue("gameSetting");
    var securityPassword:String = this._launchInfo.securityPassword;
    var classPrefix:String = this._launchInfo.classPrefix;
    var username:String = this._launchInfo.username;
    var password:String = this._launchInfo.password;
    var roomId:String = this._launchInfo.roomId;
    var gameType:String = this._launchInfo.gameType;
    if (securityPassword) {
        switch (gameType) {
            case 1:
                red5GameStateManager.myPuppet = PuppetEngine.createPinocchioPuppet(
                    securityPassword, classPrefix, username, password, roomId, gameType);
        }
    }
}
