package info.knightrcom.state
{
    import info.knightrcom.GameSocketProxy;
    import info.knightrcom.puppet.GamePinocchio;
    import info.knightrcom.util.ListenerBinder;
    
    import mx.core.Application;
    import mx.states.State;

	public class AbstractGameStateManager extends AbstractStateManager
	{
        
        /**
         * 游戏PUPPET 
         */
        protected var _myPuppet:GamePinocchio = new GamePinocchio(null, null, null);

        /**
         * 
         * @param socketManager
         * @param gameClient
         * @param myState
         */
        public function AbstractGameStateManager(socketManager:GameSocketProxy, myState:State):void
		{
		    super(socketManager, myState);
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
        
        /**
         * 
         * @param value
         */
        public function set myPuppet(value:GamePinocchio):void
        {
            _myPuppet = value;
        }
	}
}