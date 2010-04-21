package info.knightrcom.state.fightlandlordgame
{
	
	import component.PokerButton;
	
	/**
	 *
	 * 方法中所有的参数形式均为 \dV([2-9JQKAXY]|10)(,\dV([2-9JQKAXY]|10))*
	 * 并且是已经排好顺序
	 *
	 */
	public class FightLandlordGame
	{

		public function FightLandlordGame()
		{
		}

		private static const prioritySequence:String="V3,V4,V5,V6,V7,V8,V9,V10,VJ,VQ,VK,VA,V2,VX,VY";
		
		/** 操作动作名称  */
		/** 重选 */
		public static const OPTR_RESELECT:int = 0;
		/** 不要 */
		public static const OPTR_GIVEUP:int = 1;
		/** 提示 */
		public static const OPTR_HINT:int = 2;
		/** 出牌 */
		public static const OPTR_DISCARD:int = 3;

		// 三带单中三同顺的连续个数 333444-》2 333444555-》3
		private static var followStyleCount:int=0;
		
		private static var followCardMap:*;
		
		/**
		 * 对服务器端洗牌后分配的尚未排序过的扑克进行排序
		 *
		 * @param cards
		 * @return
		 *
		 */
		public static function sortPokers(cards:String):Array
		{
			var cardArray:Array=cards.split(",");
			cardArray.sort(cardSorter);
			return cardArray;
		}

		/**
		 *
		 * @param card1
		 * @param card2
		 * @return
		 *
		 */
		private static function cardSorter(card1:String, card2:String):int
		{
			if (card1 == card2)
			{
				// 值与花色都相同时
				return 0;
			}
			// 实现排序功能
			var pri1:int=prioritySequence.indexOf(card1.replace(/^[0-4]/, ""));
			var pri2:int=prioritySequence.indexOf(card2.replace(/^[0-4]/, ""));
			// 值比较
			if (pri1 > pri2)
			{
				return 1;
			}
			else if (pri1 < pri2)
			{
				return -1;
			}
			// 值相同时，进行花色比较
			if (card1.charAt(0) > card2.charAt(0))
			{
				return 1;
			}
			else if (card1.charAt(0) < card2.charAt(0))
			{
				return -1;
			}
			return 0;
		}

		/**
		 *
		 * 严重发牌规则，分为两种验证：首发、接牌
		 *
		 * @param previousBout
		 * @param currentBout
		 * @return
		 *
		 */
		public static function isRuleFollowed(currentBout:String, previousBout:String=null):Boolean
		{
			if (previousBout == null)
			{
				// 首次发牌判断
				return isStartRuleFollowed(currentBout);
			}
			// 接牌判断
			return isBoutRuleFollowed(currentBout, previousBout);
		}

		/**
		 *
		 * 首次发牌时进行校验
		 *
		 * @param currentBout
		 * @return
		 *
		 */
		public static function isStartRuleFollowed(currentBout:String):Boolean
		{
			return isSingleStyle(currentBout) || isSeveralFoldStyle(currentBout) || isStraightStyle(currentBout) || isFollowStyle(currentBout) || isFourByTwoStyle(currentBout) || isBombStyle(currentBout) || isRocketStyle(currentBout);
		}

		/**
		 *
		 * 将前次牌序内容与本次将要打出的牌序内容进行校验
		 *
		 * @param currentBout
		 * @param previousBout
		 * @return
		 *
		 */
		public static function isBoutRuleFollowed(currentBout:String, previousBout:String):Boolean
		{
			// 如果当前发牌为火箭时，继续出牌
			if (isRocketStyle(currentBout))
			{
				return true;
			}
			// 如果上家发牌为火箭时，不出牌
			if (isRocketStyle(previousBout))
			{
				return false;
			}
			// 牌数不一致
			if (previousBout.split(",").length != currentBout.split(",").length)
			{
				// 如果当前出牌为炸弹时
				if (isBombStyle(currentBout))
				{
					return true;
				}
				return false;
			}
			// 牌数一致且能管上的特殊条件
			if (previousBout.split(",").length == currentBout.split(",").length)
			{
				// 如果上把牌是三带单，当前牌为炸弹
				if (isFollowStyle(previousBout) && isBombStyle(currentBout))
				{
					return true;
				}
			}
			if ((isSingleStyle(previousBout) && isSingleStyle(currentBout)))
			{
				currentBout=currentBout.replace(/^[0-4]/, "");
				previousBout=previousBout.replace(/^[0-4]/, "");
				return prioritySequence.indexOf(currentBout) > prioritySequence.indexOf(previousBout);
			}
			else if (isSeveralFoldStyle(previousBout) && isSeveralFoldStyle(currentBout))
			{
				// 符合样式规则后，验证大小规则
				currentBout=currentBout.replace(/^[0-4](V[^,]+).*$/, "$1");
				previousBout=previousBout.replace(/^[0-4](V[^,]+).*$/, "$1");
				return prioritySequence.indexOf(currentBout) > prioritySequence.indexOf(previousBout);
			}
			else if (isBombStyle(previousBout) && isBombStyle(currentBout))
			{
				// 符合样式规则后，验证大小规则
				currentBout=currentBout.replace(/^[0-4](V[^,]+).*$/, "$1");
				previousBout=previousBout.replace(/^[0-4](V[^,]+).*$/, "$1");
				return prioritySequence.indexOf(currentBout) > prioritySequence.indexOf(previousBout);
			}
			else if (isStraightStyle(previousBout) && isStraightStyle(currentBout))
			{
				// 判断倍数是否相同
				if (getMultiple(currentBout) != getMultiple(previousBout))
				{
					return false;
				}
				// 符合倍数规则后，验证顺子的大小规则，只判断首牌即可
				currentBout=currentBout.replace(/^[0-4]([^,]+).*$/, "$1");
				previousBout=previousBout.replace(/^[0-4]([^,]+).*$/, "$1");
				return prioritySequence.indexOf(currentBout) > prioritySequence.indexOf(previousBout);
			}
			else if (isFollowStyle(previousBout) && isFollowStyle(currentBout))
			{
				// 构造排序后的字符串进行比较
				var currentBoutAf:String=reMakeCardArray(currentBout).replace(/^([^,]+).*$/, "$1");
				var previousBoutAf:String=reMakeCardArray(previousBout).replace(/^([^,]+).*$/, "$1");
				return prioritySequence.indexOf(currentBoutAf) > prioritySequence.indexOf(previousBoutAf);
			}
			else if (isFourByTwoStyle(previousBout) && isFourByTwoStyle(currentBout))
			{
				// 构造排序后的字符串进行比较
				var currentBoutAf2:String=reBuildCardArray(currentBout).replace(/^([^,]+).*$/, "$1");
				var previousBoutAf2:String=reBuildCardArray(previousBout).replace(/^([^,]+).*$/, "$1");
				return prioritySequence.indexOf(currentBoutAf2) > prioritySequence.indexOf(previousBoutAf2);
			}
			else
			{
				// 其它所有的错误样式
				return false;
			}
		}
		
		/**
		 *
		 * 将前次牌序内容与本次将要打出的牌序内容进行校验[提示]
		 *
		 * @param currentBout
		 * @param previousBout
		 * @return
		 *
		 */
		public static function isPopRuleFollowed(currentBout:Array, previousBout:String):Boolean
		{
			// 单调
			if (isSingleStyle(previousBout)) {
				for each(var card:PokerButton in currentBout)   
				{ 
					if (prioritySequence.indexOf(card.value.replace(/^[0-4]/, "")) > prioritySequence.indexOf(previousBout.replace(/^[0-4]/, "")))
					{
						card.setSelected(true);
						return true;
					}
				}
				return false;
			}
			// 成倍且不成顺子
			if (isSeveralFoldStyle(previousBout))
			{
				// 取得倍数
				var len:int = getMultiple(previousBout);
				var times:int = 0; // 计数
				var currentCards:* = new Object(); // 累计牌型
				var cardString:String = "";
				var tempTimes:int = 0;
				for each(var cardPB:PokerButton in currentBout)   
				{ 
					cardString = cardPB.value.replace(/^[0-4]/, "");
					if (prioritySequence.indexOf(cardString) > prioritySequence.indexOf(previousBout.split(",")[0].replace(/^[0-4]/, "")))
					{
						if (currentCards[cardString] === undefined)
						{
							currentCards[cardString] = 0;
						}
						currentCards[cardString] += 1;
						if (currentCards[cardString] ==  len)
						{
							for each(var cardP:PokerButton in currentBout)   
							{ 
								if (cardP.value.toString().replace(/^[0-4]/,"") == cardString && ++tempTimes <= len)
								{
									trace(cardP.value);
									cardP.setSelected(true);
								}
								if (tempTimes == len)
								{
									return true;
								}
							}  
							break;
						}
					}
				}
			}
			return false;
		}
		
		/**
		 *
		 * 单调
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		private static function isSingleStyle(boutCards:String):Boolean
		{
			var ptn:RegExp=/^[0-4]V([^,]+)$/;
			return ptn.test(boutCards);
		}

		/**
		 *
		 * 成倍且不成顺子
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		private static function isSeveralFoldStyle(boutCards:String):Boolean
		{
			var ptn:RegExp=/^[0-4]V([^,]+)(,[0-4]V\1){1,2}$/;
			return ptn.test(boutCards);
		}

		/**
		 *
		 * 炸弹
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		public static function isBombStyle(boutCards:String):Boolean
		{
			var ptn:RegExp=/^[0-4]V([^,]+)(,[0-4]V\1){3}$/;
			return ptn.test(boutCards);
		}

		/**
		 *
		 * 火箭
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		public static function isRocketStyle(boutCards:String):Boolean
		{
			var ptn:RegExp=/^[0]VX(,[0]VY)$/;
			return ptn.test(boutCards);
		}

		/**
		 *
		 * 四带二 四张牌＋任意两套张数相同的牌。例如：5555＋3＋8或 4444＋55＋77
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		public static function isFourByTwoStyle(boutCards:String):Boolean
		{
			var ptnDouble2:RegExp=/^(V\w+)\1{3}(V\w+)\2(V\w+)\3$/;
			var ptnSingle2:RegExp=/^(V\w+)\1{3}(V\w+)(V\w+)$/;

			// 重构排序后的字符串
			var newCardString:String=reBuildCardArray(boutCards);
			if (newCardString == null)
			{
				return false;
			}
			var reCardArray:Array=newCardString.split(",");
			// 四带两单
			if (reCardArray.length == 6)
			{
				// 验证四带两单 
				if (reCardArray[4] == reCardArray[5])
				{
					return false;
				}
				return ptnSingle2.test(newCardString.replace(/,/g, ""));
			}
			// 四带两对
			if (reCardArray.length == 8)
			{
				// 验证四带两单 
				if (reCardArray[4] == reCardArray[6])
				{
					return false;
				}
				return ptnDouble2.test(newCardString.replace(/,/g, ""));
			}

			return false;
		}

		/**
		 *
		 * 对四带二的牌进行重新排序组合 例如：5555＋3＋8或 4444＋55＋77
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		private static function reBuildCardArray(boutCards:String):String
		{
			var cardArray2:Array=boutCards.split(",");
			var map2:*= new Object();
			var count2:int=0;
			for each (var card2:String in cardArray2)
			{
				// 去花色
				var pri2:String=card2.replace(/\b\dV/g, "V");
				if (map2[pri2] === undefined)
				{
					map2[pri2] = 1;
				}
				else
				{
					count2=map2[pri2] as int;
					map2[pri2] = ++count2;
				}
			}
			var newCardArray2:Array=new Array();
			for each (var cardAf2:String in cardArray2)
			{
				// 去花色
				var priAf2:String=cardAf2.replace(/\b\dV/g, "V");
				newCardArray2.push({cardName:priAf2, cardCount:map2[priAf2] as int});
			}
			// 重新构造按同号顺序由大到小排序后的字段串
			var reCardArray2:Array=newCardArray2.sort(boutCardSorter);

			var newCardString2:String="";
			for (var i:int=0; i < reCardArray2.length; i++)
			{
				newCardString2+=(reCardArray2[i]).cardName;
				if (i != reCardArray2.length - 1)
				{
					newCardString2+=",";
				}
			}
			return newCardString2;
		}

		/**
		 *
		 * 三带单或三带对
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		public static function isFollowStyle(boutCards:String):Boolean
		{
//        	var ptn:RegExp = /^V([^,]+)(,V\1){2}(,V[^\1]){1,2}$/;
			var ptnDouble:RegExp=/^(V\w+)\1{2}(V\w+)\2$/;
			var ptnSingle:RegExp=/^(V\w+)\1{2}(V\w+)$/;
			// 用来验证三带单中单中是否包括任意两个同号的牌
			var validateSingle:*=new Object();
			// 重构排序后的字符串
			var newCardString:String=reMakeCardArray(boutCards);
			if (newCardString == null)
			{
				return false;
			}
			var reCardArray:Array=newCardString.split(",");
			// 判断三倍的号是否连续且判断带牌是否格式相同
			if (reCardArray.length >= 8)
			{
				// 出现20张牌 4同顺带4对，5同顺带5单
				var bool:int=0;
				if (reCardArray.length == 20)
				{
					if (followStyleCount == 5)
					{
						bool=1;
					}
					if (followStyleCount == 4)
					{
						bool=2;
					}
				}
				// 都是三带单
				if (reCardArray.length % 4 == 0 && bool < 2)
				{
					// 对每组三带单进行规则验证
					for (var four:int=0; four < reCardArray.length / 4; four++)
					{
						// 三带单中的单序列遍历
						var singleCard:String=reCardArray[followStyleCount * 3 + four];
						if (singleCard == null)
						{
							return false;
						}
						var cardPokersSingle:String=reCardArray[four * 3] + reCardArray[four * 3 + 1] + reCardArray[four * 3 + 2] + singleCard;
						// 验证非三同张的牌序中是否包括对牌
						if (!(validateSingle[singleCard] === undefined))
						{
							return false;
						}
						validateSingle[singleCard] = singleCard;
						// 为防止前三张与后单张或后一张相同
						if (reCardArray[four] == singleCard)
						{
							return false;
						}
						if (!ptnSingle.test(cardPokersSingle))
						{
							return false;
						}
					}
					return true;
				}
				else if (reCardArray.length % 5 == 0)
				{
					// 都是三带对
					// 对每组三带对进行规则验证
					for (var five:int=0; five < reCardArray.length / 5; five++)
					{
						// 三带对中的对子序列遍历
						var pirCardfirst:String=reCardArray[(followStyleCount * 3) + (five * 2)];
						var pirCardsecond:String=reCardArray[(followStyleCount * 3) + (five * 2) + 1];
						if (pirCardfirst == null || pirCardsecond == null)
						{
							return false;
						}
						// 验证是否是对子
						if (pirCardfirst != pirCardsecond)
						{
							return false;
						}
						var cardPokersDouble:String=reCardArray[five * 3] + reCardArray[five * 3 + 1] + reCardArray[five * 3 + 2] + pirCardfirst + pirCardsecond;
						// 为防止前三张与后单张或后一对相同
						if (reCardArray[five * 3] == pirCardfirst)
						{
							return false;
						}
						if (!ptnDouble.test(cardPokersDouble))
						{
							return false;
						}
					}
					return true;
				}

			}

			var cardPokers:String=newCardString.replace(/,/g, "");
			// 为防止前三张与后单张或后一对相同
			if (reCardArray[0] == reCardArray[reCardArray.length - 1])
			{
				return false;
			}
			if (reCardArray.length == 4)
			{
				return ptnSingle.test(cardPokers);
			}
			else if (reCardArray.length == 5)
			{
				return ptnDouble.test(cardPokers);
			}
			return false;
		}

		/**
		 *
		 * 对三带一的牌进行重构，对同号的牌统计数量，做为比较的依据
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		private static function reMakeCardArray(boutCards:String):String
		{
			var cardArray:Array=boutCards.split(",");
			var map:*=new Object();
			var tempFollow:String="";
			var count1:int=0;
			for each (var card:String in cardArray)
			{
				// 去花色
				var pri:String=card.replace(/\b\dV/g, "V");
				if (map[pri] === undefined)
				{
					map[pri] = 1;
				}
				else
				{
					count1=map[pri] as int;
					// 判断是否包含4同号的牌
					if (count1 >= 3)
					{
						return null;
					}
					map[pri] = ++count1;
					// 存储三同张的牌
					if (count1 == 3)
					{
						tempFollow+=pri + ",";
					}
				}
			}
			followCardMap = map;
			var newCardArray:Array=new Array();
			for each (var cardAf:String in cardArray)
			{
				// 去花色
				var priAf:String=cardAf.replace(/\b\dV/g, "V");
				newCardArray.push({cardName:priAf, cardCount:map[priAf] as int});
			}
			// 对三同张的牌进行排序并判断是否是三同顺
			tempFollow=tempFollow.replace(/,$/, "");
			if (cardArray.length > 5)
			{
				var tempFollowArr:Array=sortPokers(tempFollow);
				followStyleCount=tempFollowArr.length
				tempFollow="";
				for (var indTemp:int; indTemp < followStyleCount; indTemp++)
				{
					tempFollow+=tempFollowArr[indTemp] + ",";
				}
				tempFollow=tempFollow.replace(/,$/, "");
				if (!(prioritySequence.indexOf(tempFollow) > -1))
				{
					return null;
				}

			}
			// 重新构造按同号顺序由大到小排序后的字段串
			var reCardArray:Array=newCardArray.sort(boutCardSorter);

			var newCardString:String="";
			for (var i:int=0; i < reCardArray.length; i++)
			{
				newCardString+=(reCardArray[i]).cardName;
				if (i != reCardArray.length - 1)
				{
					newCardString+=",";
				}
			}
			return newCardString;
		}

		/**
		 *
		 * @param card1
		 * @param card2
		 * @return
		 *
		 */
		private static function boutCardSorter(card1:Object, card2:Object):int
		{
			// 实现排序功能
			// 数量相同时比较牌号大小
			if (card1.cardCount == card2.cardCount)
			{
				if (prioritySequence.indexOf(card1.cardName) > prioritySequence.indexOf(card2.cardName))
				{
					return 1;
				}
				else if (prioritySequence.indexOf(card1.cardName) < prioritySequence.indexOf(card2.cardName))
				{
					return -1;
				}
				else
				{
					return 0;
				}
			}
			else if (card1.cardCount < card2.cardCount)
			{
				return 1;
			}
			else if (card1.cardCount > card2.cardCount)
			{
				return -1;
			}
			return 0;
		}

		/**
		 *
		 * 顺子
		 *
		 * @param boutCards
		 * @return
		 *
		 */
		private static function isStraightStyle(boutCards:String):Boolean
		{
			var ptn:RegExp=/^.*V[2XY].*$/;
			if (ptn.test(boutCards))
			{
				// 2、王不能作为顺子的内容
				return false;
			}
			// 去花色
			var resultCards:String=(boutCards + ",").replace(/\b\dV/g, "V");
			// 去重复项目
			resultCards=(resultCards).replace(/(V[^,]+,)\1*/g, "$1");
			// 倍数验证，防止个别牌的倍数与其他牌的倍数不一致
			if ((boutCards + ",").replace(/\b\dV/g, "V").length % resultCards.length == 0)
			{
				// 倍数全相同时，判断是否满足最小序列的条件，比如JQKA单倍时，至少要四张
				// 比如JQK双倍时，至少要三张；比如JQ三倍时，至少要两张
				var multiple:int=(boutCards + ",").replace(/\b\dV/g, "V").length / resultCards.length;
				if (multiple == 1)
				{
					// 单牌顺子
					if (resultCards.replace(/,$/, "").split(",").length < 5)
					{
						return false;
					}
				}
				else if (multiple == 2)
				{
					// 双顺
					if (resultCards.replace(/,$/, "").split(",").length < 3)
					{
						return false;
					}
				}
				else if (multiple > 2)
				{
					// 三顺
					if (resultCards.replace(/,$/, "").split(",").length < 2)
					{
						return false;
					}
				}
				else
				{
					throw Error("顺子处理出错！");
				}
				// 间隔值判断，相邻的牌必须连续
				return prioritySequence.indexOf(resultCards) > -1;
			}
			else
			{
				// 不能整除代表牌中有的倍数有问题
				return false;
			}
		}
		
		/**
         *
         * 取得倍数，适用于单调、倍数牌、顺子
         * 
         * @param boutCards 当前打出的牌 
         * @return
         *
         */
        private static function getMultiple(boutCards:String):int {
            // 去花色
            var resultCards:String = (boutCards + ",").replace(/\b\dV/g, "V");
            // 去重复项目
            resultCards = (resultCards).replace(/(V[^,]+,)\1*/g, "$1");
            return (boutCards + ",").replace(/\b\dV/g, "V").length / resultCards.length;
        }
        
        /**
         *
         * 取得顺子长度
         * 
         * @param boutCards 当前打出的牌 
         * @return
         *
         */
        private static function getStraightLength(boutCards:String):int {
            return boutCards.split(",").length / getMultiple(boutCards);
        }

		/**
         * 对子、三同张、四同张 …… N同张
         * 
         * @param multiple >= 2
         * @param myCards
         * @param boutCards
         * 
         * @return an array of an array
         * 
         */
        public static function grabMultiple(multiple:int, myCards:Array, boutCards:Array = null):Array {
            var resultArrayArray:Array = new Array();
            // 按照给定的序列倍数扩大确定下来的样式
            var extStyle:String = "";
            while (multiple-- > 0) {
                extStyle += "$1";
            }
            multiple = extStyle.length / 2;
            // 去花色，并在结尾添加一个逗号
            var myCardsString:String = (myCards.join(",") + ",").replace(/\dV/g, "V");
            // 去除特殊数据"X Y"
            myCardsString = myCardsString.replace(/V[XY],/g, "");
            // 将超过指定倍数的每个样式的牌的个数都缩小至指定的倍数
            myCardsString = myCardsString.replace(new RegExp("(V[^,]*,)\\1{" + (multiple - 1) + ",}", "g"), extStyle);
            var matchedCardsArray:Array = myCardsString.match(new RegExp("(V[^,]*,)\\1{" + (multiple - 1) + "}", "g"));
            for each (var eachCardsString:String in matchedCardsArray) {
                eachCardsString = eachCardsString.replace(/,$/, "");
                var eachCardsArray:Array = eachCardsString.split(",");
                resultArrayArray.push(eachCardsArray);
            }
            // 处理大小王与红五
            if (multiple == 2) {
                if (myCards.join(",").indexOf("0VX,0VX") > -1) {
                    // 小王
                    resultArrayArray.push(new Array("0VX", "0VX"));
                }
                if (myCards.join(",").indexOf("0VY,0VY") > -1) {
                    // 大王
                    resultArrayArray.push(new Array("0VY", "0VY"));
                }
            }
            return resultArrayArray;
        }
        
        /**
         * 四连顺、五连顺
         * 对子三连顺、对子四连顺、对子五连顺
         * 三同张三连顺、三同张四连顺、三同张五连顺
         * 四同张三连顺
         * 
         * @param multiple >= 1
         * @param numSeq >= 3
         * @param myCards
         * @param boutCards
         * 
         * @return an array of an array
         * 
         */
        public static function grabSequence(multiple:int, numSeq:int, myCards:Array, boutCards:Array = null):Array {
            var resultArrayArray:Array = new Array();
            var i:int = 0;
            // 1.去花色，并在结尾添加一个逗号
            var myCardsString:String = (myCards.join(",") + ",").replace(/\dV/g, "V");
            // 2.去除无效数据"2 X Y"
            myCardsString = myCardsString.replace(/V[2XY],/g, "");
            // 3.去除重复项
            myCardsString = myCardsString.replace(/(V[^,]*,)\1{1,}/g, "$1");
            if (myCardsString.replace(/,$/, "").split(",").length < numSeq) {
                // 牌值样式的个数比要求的序列个数少
                return resultArrayArray;
            }
            // 确定组合样式
            var testStyleArray:Array = new Array();
            var cardsArr:Array = prioritySequence.replace(/,V[2XY]/g, "").split(",");
			var cards:String = "";
			for (var n:int = 0; n < cardsArr.length; n++) {
				if (numSeq + n > cardsArr.length){
					break;
				}
				for(var j:int = n; j < numSeq + n; j++) {
					cards += cardsArr[j] + ",";
				}
				testStyleArray.push(cards);
				cards="";
			}
            // 按照给定的序列倍数扩大确定下来的样式
            var extStyle:String = "";
            while (multiple-- > 0) {
                extStyle += "$1";
            }
            multiple = extStyle.length / 2;
            for (i = 0; i < testStyleArray.length; i++) {
                var testStyle:String = testStyleArray[i].toString().replace(/(V[^,]*,)/g, extStyle);
                testStyleArray[i] = testStyle;
            }
            // 将已经构造出来的，可能出现的样式，应用到玩家手中的牌中
            // 去花色去无效数据"2 X Y"
            myCardsString = (myCards.join(",") + ",").replace(/\dV/g, "V").replace(/V[2XY],/g, "");
            // 将超过指定倍数的每个样式的牌的个数都缩小至指定的倍数
            myCardsString = myCardsString.replace(new RegExp("(V[^,]*,)\\1{" + (multiple - 1) + ",}", "g"), extStyle);
            for (i = 0; i < testStyleArray.length; i++) {
                if (myCardsString.indexOf(testStyleArray[i]) > -1) {
                } else {
                    // 去除不满足条件
                    testStyleArray[i] = null;
                }
            }
            // 整理数据，将null内容过滤掉
            for each (var eachStyle:String in testStyleArray) {
                if (eachStyle) {
                    resultArrayArray.push(eachStyle.replace(/,$/, "").split(","));
                }
            }
            return resultArrayArray;
        }
        
        /**
         * 三带单，三单对
         * 
         * @param multiple >= 2
         * @param myCards
         * @param boutCards
         * 
         * @return an array of an array
         * 
         */
        public static function grabFollow(multiple:int, myCards:String, boutCards:String = null):Array {
            var resultArrayArray:Array = new Array();

			// 去花色，并在结尾添加一个逗号
            var myCardsStringHold:String = (myCards + ",").replace(/\dV/g, "V");
            // 排除主牌（3，4）找出带牌
            var myCardsString:String = myCardsStringHold.replace(new RegExp("(V[^,]*,)\\1{2,}", "g"), "");
            // 将超过指定倍数的每个样式的牌的个数都缩小至指定的倍数
            var matchedCardsArray:Array = myCardsStringHold.match(new RegExp("(V[^,]*,)\\1{2}", "g"));
			var multiplePair:int = 0;
			var multipleSingle:int = 0;
			var boutCardsString:String = reMakeCardArray(boutCards);
			var key:String = "";
			for (var obj:Object in followCardMap) {
				if (int(followCardMap[obj]) == 3) {
					key += obj + ",";
					multiple += 1;
				} else if (int(followCardMap[obj]) == 2) {
					multiplePair += 1;
				} else if (int(followCardMap[obj]) == 1) {
					multipleSingle += 1;
				} 
			}
			key = key.replace(/,$/,"");
			// 连顺
			if (multiple > 1) {
				var orgKey:String = "";
				for each (var eachCardsString:String in matchedCardsArray) {
	                eachCardsString = eachCardsString.replace(/,$/, "");
	                var eachCardsArray:Array = eachCardsString.split(",");
	                orgKey += eachCardsArray[0].replace(/V[2XY],/g, "") + ","
	            }
				orgKey = orgKey.replace(/,$/,"");
				if (orgKey.length == 0){
					return null;
				}
				// 确定组合样式
	            var testStyleArray:Array = new Array();
	            var cardsArr:Array = prioritySequence.replace(/,V[2XY]/g, "").split(",");
				var cards:String = "";
				for (var n:int = 0; n < cardsArr.length; n++) {
					if (multiple + n > cardsArr.length){
						break;
					}
					for(var j:int = n; j < multiple + n; j++) {
						cards += cardsArr[j] + ",";
					}
					testStyleArray.push(cards);
					cards="";
				}
				// 按照给定的序列倍数扩大确定下来的样式
	            for (var i:int = 0; i < testStyleArray.length; i++) {
	                var testStyle:String = testStyleArray[i].toString().replace(/(V[^,]*,)/g, "$1$1$1");
	                testStyleArray[i] = testStyle;
	            }
	            // 将已经构造出来的，可能出现的样式，应用到玩家手中的牌中
	            // 去花色去无效数据"2 X Y"
	            // 将超过指定倍数的每个样式的牌的个数都缩小至指定的倍数
	            myCardsStringHold = myCardsStringHold.replace(new RegExp("(V[^,]*,)\\1{" + (multiple) + ",}", "g"), "$1$1$1");
	            for (i = 0; i < testStyleArray.length; i++) {
	                if (myCardsStringHold.indexOf(testStyleArray[i]) > -1) {
	                } else {
	                    // 去除不满足条件
	                    testStyleArray[i] = null;
	                }
	            }
	            // 整理数据，将null内容过滤掉
	            for each (var eachStyle:String in testStyleArray) {
	                if (eachStyle) {
	                    resultArrayArray.push(eachStyle.replace(/,$/, "").split(","));
	                }
	            }
				if (resultArrayArray == null || resultArrayArray.length == 0) {
					return null;
				}
				
				var followType:int = 1
				if (multiplePair > 0) {
					// 带对
					followType = 2;
				}
				var followFinalString:String = "";
				while (multiple-- > 0) {
	                var myFollowCards:String = getFollowCards(myCardsString, followType);
	                if (myFollowCards == null) {
	                	return null;
	                }
	                myCardsString = myCardsString.replace(new RegExp(myFollowCards, "g"), "");
	                followFinalString += myFollowCards;
	            }
	            followFinalString = followFinalString.replace(/,$/g, "");
				var followFinalArr:Array = followFinalString.split(",");
				resultArrayArray.push(followFinalArr);
			} else {
				// 非连顺
				var followCards:String = ""
				if (multiplePair > 0) {
					// 带对
					var pairArr:Array = myCardsString.replace(/((V[^,]*,){1,})\\1/g, "$$").split(",");
					if (pairArr != null && pairArr.length >= 2) {
						followCards = pairArr[0] + "," + pairArr[1];
					} else {
						return null;
					}
				}
				if (multipleSingle > 0) {
					// 带单
					var singleArr:Array = myCardsString.replace(/(V[^,]*,)\\1/g, "$").split(",");
					if (singleArr != null && singleArr.length > 0) {
						followCards = singleArr[0];
					} else {
						return null;
					}
				}
	            for each (var eachCardsString:String in matchedCardsArray) {
	                eachCardsString = eachCardsString + followCards;
	                var eachCardsArray:Array = eachCardsString.split(",");
	                resultArrayArray.push(eachCardsArray);
	            }
			}
			
            return resultArrayArray;
        }
        
        public static function getFollowCards(myCardsString:String, type:int):String {
        	var pairArr:Array = null;
        	if (type == 2) {
        		pairArr = myCardsString.match(new RegExp("(V[^,]*,)\\1{1,}", "g"));
        	} else {
        		pairArr = myCardsString.match(new RegExp("V([^,]+)", "g"));
        	}
        	if (pairArr != null && pairArr.length > 0) {
        		if (type == 2) {
        			return pairArr[0];
        		} else {
        			return pairArr[0] + ",";
        		}
        	}
        	return null;
        }
        
        /** 对子 */
        public static const TIPA_MUTIPLE2:int = 101;
        /** 三同张 */
        public static const TIPA_MUTIPLE3:int = 102;
        /** 四同张 */
        public static const TIPA_MUTIPLE4:int = 103;
        
        /** 五连顺 */
        public static const TIPB_SEQ5:int = 201;
        /** 六连顺 */
        public static const TIPB_SEQ6:int = 202;
        /** 七连顺 */
        public static const TIPB_SEQ7:int = 203;
        /** 八连顺 */
        public static const TIPB_SEQ8:int = 204;
        /** 九连顺 */
        public static const TIPB_SEQ9:int = 205;
        /** 十连顺 */
        public static const TIPB_SEQ10:int = 206;
        /** 十一连顺 */
        public static const TIPB_SEQ11:int = 207;
        /** 十二连顺 */
        public static const TIPB_SEQ12:int = 208;
        
        /** 对子三连顺 */
        public static const TIPB_DOUBLE_SEQ3:int = 209;
        /** 对子四连顺 */
        public static const TIPB_DOUBLE_SEQ4:int = 210;
        /** 对子五连顺 */
        public static const TIPB_DOUBLE_SEQ5:int = 211;
        /** 对子六连顺 */
        public static const TIPB_DOUBLE_SEQ6:int = 212;
        /** 对子七连顺 */
        public static const TIPB_DOUBLE_SEQ7:int = 213;
        /** 对子八连顺 */
        public static const TIPB_DOUBLE_SEQ8:int = 214;
        /** 对子九连顺 */
        public static const TIPB_DOUBLE_SEQ9:int = 215;
        /** 对子十连顺 */
        public static const TIPB_DOUBLE_SEQ10:int = 216;
        
        /** 三同张三连顺 */
        public static const TIPC_TRIPLE_SEQ3:int = 301;
        /** 三同张四连顺 */
        public static const TIPC_TRIPLE_SEQ4:int = 302;
        /** 三同张五连顺 */
        public static const TIPC_TRIPLE_SEQ5:int = 303;
        /** 三同张六连顺 */
        public static const TIPC_TRIPLE_SEQ6:int = 304;
        
        /** 四同张三连顺 */
        public static const TIPC_FOURFOLD_SEQ3:int = 305;
        /** 四同张四连顺 */
        public static const TIPC_FOURFOLD_SEQ4:int = 306;
        /** 四同张五连顺 */
        public static const TIPC_FOURFOLD_SEQ5:int = 307;
        
        /** 三(单独)带一*/
        public static const TIPC_THREE_ONE1:int = 306;
        /** 三(二连顺)带二 */
        public static const TIPC_THREE_ONE2:int = 307;
        /** 三(三连顺)带三 */
        public static const TIPC_THREE_ONE3:int = 308;
        /** 三(四连顺)带四 */
        public static const TIPC_THREE_ONE4:int = 309;
        /** 三(五连顺)带五 */
        public static const TIPC_THREE_ONE5:int = 310;
        
        /** 三(单独)带一对*/
        public static const TIPC_THREE_DOUBLE1:int = 311;
        /** 三(二连顺)带二对 */
        public static const TIPC_THREE_DOUBLE2:int = 312;
        /** 三(三连顺)带三对 */
        public static const TIPC_THREE_DOUBLE3:int = 313;
        /** 三(四连顺)带四对 */
        public static const TIPC_THREE_DOUBLE4:int = 314;
        
        
        /** 四(单独)带单二*/
        public static const TIPC_FOUR_ONE1:int = 315;
        /** 四(二连顺)带单四*/
        public static const TIPC_FOUR_ONE2:int = 316;
        /** 四(三连顺)带单六 */
        public static const TIPC_FOUR_ONE3:int = 317;
        
        /** 四(单独)带对*/
        public static const TIPC_FOUR_DOUBLE1:int = 318;
        /** 四(二连顺)带两对*/
        public static const TIPC_FOUR_DOUBLE2:int = 319;
        /** 四(三连顺)带三对*/
        public static const TIPC_FOUR_DOUBLE3:int = 320;
        /**
         * 
         */
        private static const allTipIds:Array = new Array(
        	TIPA_MUTIPLE2, TIPA_MUTIPLE3, TIPA_MUTIPLE4,  
            TIPB_SEQ5, TIPB_SEQ6, TIPB_SEQ7, TIPB_SEQ8, TIPB_SEQ9, TIPB_SEQ10, TIPB_SEQ11, TIPB_SEQ12, 
            TIPB_DOUBLE_SEQ3, TIPB_DOUBLE_SEQ4, TIPB_DOUBLE_SEQ5, TIPB_DOUBLE_SEQ6, TIPB_DOUBLE_SEQ7, TIPB_DOUBLE_SEQ8, TIPB_DOUBLE_SEQ9, TIPB_DOUBLE_SEQ10,  
            TIPC_TRIPLE_SEQ3, TIPC_TRIPLE_SEQ4, TIPC_TRIPLE_SEQ5, TIPC_TRIPLE_SEQ6, 
            TIPC_FOURFOLD_SEQ3, TIPC_FOURFOLD_SEQ4, TIPC_FOURFOLD_SEQ5, 
            TIPC_THREE_ONE1, TIPC_THREE_ONE2, TIPC_THREE_ONE3, TIPC_THREE_ONE4, TIPC_THREE_ONE5,
            TIPC_THREE_DOUBLE1, TIPC_THREE_DOUBLE2, TIPC_THREE_DOUBLE3, TIPC_THREE_DOUBLE4,
            TIPC_FOUR_ONE1, TIPC_FOUR_ONE2, TIPC_FOUR_ONE3,
            TIPC_FOUR_DOUBLE1, TIPC_FOUR_DOUBLE2, TIPC_FOUR_DOUBLE3);

        /**
         * 提示容器
         */
        private static var tipsHolder:Object = new Object();
        
        /**
         * 
         * 将所有的可能的牌型放入提示容器中
         * 
         * @param myCards
         * 
         */
        public static function refreshTips(myCards:String):void {
            var allTips:Object = grabTips(myCards);
            for each (var eachId:int in allTipIds) {
                tipsHolder[eachId] = allTips[eachId];
            }
            //			tipsHolder[TIPA_MUTIPLE2] = {STATUS : -1, TIPS : grabMultiple(2, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE3] = {STATUS : -1, TIPS : grabMultiple(3, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE4] = {STATUS : -1, TIPS : grabMultiple(4, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE5] = {STATUS : -1, TIPS : grabMultiple(5, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE6] = {STATUS : -1, TIPS : grabMultiple(6, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE7] = {STATUS : -1, TIPS : grabMultiple(7, myCards.split(","))};
            //			tipsHolder[TIPA_MUTIPLE8] = {STATUS : -1, TIPS : grabMultiple(8, myCards.split(","))};
            //
            //			tipsHolder[TIPB_SEQ4] = {STATUS : -1, TIPS : grabSequence(1, 4, myCards.split(","))};
            //			tipsHolder[TIPB_SEQ5] = {STATUS : -1, TIPS : grabSequence(1, 5, myCards.split(","))};
            //			tipsHolder[TIPB_DOUBLE_SEQ3] = {STATUS : -1, TIPS : grabSequence(2, 3, myCards.split(","))};
            //			tipsHolder[TIPB_DOUBLE_SEQ4] = {STATUS : -1, TIPS : grabSequence(2, 4, myCards.split(","))};
            //			tipsHolder[TIPB_DOUBLE_SEQ5] = {STATUS : -1, TIPS : grabSequence(2, 5, myCards.split(","))};
            //
            //			tipsHolder[TIPC_TRIPLE_SEQ3] = {STATUS : -1, TIPS : grabSequence(3, 3, myCards.split(","))};
            //			tipsHolder[TIPC_TRIPLE_SEQ4] = {STATUS : -1, TIPS : grabSequence(3, 4, myCards.split(","))};
            //			tipsHolder[TIPC_TRIPLE_SEQ5] = {STATUS : -1, TIPS : grabSequence(3, 5, myCards.split(","))};
            //			tipsHolder[TIPC_FOURFOLD_SEQ3] = {STATUS : -1, TIPS : grabSequence(4, 3, myCards.split(","))};
        }
        
        /**
         * 
         * 从当前玩家手中的牌中组合出所有可能的牌型
         * 
         * @param myCards
         * @return 
         * 
         */
        private static function grabTips(myCards:String):Object {
            var tempTipsHolder:Object = new Object();
            tempTipsHolder[TIPA_MUTIPLE2] = {STATUS : -1, TIPS : grabMultiple(2, myCards.split(","))};
            tempTipsHolder[TIPA_MUTIPLE3] = {STATUS : -1, TIPS : grabMultiple(3, myCards.split(","))};
            tempTipsHolder[TIPA_MUTIPLE4] = {STATUS : -1, TIPS : grabMultiple(4, myCards.split(","))};
            
            tempTipsHolder[TIPB_SEQ5] = {STATUS : -1, TIPS : grabSequence(1, 5, myCards.split(","))};
            tempTipsHolder[TIPB_SEQ6] = {STATUS : -1, TIPS : grabSequence(1, 6, myCards.split(","))};
            tempTipsHolder[TIPB_SEQ7] = {STATUS : -1, TIPS : grabSequence(1, 7, myCards.split(","))};
            tempTipsHolder[TIPB_SEQ8] = {STATUS : -1, TIPS : grabSequence(1, 8, myCards.split(","))};
            tempTipsHolder[TIPB_SEQ9] = {STATUS : -1, TIPS : grabSequence(1, 9, myCards.split(","))};
            tempTipsHolder[TIPB_SEQ10] = {STATUS : -1, TIPS : grabSequence(1, 10, myCards.split(","))};
            tempTipsHolder[TIPB_SEQ11] = {STATUS : -1, TIPS : grabSequence(1, 11, myCards.split(","))};
            tempTipsHolder[TIPB_SEQ12] = {STATUS : -1, TIPS : grabSequence(1, 12, myCards.split(","))};
            
            tempTipsHolder[TIPB_DOUBLE_SEQ3] = {STATUS : -1, TIPS : grabSequence(2, 3, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ4] = {STATUS : -1, TIPS : grabSequence(2, 4, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ5] = {STATUS : -1, TIPS : grabSequence(2, 5, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ6] = {STATUS : -1, TIPS : grabSequence(2, 6, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ7] = {STATUS : -1, TIPS : grabSequence(2, 7, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ8] = {STATUS : -1, TIPS : grabSequence(2, 8, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ9] = {STATUS : -1, TIPS : grabSequence(2, 9, myCards.split(","))};
            tempTipsHolder[TIPB_DOUBLE_SEQ10] = {STATUS : -1, TIPS : grabSequence(2, 10, myCards.split(","))};
            
            tempTipsHolder[TIPC_TRIPLE_SEQ3] = {STATUS : -1, TIPS : grabSequence(3, 3, myCards.split(","))};
            tempTipsHolder[TIPC_TRIPLE_SEQ4] = {STATUS : -1, TIPS : grabSequence(3, 4, myCards.split(","))};
            tempTipsHolder[TIPC_TRIPLE_SEQ5] = {STATUS : -1, TIPS : grabSequence(3, 5, myCards.split(","))};
            tempTipsHolder[TIPC_TRIPLE_SEQ6] = {STATUS : -1, TIPS : grabSequence(3, 6, myCards.split(","))};
            
            tempTipsHolder[TIPC_FOURFOLD_SEQ3] = {STATUS : -1, TIPS : grabSequence(4, 3, myCards.split(","))};
            tempTipsHolder[TIPC_FOURFOLD_SEQ4] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
            tempTipsHolder[TIPC_FOURFOLD_SEQ5] = {STATUS : -1, TIPS : grabSequence(4, 5, myCards.split(","))};
            
//            tempTipsHolder[TIPC_THREE_ONE1] = {STATUS : -1, TIPS : grabSequence(4, 3, myCards.split(","))};
//            tempTipsHolder[TIPC_THREE_ONE2] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_THREE_ONE3] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_THREE_ONE4] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_THREE_ONE5] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            
//            tempTipsHolder[TIPC_THREE_DOUBLE1] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_THREE_DOUBLE2] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_THREE_DOUBLE3] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_THREE_DOUBLE4] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            
//            tempTipsHolder[TIPC_FOUR_ONE1] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_FOUR_ONE2] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_FOUR_ONE3] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            
//            tempTipsHolder[TIPC_FOUR_DOUBLE1] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_FOUR_DOUBLE2] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
//            tempTipsHolder[TIPC_FOUR_DOUBLE3] = {STATUS : -1, TIPS : grabSequence(4, 4, myCards.split(","))};
            return tempTipsHolder;
        }
        
        /**
         * 
         * 按用户的选择来进行循环选择备用牌
         * 
         * @param optrIndex
         * @return 
         * 
         */
        public static function nextTipCards(optrIndex:int):Array {
            var tipHolder:Object = tipsHolder[optrIndex];
            if (tipHolder.TIPS.length == 0) {
                return null;
            }
            tipHolder.STATUS = tipHolder.STATUS + 1;
            if (tipHolder.STATUS == tipHolder.TIPS.length) {
                tipHolder.STATUS = 0;
            }
            return (tipHolder.TIPS as Array)[tipHolder.STATUS].toString().split(",");
        }
        
        /**
         * 
         * 智能提示，不负责牌型校验，只是针对已经打出的合法的牌型，从备选牌中选出合适的对策牌
         * 
         * @return
         * 
         */
        public static function getBrainPowerTip(myCards:Array, boutCards:Array, enableFoolish:Boolean = true):Array {
            var resultArrayArray:Array = new Array();
            var boutCardsString:String = boutCards.join(",");
            var myCardsString:String = myCards.join(",") + ",";
            // 火箭
			if (isRocketStyle(boutCardsString)) {
				return null;
			}
            if (isSingleStyle(boutCardsString)) {
                // 单张判断
                // 去花色和逗号
                boutCardsString = boutCardsString.replace(/^\dV/g, "V");
                myCardsString = myCardsString.replace(/\dV/g, "V");
                // 是否有比打出牌大的牌在手中
                var myLastCard:String = myCardsString.replace(/.*,(\w+),/, "$1");
                // 比较除了红五以外的牌
                if (prioritySequence.indexOf(myLastCard.replace(/\dV/, "V")) <= prioritySequence.indexOf(boutCardsString)) {
                    return null;
                }
                // 单张优先，判断是否有比打出牌大的单张
                // 完全去除重复的项目，不保留任何内容
                var singleCard:String = null;
                var mySingleCardsString:String = myCardsString.replace(/(V[^,]*,)\1{1,}/g, ""); // 只保留单张牌
                mySingleCardsString = mySingleCardsString.replace(/,$/, "");
                for each (singleCard in mySingleCardsString.split(",")) {
                    if (prioritySequence.indexOf(singleCard) > prioritySequence.indexOf(boutCardsString)) {
                        return new Array(singleCard);
                    }
                }
                // 判断是否有比打出牌大的非单张
                var removeSingleCardPattern:RegExp = new RegExp(mySingleCardsString.replace(/,/g, "|"), "g");
                myCardsString = myCardsString.replace(removeSingleCardPattern, "").replace(",{2,}", ",");
                for each (singleCard in myCardsString.replace(/(V[^,]*,)\1{1,}/g, "$1").replace(/,{2,}/g, ",").replace(/,$/, "").split(",")) {
                    if (mySingleCardsString.indexOf(singleCard) > -1) {
                        continue;
                    }
                    if (prioritySequence.indexOf(singleCard) > prioritySequence.indexOf(boutCardsString)) {
                        return new Array(singleCard);
                    }
                }
            } else {
                var allTips:Object = grabTips(myCardsString.replace(/,$/, ""));
                var multiple:int = getMultiple(boutCardsString);
                var multipleId:int = -1;
                var targetTips:Array = null;
                var boutValue:String = null;
                var eachTargetTip:Array = null;
                var tempTargeTip:String = null;
                if (isSeveralFoldStyle(boutCardsString) || isBombStyle(boutCardsString)) {
                    // 成倍且不成顺子
                    multipleId = 99 + multiple;
                    targetTips = allTips[multipleId].TIPS as Array;
                    boutValue = boutCardsString.replace(/^\d|,.*$/g, ""); // 去花色重复项
                    // 是否有比打出牌大的牌在手中
                    if (targetTips.length > 0) {
                        for each (eachTargetTip in targetTips) {
                            tempTargeTip = eachTargetTip.join(",").replace(/^\d|,.*$/g, ""); // 去花色重复项
                            if (prioritySequence.indexOf(tempTargeTip) > prioritySequence.indexOf(boutValue)) {
                                return eachTargetTip;
                            }
                        }
                    }
                } else if (isFollowStyle(boutCardsString)) {
                	// 三带单或三带对
                	targetTips = grabFollow(0, myCardsString, boutCardsString);
					for each (eachTargetTip in targetTips) {
                        var boutFirst:String = boutCardsString.replace(/\dV/, "V").split(",")[0];
                        var targetFirst:String = eachTargetTip[0];
                        if (prioritySequence.indexOf(boutFirst) < prioritySequence.indexOf(targetFirst)) {
                            return eachTargetTip;
                        }
                    }
                } else if (isFourByTwoStyle(boutCardsString)) {
                	// 四带二 四张牌＋任意两套张数相同的牌
                } else {
                    // 顺子，不含五连顺
                    var stlength:int = getStraightLength(boutCardsString);
                    multipleId = -1;
                    if (multiple == 1 && stlength == 5) {
                        // 五连顺 
                        multipleId = TIPB_SEQ5;
                    }
                    if (multiple == 1 && stlength == 6) {
                        // 六连顺 
                        multipleId = TIPB_SEQ6;
                    }
                    if (multiple == 1 && stlength == 7) {
                        // 七连顺 
                        multipleId = TIPB_SEQ7;
                    }
                    if (multiple == 1 && stlength == 8) {
                        // 八连顺 
                        multipleId = TIPB_SEQ8;
                    }
                    if (multiple == 1 && stlength == 9) {
                        // 九连顺 
                        multipleId = TIPB_SEQ9;
                    }
                    if (multiple == 1 && stlength == 10) {
                        // 十连顺 
                        multipleId = TIPB_SEQ10;
                    }
                    if (multiple == 1 && stlength == 11) {
                        // 十一连顺 
                        multipleId = TIPB_SEQ11;
                    }
                    if (multiple == 1 && stlength == 12) {
                        // 十二连顺 
                        multipleId = TIPB_SEQ12;
                    }
                    if (multiple == 2 && stlength == 3) {
                        // 对子三连顺
                        multipleId = TIPB_DOUBLE_SEQ3;
                    }
                    if (multiple == 2 && stlength == 4) {
                        // 对子四连顺
                        multipleId = TIPB_DOUBLE_SEQ4;
                    }
                    if (multiple == 2 && stlength == 5) {
                        // 对子五连顺
                        multipleId = TIPB_DOUBLE_SEQ5;
                    }
                    if (multiple == 2 && stlength == 6) {
                        // 对子六连顺
                        multipleId = TIPB_DOUBLE_SEQ6;
                    }
                    if (multiple == 2 && stlength == 7) {
                        // 对子七连顺
                        multipleId = TIPB_DOUBLE_SEQ7;
                    }
                    if (multiple == 2 && stlength == 8) {
                        // 对子八连顺
                        multipleId = TIPB_DOUBLE_SEQ8;
                    }
                    
                    if (multiple == 3 && stlength == 3) {
                        // 三同张三连顺
                        multipleId = TIPC_TRIPLE_SEQ3;
                    }
                    if (multiple == 3 && stlength == 4) {
                        // 三同张四连顺
                        multipleId = TIPC_TRIPLE_SEQ4;
                    }
                    if (multiple == 3 && stlength == 5) {
                        // 三同张五连顺
                        multipleId = TIPC_TRIPLE_SEQ5;
                    }
                    
                    if (multiple == 4 && stlength == 3) {
                        // 四同张三连顺
                        multipleId = TIPC_FOURFOLD_SEQ3;
                    }
                    if (multiple == 4 && stlength == 4) {
                        // 四同张四连顺
                        multipleId = TIPC_FOURFOLD_SEQ4;
                    }
                    targetTips = allTips[multipleId].TIPS as Array;
                    // 将手中顺子的首位与打出牌的首位比较
                    if (targetTips.length > 0) {
                        for each (eachTargetTip in targetTips) {
                            var boutFirst:String = boutCards[0].replace(/\dV/, "V");
                            var targetFirst:String = eachTargetTip[0];
                            if (prioritySequence.indexOf(boutFirst) < prioritySequence.indexOf(targetFirst)) {
                                return eachTargetTip;
                            }
                        }
                    }
                }
            }
            if (!isBombStyle(boutCardsString)) {
            	// 手中牌型无比相应牌型大的牌时，判断手是中否有炸弹
            	var allTipsTips:Object = grabTips(myCardsString.replace(/,$/, ""));
	            var targetTipsTips:Array = allTipsTips[103].TIPS as Array;
	            // 是否有比打出牌大的牌在手中
	            if (targetTipsTips.length > 0) {
	                for each (eachTargetTip in targetTipsTips) {
	                    tempTargeTip = eachTargetTip.join(",").replace(/^\d|,.*$/g, ""); // 去花色重复项
	                    return eachTargetTip;
	                }
	            }
            }
            if (myCardsString.replace(/,$/, "").indexOf("0VX,0VY") > 0) {
            	// 判断手是中否有火箭
            	return myCardsString.replace(/,$/, "").replace("/.*(0VX,0VY).*/", "$1").match(new RegExp("(0VX)|(0VY)", "g"));
            }
            return null;
        }
	}
}