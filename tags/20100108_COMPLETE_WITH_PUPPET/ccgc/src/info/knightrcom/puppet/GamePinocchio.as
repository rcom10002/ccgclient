package info.knightrcom.puppet
{
    import component.Scoreboard;
    
    import flash.events.EventDispatcher;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    import info.knightrcom.state.red5game.Red5Game;
    import info.knightrcom.util.ListenerBinder;
    import info.knightrcom.util.PuppetProxy;

    /**
     *
     * Provide common methods for the subclass of the current class
     *
     */
    public dynamic class GamePinocchio extends EventDispatcher
    {
        private var _username:String;
        private var _password:String;
        private var _roomId:String;
        private var _gameSetting:String;
        private var _actionTimer:Timer = new Timer(3000);
		private var _tips:Array;

        /**
         *
         * @param username
         * @param password
         * @param roomId
		 * @param gameSetting
         *
         */
        public function GamePinocchio(username:String, password:String, roomId:String, gameSetting:String = null)
        {
            this._username = username;
            this._password = password;
            this._roomId = roomId;
            this._gameSetting = gameSetting;
        }

		/**
		 * 
		 * @param value
		 * 
		 */
		public function set tips(value:*):void {
            if (value is Array) {
                this._tips = Red5Game.analyzeCandidateCards((value as Array).join(",").split(","));
            } else {
                this._tips = Red5Game.analyzeCandidateCards(String(value).split(","));
            }
            this._tips = this._tips.slice(0, this._tips.length).reverse();
		}

		/**
		 * 
		 * @return 
		 * 
		 */
		public function get tips():Array {
			return this._tips;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */
		public function get gameSetting():String {
			return this._gameSetting;
		}

		/**
         *
         * @param delay
         * @param repeatCount
         * @param timerHandler
         * @param timerCompleteHandler
         *
         */
        public function prepareActionTimer(delay:int, timerHandler:Function = null, repeatCount:int = 0, timerCompleteHandler:Function = null):Timer
        {
            resetActionTimer();
            _actionTimer = new Timer(delay);
            if (timerHandler != null)
            {
                ListenerBinder.bind(_actionTimer, TimerEvent.TIMER, timerHandler);
            }
            _actionTimer.repeatCount = repeatCount;
            if (timerCompleteHandler != null)
            {
                ListenerBinder.bind(_actionTimer, TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
            }
            return this._actionTimer;
        }

        /**
         *
         * @param delay
         * @param repeatCount
         * @param timerHandler
         * @param timerCompleteHandler
         * 
         * TODO remove all unused parameters
         *
         */
        public function resetActionTimer(delay:int = 3000, timerHandler:Function = null, repeatCount:int = 0, timerCompleteHandler:Function = null):void
        {
            if (_actionTimer == null)
            {
                return;
            }
            if (_actionTimer.running)
            {
                _actionTimer.reset();
                _actionTimer.stop();
            }
            _actionTimer = null;
        }

        /**
         *
         *
         */
        public function loginPlatform():void
        {
            PuppetProxy.loginPlatform(_username, _password);
        }

        /**
         *
         *
         */
        public function enterRoom():Boolean
        {
            return PuppetProxy.enterRoom(_roomId);
        }

        /**
         *
         *
         */
        public function joinGame():void
        {
            PuppetProxy.joinGame();
        }

        /**
         *
         * @param event
         *
         */
        public function selectGameSetting(event:GamePinocchioEvent):void
        {
        }

        /**
         *
         * @param event
         *
         */
        public function operateGame(event:GamePinocchioEvent):void
        {
        }

        /**
         *
         * @param event
         *
         */
        public function backToLobby(event:GamePinocchioEvent):void
        {
            (event.tag as Scoreboard).btnClose.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
        }
    }

}
