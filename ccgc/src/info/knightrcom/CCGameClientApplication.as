package info.knightrcom
{
    import info.knightrcom.assets.CommonResource;
    import info.knightrcom.state.BaseStateManager;
    import info.knightrcom.state.FightLandlordGameStateManager;
    import info.knightrcom.state.LobbyStateManager;
    import info.knightrcom.state.LoginStateManager;
    import info.knightrcom.state.PushdownWinGameStateManager;
    import info.knightrcom.state.QiongWinGameStateManager;
    import info.knightrcom.state.Red5GameStateManager;
    import info.knightrcom.util.BrowserAddressUtil;
    import info.knightrcom.util.ListenerBinder;
    import info.knightrcom.util.PuppetEngine;

    import mx.core.Application;
    import mx.events.FlexEvent;
    import mx.utils.URLUtil;
    
    public dynamic class CCGameClientApplication extends Application
    {
//        private var stateManagers:Object = new Object();

        public function CCGameClientApplication()
        {
            ListenerBinder.bind(this, FlexEvent.APPLICATION_COMPLETE, applicationCompleteHandler);
            super();
        }
//
//        /**
//         * 
//         * @param gameStateManagerClass
//         * @return 
//         */
//        public function getGameStateManager(gameStateManagerClass:*):AbstractGameStateManager
//        {
//            return stateManagers[getQualifiedClassName(gameStateManagerClass)] as AbstractGameStateManager;
//        }

        protected function applicationCompleteHandler(event:FlexEvent):void {
        }
    }
}