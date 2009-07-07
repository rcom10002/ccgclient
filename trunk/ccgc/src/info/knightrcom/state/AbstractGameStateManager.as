package info.knightrcom.state
{
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.util.ListenerBinder;
    
    import mx.controls.Alert;
    import mx.states.State;

	public class AbstractGameStateManager extends AbstractStateManager
	{
		public function AbstractGameStateManager(socketManager:GameSocketProxy, gameClient:CCGameClient, myState:State):void
		{
		    super(socketManager, gameClient, myState);
		}
        
        /**
         *
         * 批量绑定游戏事件
         *  
         * @param eventType
         * @param eventConfigs
         * 
         */
        protected function batchBindGameEvent(eventType:uint, eventConfigs:Array):void {
    	    for (var i:int = 0; i < eventConfigs.length; i += 2) {
            	ListenerBinder.gameBind(socketProxy, eventType, eventConfigs[i], eventConfigs[i + 1]);
            }
        }
	}
}