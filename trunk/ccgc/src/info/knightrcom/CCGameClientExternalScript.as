// ActionScript file

import info.knightrcom.state.BaseStateManager;
import info.knightrcom.state.FightLandlordGameStateManager;
import info.knightrcom.state.LobbyStateManager;
import info.knightrcom.state.LoginStateManager;
import info.knightrcom.state.PushdownWinGameStateManager;
import info.knightrcom.state.QiongWinGameStateManager;
import info.knightrcom.state.Red5GameStateManager;
import info.knightrcom.util.BrowserAddressUtil;
import info.knightrcom.util.PuppetEngine;
import info.knightrcom.GameSocketProxy;

import mx.core.Application;
import mx.events.FlexEvent;
import mx.utils.URLUtil;

protected override function applicationCompleteHandler(event:FlexEvent):void {
    var myApp:CCGameClient = application as CCGameClient;
    var socketProxy:GameSocketProxy = new GameSocketProxy(URLUtil.getServerName(Application.application.loaderInfo.url), 2009);
    var baseStateManager:BaseStateManager = new BaseStateManager(socketProxy);
    var loginStateManager:LoginStateManager = new LoginStateManager(socketProxy, myApp.loginState);
    var lobbyStateManager:LobbyStateManager = new LobbyStateManager(socketProxy, myApp.lobbyState);
    var red5GameStateManager:Red5GameStateManager = new Red5GameStateManager(socketProxy, myApp.red5GameState);
    var fightLandlordGameStateManager:FightLandlordGameStateManager = new FightLandlordGameStateManager(socketProxy, myApp.fightLandlordGameState);
    var pushdownWinGameStateManager:PushdownWinGameStateManager = new PushdownWinGameStateManager(socketProxy, myApp.pushdownWinGameState);
    var qiongWinGameStateManager:QiongWinGameStateManager = new QiongWinGameStateManager(socketProxy, myApp.qiongWinGameState);
    //            for each (var eachGameStateManager:* in [
    //                {key: getQualifiedClassName(Red5GameStateManager), value: myApp.red5GameStateManager}, 
    //                {key: getQualifiedClassName(FightLandlordGameStateManager), value: myApp.fightLandlordGameStateManager}, 
    //                {key: getQualifiedClassName(PushdownWinGameStateManager), value: myApp.pushdownWinGameStateManager}, 
    //                {key: getQualifiedClassName(QiongWinGameStateManager), value: myApp.qiongWinGameStateManager}]) {
    //                    stateManagers[eachGameStateManager.key] = eachGameStateManager.value;
    //                }
    baseStateManager.init();
    // 全屏效果
    // PlatformRepresentationUtil.toggleStageDisplayState(Application.application.stage);
    // login the platform through a unique identifier
    var securityPassword:String = BrowserAddressUtil.getParameterValue("securityPassword");
    var classPrefix:String = BrowserAddressUtil.getParameterValue("classPrefix");
    var username:String = BrowserAddressUtil.getParameterValue("username");
    var password:String = BrowserAddressUtil.getParameterValue("password");
    var roomId:String = BrowserAddressUtil.getParameterValue("roomId");
    var gameSetting:String = BrowserAddressUtil.getParameterValue("gameSetting");
    if (securityPassword) {
        red5GameStateManager.myPuppet = PuppetEngine.createPinocchioPuppet(securityPassword, classPrefix, username, password, roomId, gameSetting);
    }
}