package info.knightrcom.state
{
	import component.PokerButton;
	import component.Scoreboard;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import info.knightrcom.GameSocketProxy;
	import info.knightrcom.command.FightLandlordGameCommand;
	import info.knightrcom.event.FightLandlordGameEvent;
	import info.knightrcom.event.GameEvent;
	import info.knightrcom.state.fightlandlordgame.FightLandlordGame;
	import info.knightrcom.state.fightlandlordgame.FightLandlordGameBox;
	import info.knightrcom.state.fightlandlordgame.FightLandlordGameSetting;
	import info.knightrcom.util.ListenerBinder;
	import info.knightrcom.util.PlatformAlert;
	import info.knightrcom.util.PlatformAlertEvent;
	
	import mx.containers.Box;
	import mx.containers.Tile;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.ProgressBarMode;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.managers.CursorManager;
	import mx.states.State;

	/**
	 *
	 * 斗地主游戏状态管理器
	 *
	 */
	public class FightLandlordGameStateManager extends AbstractGameStateManager
	{

		/**
		 * 游戏中玩家的个数
		 */
		public static var playerCogameNumber:int;

		/**
		 * 游戏设置：
		 * 0、不叫
		 * 1、1分 青龙
		 * 2、2分 白虎
		 * 3、3分 朱雀
		 */
		public static var gameSetting:int=-1;

		/**
		 * 游戏的最终设置所对应的玩家编号
		 */
		public static var gameFinalSettingPlayerNumber:int=-1;

		/**
		 * 游戏设置更新次数
		 */
		public static var gameSettingUpdateTimes:int=0;

		/**
		 * 当前游戏id
		 */
		public static var currentGameId:String;
		
		/**
         * 当前玩家序号
         */
        public static var firstPlayerNumber:int;
        
		/**
		 * 当前玩家序号
		 */
		public static var localNumber:int;

		/**
		 * 下家玩家序号
		 */
		public static var localNextNumber:int;

		/**
		 * 消息中的发牌玩家序号
		 */
		public static var currentNumber:int;

		/**
		 * 消息中的牌序
		 */
		public static var currentBoutCards:String=null;

		/**
		 * 消息中的下家玩家序号
		 */
		public static var currentNextNumber:int;

		/**
		 * 第一名玩家序号
		 */
		public static var firstPlaceNumber:int=UNOCCUPIED_PLACE_NUMBER;

		/**
		 * 第二名玩家序号
		 */
		public static var secondPlaceNumber:int=UNOCCUPIED_PLACE_NUMBER;

		/**
		 * 第三名玩家序号
		 */
		public static var thirdPlaceNumber:int=UNOCCUPIED_PLACE_NUMBER;

		/**
		 * 第四名玩家序号
		 */
		public static var forthPlaceNumber:int=UNOCCUPIED_PLACE_NUMBER;

		/**
		 * 未占用的位置
		 */
		public static const UNOCCUPIED_PLACE_NUMBER:int=-1;

		/**
		 * 是否是第一个获胜者的下家
		 */
		public static var isWinnerFollowed:Boolean=false;

		/**
		 * 已发牌区域
		 */
		private static var cardsDealedArray:Array=null;

		/**
		 * 待发牌区域
		 */
		private static var cardsCandidatedArray:Array=null;

		/**
		 * 地主出牌次数
		 */
		private static var holderOutTimes:int=0;

		/**
		 * 非地主玩家是否出过牌
		 */
		private static var isHaveOut:Boolean=false;

		/**
		 * 是否翻倍积分
		 */
		public static var isDoublePoint:Boolean=false;

		/**
		 * 用户发牌最大等待时间(秒)
		 */
		private static const MAX_CARDS_SELECT_TIME:int=15;

		/**
		 * 计时器
		 */
		private static var timer:Timer=new Timer(1000, MAX_CARDS_SELECT_TIME);
		
        /**
         * 计时器(用于显示其他玩家出牌所用时间)
         */
        private static var otherTimer:Timer = new Timer(1000, MAX_CARDS_SELECT_TIME);

		/**
		 * 当前游戏模块
		 */
		private static var currentGame:CCGameFightLandlord=null;

		/**
		 * 游戏内存模型
		 */
		private static var pokerBox:FightLandlordGameBox;
		/**
		 *
		 * @param socketProxy
		 * @param gameClient
		 * @param myState
		 *
		 */
		public function FightLandlordGameStateManager(socketProxy:GameSocketProxy, gameClient:CCGameClient, myState:State):void
		{
			super(socketProxy, gameClient, myState);
			ListenerBinder.bind(myState, FlexEvent.ENTER_STATE, init);
			batchBindGameEvent(FightLandlordGameEvent.EVENT_TYPE, new Array(
					GameEvent.GAME_WAIT, gameWaitHandler, 
					GameEvent.GAME_CREATE, gameCreateHandler, 
					GameEvent.GAME_STARTED, gameStartedHandler, 
					GameEvent.GAME_FIRST_PLAY, gameFirstPlayHandler, 
					GameEvent.GAME_SETTING_UPDATE, gameSettingUpdateHandler, 
					GameEvent.GAME_SETTING_OVER, gameSettingOverHandler,
            		FightLandlordGameEvent.GAME_SETTING_UPDATE_FINISH, gameSettingUpdateFinishHandler, 
					GameEvent.GAME_BRING_OUT, gameBringOutHandler, GameEvent.GAME_INTERRUPTED, 
					gameInterruptedHandler, GameEvent.GAME_WINNER_PRODUCED, gameWinnerProducedHandler, 
					GameEvent.GAME_OVER, gameOverHandler));
		}

		/**
		 *
		 * @param event
		 *
		 */
		private function init(event:Event):void
		{
			if (!isInitialized())
			{
				// 配置事件监听
				// 非可视组件
				currentGame=gameClient.fightLandlordGameModule;
				ListenerBinder.bind(timer, TimerEvent.TIMER, function(event:TimerEvent):void
					{
						currentGame.timerTip.setProgress(MAX_CARDS_SELECT_TIME - timer.currentCount, MAX_CARDS_SELECT_TIME);
						currentGame.timerTip.label = "剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME - timer.currentCount);
						if (timer.currentCount == MAX_CARDS_SELECT_TIME)
						{
							if (Button(currentGame.btnBarPokers.getChildAt(FightLandlordGame.OPTR_GIVEUP)).enabled)
							{
								// 可以选择不要按钮时，则进行不要操作
								itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 1));
							}
							else
							{
								// 重选
								itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 0));
								// 选择第一张牌
								PokerButton(currentGame.candidatedDown.getChildAt(FightLandlordGame.OPTR_RESELECT)).setSelected(true);
								// 出牌
								itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 3));
							}
						}
					});
				ListenerBinder.bind(otherTimer, TimerEvent.TIMER, function(e:TimerEvent):void {
                    currentGame.arrowTip.text = currentGame.arrowTip.text.replace(/\d+/g, String(MAX_CARDS_SELECT_TIME - otherTimer.currentCount));
                });
				// 可视组件
				ListenerBinder.bind(currentGame.btnBarPokers, ItemClickEvent.ITEM_CLICK, itemClick);
                ListenerBinder.bind(currentGame.btnBarPokers, FlexEvent.SHOW, show);
                ListenerBinder.bind(currentGame.btnBarPokers, FlexEvent.HIDE, hide);
                ListenerBinder.bind(currentGame.btnBarPokersTipA, ItemClickEvent.ITEM_CLICK, btnBarPokersTipHandler);
                ListenerBinder.bind(currentGame.btnBarPokersTipB, ItemClickEvent.ITEM_CLICK, btnBarPokersTipHandler);
                ListenerBinder.bind(currentGame.btnBarPokersTipC, ItemClickEvent.ITEM_CLICK, btnBarPokersTipHandler);
				setInitialized(true);
			}

			// 按照当前玩家序号，进行画面座次安排
			var tempCardsDealed:Array=new Array(currentGame.dealedDown, currentGame.dealedRight, currentGame.dealedLeft);
			var tempCardsCandidated:Array=new Array(currentGame.candidatedDown, currentGame.candidatedRight, currentGame.candidatedLeft);
			// 进行位移操作
			var index:int=0;
			while (index != localNumber - 1)
			{
				var temp:Object=tempCardsDealed.pop();
				tempCardsDealed.unshift(temp);
				temp=tempCardsCandidated.pop();
				tempCardsCandidated.unshift(temp);
				index++;
			}
			// 更改画面组件
			cardsDealedArray=new Array(playerCogameNumber);
			for (index=0; index < cardsDealedArray.length; index++)
			{
				cardsDealedArray[index]=tempCardsDealed[index];
			}
			cardsCandidatedArray=new Array(playerCogameNumber);
			for (index=0; index < cardsCandidatedArray.length; index++)
			{
				cardsCandidatedArray[index]=tempCardsCandidated[index];
			}
			currentGame.btnBarPokers.visible=false;
            currentGame.btnBarPokersTipA.visible = false;
            currentGame.btnBarPokersTipB.visible = false;
            currentGame.btnBarPokersTipC.visible = false;
			currentGame.timerTip.label="剩余时间：";
			currentGame.timerTip.minimum=0;
			currentGame.timerTip.maximum=MAX_CARDS_SELECT_TIME;
			currentGame.timerTip.mode=ProgressBarMode.MANUAL;
		}

		/**
		 *
		 * 游戏开始时，将系统分配的扑克进行排序
		 *
		 * @param event
		 *
		 */
		private function gameStartedHandler(event:FightLandlordGameEvent):void
		{
			// 显示系统洗牌后的结果，格式为：当前玩家待发牌 + "~" + "0=17;1=17;2=17"
			var results:Array=event.incomingData.split("~");
			var cardSequence:String=results[0];
			var cardNames:Array=FightLandlordGame.sortPokers(cardSequence);
			var poker:PokerButton=null;
			// 为当前玩家发牌
			for each (var cardName:String in cardNames)
			{
				poker=new PokerButton();
				poker.source="image/poker/" + cardName + ".png";
				currentGame.candidatedDown.addChild(poker);
			}

			// 其他玩家牌数
			var pokerNumberOfPlayers:String=results[1];
			var index:int=0;
			while (index != playerCogameNumber)
			{
				// 跳过当前玩家
				if (localNumber == index + 1)
				{
					index++;
					continue;
				}
				// 获取玩家手中的牌数
				var pokerNumberPattern:RegExp=new RegExp("^.*" + index + "=(\\d+).*$");
				var pokerNumber:int=Number(pokerNumberOfPlayers.replace(pokerNumberPattern, "$1"));
				// 获取当前玩家待发牌个数
				var cardsCandidated:Box=Box(cardsCandidatedArray[index]);
				// 为其他玩家发牌，全为牌的背面图案
				for (var i:int=0; i < pokerNumber; i++)
				{
					poker=new PokerButton();
					poker.source="image/poker/back.png";
					poker.allowSelect=false;
					cardsCandidated.addChild(poker);
				}
				index++;
			}

			// 上面三张底牌，全为牌的背面图案
			currentGame.candidatedUp.removeAllChildren();
			for (var j:int=0; j < playerCogameNumber; j++)
			{
				poker=new PokerButton();
				poker.source="image/poker/back.png";
				poker.allowSelect=false;
				currentGame.candidatedUp.addChild(poker);
				// 添加空牌位，以方便显示三张底牌的全部牌面
				for (var space:int=0; space < 3; space++)
				{
					currentGame.candidatedUp.addChild(new PokerButton());
				}
			}
		}

		/**
		 *
		 * 当前玩家为第一个发牌者时，开始进行游戏设置
		 *
		 * @param event
		 *
		 */
		private function gameFirstPlayHandler(event:FightLandlordGameEvent):void
		{
			var results:Array = new Array(event.incomingData.substr(0, 1), event.incomingData.substring(2));
            firstPlayerNumber = parseInt(results[0]);
            results[1] = results[1].toString().replace(/~[^~]+;$/, "");
            var initCardsOfPlayers:Array = results[1].toString().split(/~[^~]+;/g);
        	if (firstPlayerNumber == localNumber) {
            	PlatformAlert.show("游戏设置", "信息", FightLandlordGameSetting.getNoRushStyle(), gameSettingSelect);
        	}
        	pokerBox = new FightLandlordGameBox();
        	pokerBox.cardsOfPlayers = initCardsOfPlayers;
            var playerDirection:Array = new Array("下", "右", "上", "左");
            var index:int = 0;
            while (index != localNumber - 1) {
                var temp:Object = null;
                temp = playerDirection.pop();
                playerDirection.unshift(temp);
                index++;
            }
        	currentGame.arrowTip.text = "首次发牌玩家: " + playerDirection[firstPlayerNumber - 1];
		}

		/**
		 *
		 * 发送游戏设置
		 *
		 * @param event
		 *
		 */
		private function gameSettingSelect(event:PlatformAlertEvent):void
		{
			if (gameClient.currentState != "FIGHTLANDLORDGAME")
			{
				return;
			}
			// 更新游戏设置已经进行的次数
			gameSettingUpdateTimes++;

			var setting:int=-1;
			setting=int(event.detail);
			if (gameSetting == -1)
			{
				// 首次进行游戏设置时，直接发送本次的游戏设置
				socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
				gameSetting=setting;
				gameFinalSettingPlayerNumber=localNumber;
				if (setting == FightLandlordGameSetting.THREE_RUSH)
				{
					socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING_FINISH, localNumber + "~" + setting);
					// 准备出牌
					currentGame.btnBarPokers.visible=true;
					// 首次出牌需要禁用"不要"按键
					Button(currentGame.btnBarPokers.getChildAt(FightLandlordGame.OPTR_GIVEUP)).enabled=false;
				}
			}
			else if (gameSettingUpdateTimes == playerCogameNumber)
			{
				// 当前玩家为最后一个玩家时，马上可以开始游戏
				if (setting != FightLandlordGameSetting.NO_RUSH)
				{
					// 游戏设置为1分或2分时
					socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING_FINISH, localNumber + "~" + setting);
					socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
					gameSetting=setting;
					gameFinalSettingPlayerNumber=localNumber;
					// 准备出牌
					currentGame.btnBarPokers.visible=true;
					// 首次出牌需要禁用"不要"按键
					Button(currentGame.btnBarPokers.getChildAt(FightLandlordGame.OPTR_GIVEUP)).enabled=false;
				}
				else
				{
					// 游戏设置为不叫时
					// 如三家都不叫分时，系统初始分为1分
					if (gameSetting == 0)
					{
						setting=FightLandlordGameSetting.ONE_RUSH;
						gameSetting=setting;
					}
					socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING_FINISH, currentNumber + "~" + gameSetting);
					socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING, currentNumber + "~" + gameSetting + "~" + localNextNumber);
				}
			}
			else if (setting == FightLandlordGameSetting.NO_RUSH)
			{
				// 非首次和末次，不叫时，直接转发前次的游戏设置
				socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING, currentNumber + "~" + gameSetting + "~" + localNextNumber);
			}
			else if (setting == FightLandlordGameSetting.ONE_RUSH || setting == FightLandlordGameSetting.TWO_RUSH)
			{
				// 非首次和末次，1分或2分时，发送本次的游戏设置
				socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
				gameSetting=setting;
				gameFinalSettingPlayerNumber=localNumber;
			}
			else if (setting == FightLandlordGameSetting.THREE_RUSH)
			{
				socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING_FINISH, localNumber + "~" + gameSetting);
				// 非首次和末次，3分时，发送本次的游戏设置
				socketProxy.sendGameData(FightLandlordGameCommand.GAME_SETTING, localNumber + "~" + setting + "~" + localNextNumber);
				gameSetting=setting;
				gameFinalSettingPlayerNumber=localNumber;
				// 准备出牌
				currentGame.btnBarPokers.visible=true;
				// 首次出牌需要禁用"不要"按键
				Button(currentGame.btnBarPokers.getChildAt(FightLandlordGame.OPTR_GIVEUP)).enabled=false;
			}
		}

		/**
		 *
		 * 游戏设置结束，准备发牌
		 *
		 * @param event
		 *
		 */
		private function gameSettingUpdateHandler(event:FightLandlordGameEvent):void
		{
			gameSettingUpdateTimes++;
			var results:Array=event.incomingData.split("~");
			currentNumber=results[0];
			if (gameSetting < results[1])
			{
				gameSetting=results[1];
			}
			currentNextNumber=results[2];
			gameFinalSettingPlayerNumber=currentNumber;
			if (gameSettingUpdateTimes == playerCogameNumber)
			{
				// 每个玩家都进行过游戏设置，则可以开始游戏
				if (localNumber == currentNumber)
				{
					// 游戏设置结束，准备出牌
					currentGame.btnBarPokers.visible=true;
					// 首次出牌需要禁用"不要"按键
					Button(currentGame.btnBarPokers.getChildAt(FightLandlordGame.OPTR_GIVEUP)).enabled=false;
				}
			}
			else if (currentNextNumber == localNumber)
			{
				// 当前设置为不叫或非最后一个玩家的1分、2分，则继续进行游戏设置
				var alertButtons:Array=null;
				switch (gameSetting)
				{
					case FightLandlordGameSetting.NO_RUSH:
						// 当前游戏设置为不叫时
						alertButtons=FightLandlordGameSetting.getNoRushStyle();
						break;
					case FightLandlordGameSetting.ONE_RUSH:
						// 当前游戏设置为独时
						alertButtons=FightLandlordGameSetting.getRushStyle();
						break;
					case FightLandlordGameSetting.TWO_RUSH:
						// 当前游戏设置2分时
						alertButtons=FightLandlordGameSetting.getDeadlyRushStyle();
						break;
					case FightLandlordGameSetting.THREE_RUSH:
						return;
				}
				PlatformAlert.show("游戏设置", "信息", alertButtons, gameSettingSelect);
			}
		}

		/**
		 *
		 * 游戏设置结束，为地主发底牌
		 *
		 * @param event
		 *
		 */
		private function gameSettingUpdateFinishHandler(event:FightLandlordGameEvent):void
		{
			// 接收服务器发出的底牌，为地主添加，显示三张底牌给其它两家
			var results:Array=event.incomingData.split("~");
			var holderBoutCards:String=results[0];
			var holderNumber:int=results[1];
			var poker:PokerButton=null;
			// 将底牌显示在桌面上
			currentGame.candidatedUp.removeAllChildren();
			for each (var cardName:String in holderBoutCards.split(","))
			{
				poker=new PokerButton();
				poker.source="image/poker/" + cardName + ".png";
				poker.allowSelect=false;
				currentGame.candidatedUp.addChild(poker);
				// 添加空牌位，以方便显示三张底牌的全部牌面
				for (var space:int=0; space < 3; space++)
				{
					currentGame.candidatedUp.addChild(new PokerButton());
				}
			}
			// 为地主玩家发底牌
			// 获取当前玩家待发牌个数
			var cardsCandidated:Box=Box(cardsCandidatedArray[Number(holderNumber) - 1]);
			// 加完底牌后进行排序
			var cards:String=holderBoutCards;
			for each (var card:PokerButton in cardsCandidated.getChildren())
			{
				cards+="," + card.value;
			}
			var cardNames:Array=FightLandlordGame.sortPokers(cards);
			// 移除手中持有牌再添加
			cardsCandidated.removeAllChildren();
			for each (var cardName2:String in cardNames)
			{
				poker=new PokerButton();
				poker.source="image/poker/" + cardName2 + ".png";
				cardsCandidated.addChild(poker);
			}
			var index:int=0;
			while (index != playerCogameNumber)
			{
				// 跳过非地主玩家
				if (localNumber != index + 1)
				{
					// 获取当前玩家待发牌个数
					var cardsCandidatedBack:Box=Box(cardsCandidatedArray[index]);
					for each (var pokerBack:PokerButton in cardsCandidatedBack.getChildren())
					{
						pokerBack.source="image/poker/back.png";
						pokerBack.allowSelect=false;
					}
					index++;
					continue;
				}
				index++;
			}
		}
		
		/**
         *
         * 响应游戏设置结束事件
         *
         * @param event
         *
         */
        private function gameSettingOverHandler(event:FightLandlordGameEvent):void {
            var results:Array = event.incomingData.split("~");
            gameFinalSettingPlayerNumber = results[0];
            gameSetting = results[1];
            updateTip(-1, gameFinalSettingPlayerNumber, gameFinalSettingPlayerNumber != localNumber);
        }

		/**
		 *
		 * 接收到系统通知当前玩家出牌的消息，数据格式为：当前玩家序号~牌名,牌名...~下家玩家序号
		 *
		 * @param event
		 *
		 */
		private function gameBringOutHandler(event:FightLandlordGameEvent):void
		{
			// 接收上家出牌序列，显示出牌结果
			var results:Array=event.incomingData.split("~");
			currentNumber=results[0];
			currentBoutCards=results[1];
			currentNextNumber=results[2];
			var passed:Boolean=false;
			var count:int=0;
			var tempTile:Tile=null;

			// 在桌面上显示最近新出的牌
			if (results.length == 4)
			{
				// 获取"不要"标识
				passed=("pass" == results[3]);
			}
			// 上局待发牌区域
			var cardsCandidated:Box=cardsCandidatedArray[Number(currentNumber) - 1];
			// 上局已发牌区域
			var cardsDealed:Tile=cardsDealedArray[Number(currentNumber) - 1];
			// 获取牌序
			var cardNames:Array=currentBoutCards.split(",");
			// 更新发牌玩家的发牌区域
			if (passed)
			{
				// 上家不要时，显示不要的内容 TODO 间隔玩家？？？
				var currentIndex:int=(currentNextNumber - 1);
				var previousIndex:int=currentIndex == 0 ? playerCogameNumber - 1 : currentIndex - 1;
				var passLabel:Label=new Label();
				passLabel.text="不要";
				passLabel.setStyle("fontSize", 24);
				Tile(cardsDealedArray[previousIndex]).removeAllChildren();
				Tile(cardsDealedArray[previousIndex]).addChild(passLabel);
			}
			else
			{
				if (isOrderNeighbor(currentNumber, currentNextNumber))
				{
					// 如果牌序中的两个玩家为邻座的两个人，并且上下家顺序为逆时针，则为正常出牌
					count=cardNames.length;
					while (count-- > 0)
					{
						// 从待发牌中移除牌
						cardsCandidated.removeChildAt(0);
					}
				}
				// 上家出牌时，从已发牌中移除所有牌
				cardsDealed.removeAllChildren();
				for each (var cardName:String in cardNames)
				{
					// 向已发牌中添加牌
					var poker:PokerButton=new PokerButton();
					poker.allowSelect=false;
					poker.source="image/poker/" + cardName + ".png";
					cardsDealed.addChild(poker);
					// 更新内存模型
                    pokerBox.exportPoker(currentNumber - 1, cardNames[count]);
				}
			}

			// 全都"不要"时的首发牌，清除桌面上所有牌
			if (currentNumber == currentNextNumber)
			{
				for each (tempTile in cardsDealedArray)
				{
					tempTile.removeAllChildren();
				}
			}
// 2009/10/13 该功能可能需要保留
            // 全都"不要"时的首发牌，清除桌面上所有牌
            if (currentNumber == currentNextNumber) {
                for each (tempTile in cardsDealedArray) {
                    tempTile.removeAllChildren();
                }
            }
			// 为出牌玩家设置扑克操作按钮外观
			if (currentNextNumber == localNumber)
			{
				// 轮到当前玩家出牌时
				currentGame.btnBarPokers.visible=true;
				Button(currentGame.btnBarPokers.getChildAt(FightLandlordGame.OPTR_GIVEUP)).enabled=true;
				if (currentNumber == currentNextNumber)
				{
					// 如果消息中指定的发牌玩家序号与下家序号都等于当前玩家，
					// 即当前玩家最后一次出的牌，在回合中最大，本回合从当前玩家开始
					currentBoutCards=null;
					Button(currentGame.btnBarPokers.getChildAt(FightLandlordGame.OPTR_GIVEUP)).enabled=false;
				}
			}
			
			// 更新显示提示
            updateTip(currentNumber, currentNextNumber, !currentGame.btnBarPokers.visible);
		}

		/**
		 *
		 * 接收到当前玩家为第一个发牌者通知
		 *
		 * @param event
		 *
		 */
		private function gameInterruptedHandler(event:FightLandlordGameEvent):void
		{
			gameClient.currentState="LOBBY";
			gameClient.txtSysMessage.text+="游戏中断！请重新加入游戏！\n";
			CursorManager.removeBusyCursor();
		}

		/**
		 *
		 * 游戏结束
		 *
		 * @param event
		 *
		 */
		private function gameOverHandler(event:FightLandlordGameEvent):void
		{
			// 格式：发前玩家~牌序~接牌玩家
			var results:Array=event.incomingData.split("~");
			currentNumber=results[0];
			currentBoutCards=results[1];
			currentNextNumber=results[2];
			var scoreboardInfo:Array=String(results[3]).split(/;/);
			// 非出牌者时，移除桌面上显示的已出的牌，在桌面上显示最近新出的牌
            // if (localNumber != currentNumber && gameSetting != Red5GameSetting.EXTINCT_RUSH) {
            if (localNumber != currentNumber && isOrderNeighbor(currentNumber, currentNextNumber)) {
            	// 本局待发牌区域
                var cardsCandidated:Box = cardsCandidatedArray[currentNumber - 1];
                // 本局已发牌区域
                var cardsDealed:Tile = cardsDealedArray[currentNumber - 1];
                cardsDealed.removeAllChildren();
                var cardNames:Array = currentBoutCards.split(",");
                for each (var cardName:String in cardNames) {
                    // 为发牌区域添加已经发出的牌
                    var poker:PokerButton = new PokerButton();
                    poker.allowSelect = false;
                    poker.source = "image/poker/" + cardName + ".png";
                    cardsDealed.addChild(poker);
                    // 从待发牌区域移除已经发出的牌
                    cardsCandidated.removeChildAt(0);
                    // 更新内存
                    pokerBox.exportPoker(currentNumber - 1, cardName);
                }
            }
			// 开始亮牌，并从当前玩家的下家开始
            var startIndex:int = localNumber;
            for (var i:int = 1; i < playerCogameNumber; i++) {
            	if (startIndex == playerCogameNumber) {
            		startIndex = 0;
            	}
            	(cardsCandidatedArray[startIndex] as Box).removeAllChildren();
            	for each (var eachPoker:String in pokerBox.cardsOfPlayers[startIndex]) {
                    var pokerInHand:PokerButton = new PokerButton();
                    pokerInHand.source = "image/poker/" + eachPoker + ".png";
                    pokerInHand.allowSelect = false;
            		(cardsCandidatedArray[startIndex] as Box).addChild(pokerInHand);
            	}
            	startIndex++;
            }
			firstPlaceNumber=currentNumber;
			// 显示记分牌
			new Scoreboard().popUp(localNumber, scoreboardInfo, currentGameId,
					function():void
					{
						gameClient.currentState='LOBBY';
					});
			// 显示游戏积分
			var rushResult:String=null;
			if (firstPlaceNumber == gameFinalSettingPlayerNumber)
			{
				rushResult="成功！";
			}
			else
			{
				rushResult="失败！";
			}
			// 游戏结束，并且当前玩家不是最终的游戏规则设置者
			gameClient.txtSysMessage.text+=FightLandlordGameSetting.getDisplayName(gameSetting) + rushResult + "\n";
			 if (otherTimer.running) {
                otherTimer.stop();
            }
            CursorManager.removeBusyCursor();
		}

		/**
		 *
		 * 没有1分或2分的情况下，游戏中产生获胜者
		 *
		 * @param event
		 *
		 */
		private function gameWinnerProducedHandler(event:FightLandlordGameEvent):void
		{
			// 有新的获胜者产生，调整当前玩家次序
			var results:Array=event.incomingData.split("~");
			currentNumber=results[0];
			currentNextNumber=results[2];
			// 判断当前玩家是否是获胜者的上家
			if (localNextNumber == currentNumber)
			{
				// 当前玩家是获胜者的上家时，将当前玩家下家改成获胜者的下家
				localNextNumber=currentNextNumber;
			}
			// 判断当前玩家是否是获胜者下家
			if (currentNextNumber == localNumber)
			{
				// 当前玩家是否是获胜者下家时，设置标识符
				isWinnerFollowed=true;
			}
			// 更新画面表现
			gameBringOutHandler(event);
			// 设置游戏获胜者信息
			if (firstPlaceNumber == UNOCCUPIED_PLACE_NUMBER)
			{
				firstPlaceNumber=currentNumber;
			}
			else if (secondPlaceNumber == UNOCCUPIED_PLACE_NUMBER)
			{
				secondPlaceNumber=currentNumber;
			}
			else if (thirdPlaceNumber == UNOCCUPIED_PLACE_NUMBER)
			{
				thirdPlaceNumber=currentNumber;
				var placeNumberPattern:RegExp=new RegExp("[" + firstPlaceNumber + secondPlaceNumber + thirdPlaceNumber + "]", "g");
				forthPlaceNumber=Number("123".replace(placeNumberPattern, ""));
			}
//			var placeNumbers:Array=new Array(firstPlaceNumber, secondPlaceNumber, thirdPlaceNumber, forthPlaceNumber);
//			Alert.show("玩家[" + placeNumbers.join(",") + "]胜出！", "消息");
		}

		/**
		 *
		 * 游戏创建，为客户端玩家分配游戏id号与当前游戏玩家序号以及下家玩家序号
		 *
		 * @param event
		 *
		 */
		private function gameCreateHandler(event:GameEvent):void
		{
			var results:Array=null;
			if (event.incomingData != null)
			{
				results=event.incomingData.split("~");
			}
			FightLandlordGameStateManager.resetInitInfo();
			FightLandlordGameStateManager.currentGameId=results[0];
			FightLandlordGameStateManager.localNumber=results[1];
			FightLandlordGameStateManager.playerCogameNumber=results[2];
			if (FightLandlordGameStateManager.playerCogameNumber == FightLandlordGameStateManager.localNumber)
			{
				FightLandlordGameStateManager.localNextNumber=1;
			}
			else
			{
				FightLandlordGameStateManager.localNextNumber=FightLandlordGameStateManager.localNumber + 1;
			}
			gameClient.currentState="FIGHTLANDLORDGAME";
		}

		/**
		 *
		 * @param event
		 *
		 */
		private function gameWaitHandler(event:GameEvent):void
		{
			gameClient.txtSysMessage.text+=event.incomingData + "\n";
			gameClient.txtSysMessage.selectionEndIndex=gameClient.txtSysMessage.length - 1;
		}
		
		/**
		 *
		 * 扑克操作
		 *
		 * 1#cardSeq#2#cardSeq#3#cardSeq#4#cardSeq#
		 *
		 * cardSeq = 1V3,2V3,3V3,4V3|2V3,3V4,4V5,3V6
		 *
		 * @param event
		 *
		 */
		private function itemClick(event:ItemClickEvent):void
		{
			var card:PokerButton;
			var isGameOver:Boolean=false;
			switch (event.index)
			{
				case 0:
					// 重选
					for each (card in currentGame.candidatedDown.getChildren())
					{
						card.setSelected(false);
					}
					break;
				case 1:
					// 不要
					if (isWinnerFollowed)
					{
						// 如果当前玩家上家是获胜者时，需要重新设置获胜者发出的消息
						// 将获胜者牌更为当前玩家牌，以便在所有玩家“不要”的情况下
						// 可以由获胜者的直接下家出牌
						socketProxy.sendGameData(FightLandlordGameCommand.GAME_BRING_OUT, localNumber + "~" + currentBoutCards + "~" + localNextNumber + "~pass");
						isWinnerFollowed=false;
					}
					else
					{
						socketProxy.sendGameData(FightLandlordGameCommand.GAME_BRING_OUT, currentNumber + "~" + currentBoutCards + "~" + localNextNumber + "~pass");
						if (currentNumber == localNextNumber)
						{
// 2009/10/13 该功能可能需要保留
                            // 当前玩家在本回合中不要，且之前所有的玩家均不要的时候
                            for each (var cardsDealed:Tile in cardsDealedArray) {
                                cardsDealed.removeAllChildren();
                            }
							currentGame.btnBarPokers.visible=false;
//							return;
						}
					}
					// 在发牌区域显示"不要"标签
					var currentIndex:int=(localNumber - 1);
					var passLabel:Label=new Label();
					passLabel.text="不要";
					passLabel.setStyle("fontSize", 24);
					Tile(cardsDealedArray[currentIndex]).removeAllChildren();
					Tile(cardsDealedArray[currentIndex]).addChild(passLabel);
					// 出牌操作结束后，关闭扑克操作栏
					currentGame.btnBarPokers.visible=false;
					// 更新显示提示
                    updateTip(currentNumber, localNextNumber);
					break;
				case 2:
					// 提示
					// 1. 重选
					for each (card in currentGame.candidatedDown.getChildren())
					{
						card.setSelected(false);
					}
					// 2. 当前为发牌玩家选择第一张牌
					if (currentBoutCards == null || currentBoutCards.split(",").length == 0)
					{
						PokerButton(currentGame.candidatedDown.getChildAt(FightLandlordGame.OPTR_RESELECT)).setSelected(true);
						break;
					}
					// 3. 选择要出的牌
					// 3.1 正常牌比较不包含炸弹火箭
					var isSelectCard:Boolean = FightLandlordGame.isPopRuleFollowed(currentGame.candidatedDown.getChildren(), currentBoutCards);
//					// 3.2 炸弹
//					if (!isSelectCard)
//					{
//						isSelectCard = compareCards(4);
//					}
//					// 3.3 火箭
//					if (!isSelectCard)
//					{
//						isSelectCard = compareCards(2);
//					}
					// 4. 没有可提示的牌
					if (!isSelectCard)
					{
						itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 1));
					}
					break;
				case 3:
					// 出牌
					// 选择要出的牌
					var cardsBox:String="";
					for each (card in currentGame.candidatedDown.getChildren())
					{
						if (card.isSelected())
						{
							cardsBox+=card.value + ",";
						}
					}
					cardsBox=cardsBox.replace(/,$/, "");
					// 未作任何选择时，直接退出处理
					if (cardsBox.length == 0)
					{
						return;
					}
					// 规则验证
					if (!FightLandlordGame.isRuleFollowed(cardsBox, currentBoutCards))
					{
						itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, 0));
						return;
					}
					// 出牌过程中出现炸弹或火箭时陪数增加
					if (FightLandlordGame.isBombStyle(cardsBox) || FightLandlordGame.isRocketStyle(cardsBox))
					{
						socketProxy.sendGameData(FightLandlordGameCommand.GAME_BOMB, localNumber + "~" + cardsBox + "~" + localNextNumber + "~double");
					}
					// 设置出牌结果
					// 当前剩余的牌数
					var cardsCandicateNumber:int=currentGame.candidatedDown.getChildren().length;
					// 即将打出的牌数
					var cardsDealedNumber:int=cardsBox.split(",").length;
					// 打出后剩余牌数
					var cardsLeftNumber:int=cardsCandicateNumber - cardsDealedNumber;

					// 非地主玩家是否出过牌
					if (gameFinalSettingPlayerNumber != localNumber)
					{
						isHaveOut=true;
					}
					// 地主玩家是否出过第二手牌
					if (gameFinalSettingPlayerNumber == localNumber)
					{
						holderOutTimes++;
					}
					if (cardsLeftNumber == 0)
					{
						// 设置游戏冠军玩家
						if (gameFinalSettingPlayerNumber != localNumber)
						{
							firstPlaceNumber=localNumber;
							// 两家中有一家出完牌，而地主仅仅出过一手牌，分数×2 。
							if (holderOutTimes == 1)
							{
								socketProxy.sendGameData(FightLandlordGameCommand.GAME_BOMB, localNumber + "~" + cardsBox + "~" + localNextNumber + "~double");
							}
						}
						else
						{
							firstPlaceNumber=gameFinalSettingPlayerNumber;
							// 地主把牌出完，其余两家一张牌都没出，分数×2 ；
							if (!isHaveOut)
							{
								socketProxy.sendGameData(FightLandlordGameCommand.GAME_BOMB, localNumber + "~" + cardsBox + "~" + localNextNumber + "~double");
							}
						}
						socketProxy.sendGameData(FightLandlordGameCommand.GAME_WIN_AND_END, localNumber + "~" + cardsBox + "~" + localNextNumber);
						isGameOver=true;
					}
					else if (cardsLeftNumber > 0)
					{
						// 当前规则下，出牌玩家手中还有剩余牌，并未获胜，正常出牌的情况
						if (isWinnerFollowed)
						{
							// 没有独牌或天独，并且第一个获胜者牌最大
							// 构造出牌数据，当前玩家序号~牌名,牌名...~下家玩家序号
							socketProxy.sendGameData(FightLandlordGameCommand.GAME_BRING_OUT, localNumber + "~" + cardsBox + "~" + localNextNumber);
							isWinnerFollowed=false;
						}
						else
						{
							// 构造出牌数据，当前玩家序号~牌名,牌名...~下家玩家序号
							socketProxy.sendGameData(FightLandlordGameCommand.GAME_BRING_OUT, localNumber + "~" + cardsBox + "~" + localNextNumber);
						}
					}
					else
					{
						throw Error("其他无法预测的出牌动作！");
					}
					// 更新客户端扑克显示
					currentGame.dealedDown.removeAllChildren();
					for each (card in currentGame.candidatedDown.getChildren())
					{
						if (card.isSelected())
						{
							currentGame.candidatedDown.removeChild(card);
							currentGame.dealedDown.addChild(card);
							card.allowSelect=false;
						}
					}
					// 出牌操作结束后，关闭扑克操作栏
					currentGame.btnBarPokers.visible=false;
					// 更新显示提示
                    updateTip(localNumber, localNextNumber);
					break;
			}
		}

		/**
		 *
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
		 *
		 */
		private function show(event:FlexEvent):void
		{
			// 显示进度条，倒计时开始开始
			currentGame.timerTip.setProgress(MAX_CARDS_SELECT_TIME, MAX_CARDS_SELECT_TIME);
			currentGame.timerTip.label="剩余#秒".replace(/#/g, MAX_CARDS_SELECT_TIME);
			currentGame.timerTip.visible=true;
			timer.start();
			CursorManager.removeBusyCursor();
		}
		
		/**
         * 
         * 响应用户自主选牌提示
         * 
         * @param event
         * 
         */
        private function btnBarPokersTipHandler(event:ItemClickEvent):void {
            itemClick(new ItemClickEvent(ItemClickEvent.ITEM_CLICK, false, false, null, FightLandlordGame.OPTR_RESELECT));
            var tipArray:Array = null;
            if (event.currentTarget == currentGame.btnBarPokersTipA) {
                // 对子、三同张、四同张、五同张、六同张、七同张、八同张
                tipArray = FightLandlordGame.nextTipCards(event.index + 101);
            } else if (event.currentTarget == currentGame.btnBarPokersTipB) {
                // 四连顺、五连顺、对子三连顺、对子四连顺、对子五连顺
                tipArray = FightLandlordGame.nextTipCards(event.index + 201);
            } else if (event.currentTarget == currentGame.btnBarPokersTipC) {
                // 三同张三连顺、三同张四连顺、三同张五连顺、四同张三连顺
                tipArray = FightLandlordGame.nextTipCards(event.index + 301);
            }
            var i:int = 0;
            var eachPokerButton:PokerButton = null;
            if (tipArray) {
                for each (eachPokerButton in currentGame.candidatedDown.getChildren()) {
                    // 不计花色比较
                    if (eachPokerButton.value.replace(/\d/, "") == tipArray[i]) {
                        eachPokerButton.setSelected(true);
                        i++;
                    } else if (event.currentTarget == currentGame.btnBarPokersTipA && 
                            (event.index + 101) == FightLandlordGame.TIPA_MUTIPLE2 && 
                            eachPokerButton.value == tipArray[i]) {
                        // 对子，且目标值带有花色，即大小王和红五时
                        eachPokerButton.setSelected(true);
                        i++;
                    }
                }
            }
        }

		/**
		 *
		 * 轮到当前玩家出牌时，开始倒计时，时间到则自动进行pass，若为首发牌，打出最小的一张牌
		 *
		 */
		private function hide(event:FlexEvent):void
		{
			// 进度条隐藏，并重置计时器
			currentGame.timerTip.visible=false;
			timer.reset();
			CursorManager.removeBusyCursor();
		}
		
		/**
         * 
         * 更新游戏提示信息 
         * 
         * @param lastBoutedNumber 最后出牌玩家编号
         * @param nextNumber 准备出牌的玩家编号
         * 
         */
        private function updateTip(lastBoutedNumber:int, nextNumber:int, showOtherTime:Boolean = true):void {
            // 参数初始化
            // 显示游戏提示
            var tipString:String = "准备出牌玩家：#，\n最后出牌玩家：#。";
            var playerDirection:Array = new Array("下", "右", "左");
            var index:int = 0;
            while (index != localNumber - 1) {
                var temp:Object = null;
                temp = playerDirection.pop();
                playerDirection.unshift(temp);
                index++;
            }
            // 显示游戏提示：指示当前要出牌的玩家
            tipString = tipString.replace(/#/, playerDirection[nextNumber - 1]);
            // 显示游戏提示：指示最后出了牌的玩家，首次发牌时，lastBoutedNumber小于零
            tipString = tipString.replace(/#/, lastBoutedNumber < 0 ? "无" : playerDirection[lastBoutedNumber - 1]);

            if (gameSetting == FightLandlordGameSetting.NO_RUSH) {
                currentGame.arrowTip.text = "游戏没有人独牌！\n" + tipString;
            } else {
                currentGame.arrowTip.text = "游戏#方玩家#！\n".replace(/#/, playerDirection[gameFinalSettingPlayerNumber - 1]);
                currentGame.arrowTip.text = currentGame.arrowTip.text.replace(/#/, FightLandlordGameSetting.getDisplayName(gameSetting));
                currentGame.arrowTip.text = currentGame.arrowTip.text + tipString;
            }
        	currentGame.arrowTip.text = "获得首发牌红心十玩家: " + playerDirection[firstPlayerNumber - 1] + "\n" + currentGame.arrowTip.text;
            if (showOtherTime) {
                // 非当前玩家出牌时，显示动态提示
                currentGame.arrowTip.text = currentGame.arrowTip.text + "\n等待其他玩家出牌" + MAX_CARDS_SELECT_TIME + "秒！";
                if (otherTimer.running) {
                    otherTimer.stop();
                }
                otherTimer.reset();
                otherTimer.start();
            }
        }


		/**
		 *
		 * 判断两个玩家是否为逆时针顺序紧挨着的
		 *
		 * @param previousNumber
		 * @param nextNumber
		 *
		 */
		public static function isOrderNeighbor(number:int, nextNumber:int):Boolean
		{
			var initOrder:String="123";
			if (firstPlaceNumber != UNOCCUPIED_PLACE_NUMBER)
			{
				initOrder=initOrder.replace(new RegExp(firstPlaceNumber, "g"), "");
			}
			if (secondPlaceNumber != UNOCCUPIED_PLACE_NUMBER)
			{
				initOrder=initOrder.replace(new RegExp(secondPlaceNumber, "g"), "");
			}
			if (thirdPlaceNumber != UNOCCUPIED_PLACE_NUMBER)
			{
				Alert.show("isOrderNeighbor[thirdPlaceNumber != UNOCCUPIED_PLACE_NUMBER]");
			}
			// 取得索引号
			var index:int=initOrder.indexOf(String(number));
			var nextIndex:int=initOrder.indexOf(String(nextNumber));
			if (initOrder.length == 2)
			{
				return true;
			}
			// 计算所有间隔
			var indexInterval:int=nextIndex - index;
			return (indexInterval == 1 || indexInterval == 1 - initOrder.length);
		}

		/**
		 *
		 * 重置参数初始化
		 *
		 */
		public static function resetInitInfo():void
		{
			// 参数初始化
			playerCogameNumber=0;
			gameSetting=-1;
			gameFinalSettingPlayerNumber=-1;
			gameSettingUpdateTimes=0;
			currentGameId=null;
			localNumber=0;
			localNextNumber=0;
			currentNumber=0;
			currentBoutCards=null;
			currentNextNumber=0;
			firstPlaceNumber=UNOCCUPIED_PLACE_NUMBER;
			secondPlaceNumber=UNOCCUPIED_PLACE_NUMBER;
			thirdPlaceNumber=UNOCCUPIED_PLACE_NUMBER;
			forthPlaceNumber=UNOCCUPIED_PLACE_NUMBER;
			isWinnerFollowed=false;
			for each (var cardsDealed:Tile in cardsDealedArray)
			{
				cardsDealed.removeAllChildren();
			}
			for each (var cardsCandidated:Box in cardsCandidatedArray)
			{
				cardsCandidated.removeAllChildren();
			}
			if (currentGame) {
                currentGame.arrowTip.text = "";
            }
		}

	}
}