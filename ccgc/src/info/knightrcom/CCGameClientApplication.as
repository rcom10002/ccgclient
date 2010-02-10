package info.knightrcom
{
    import info.knightrcom.util.ListenerBinder;
    import info.knightrcom.util.Model;
    
    import mx.core.Application;
    import mx.events.FlexEvent;
    import mx.utils.URLUtil;
    
    /**
     * 提高事件绑定等初始化功能，其它功能实现由子类外部链接代码片段完成
     */
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
        
        protected var _launchInfo:Model = new Model();
        
        /**
         * 
         * @param value
         */
        public function set launchInfo(value:Model):void {
            this._launchInfo = value;
            if (!this._launchInfo.remoteAddr) {
                this._launchInfo.remoteAddr = URLUtil.getServerName(Application.application.loaderInfo.url);
            }
        }
    }
}