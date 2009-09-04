package info.knightrcom.state.fightlandlordgame
{
	import component.PokerButton;
	
	import info.knightrcom.util.CardReStrut;

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
				for each(var card:PokerButton in currentBout)   
				{ 
					cardString = card.value.replace(/^[0-4]/, "");
					if (prioritySequence.indexOf(cardString) > prioritySequence.indexOf(previousBout.split(",")[0].replace(/^[0-4]/, "")))
					{
						if (currentCards[cardString] === undefined)
						{
							currentCards[cardString] = 0;
						}
						currentCards[cardString] += 1;
						if (currentCards[cardString] ==  len)
						{
							for each(var card:PokerButton in currentBout)   
							{ 
								if (card.value.toString().replace(/^[0-4]/,"") == cardString && ++tempTimes <= len)
								{
									trace(card.value);
									card.setSelected(true);
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
				return false;
			}
			
			// 顺子
			if (isStraightStyle(previousBout))
			{
				// 去花色
				var resultCards:String=(previousBout + ",").replace(/\b\dV/g, "V");
				var singleCardStr:String="";
				var currentResultCards:String="";
				var currentCompCards:String="";
				var currentCompCardsTimes:int=0;
				// 去重复项目
				resultCards=(resultCards).replace(/(V[^,]+,)\1*/g, "$1");
				// 倍数验证，防止个别牌的倍数与其他牌的倍数不一致
				if ((previousBout + ",").replace(/\b\dV/g, "V").length % resultCards.length == 0)
				{
					// 倍数全相同时，判断是否满足最小序列的条件，比如JQKA单倍时，至少要四张
					// 比如JQK双倍时，至少要三张；比如JQ三倍时，至少要两张
					var multiple:int=(previousBout + ",").replace(/\b\dV/g, "V").length / resultCards.length;
					if (multiple == 1)
					{
						// 单牌顺子
						for each(var card:PokerButton in currentBout)   
						{ 
							if (prioritySequence.indexOf(card.value.replace(/\b\dV/g, "V")) > prioritySequence.indexOf(resultCards.split(",")[0]))
							{
								singleCardStr += card.value + ",";
							}
						}
						for each(var singCard:String in singleCardStr.replace(/,$/,"").split(","))   
						{
							currentResultCards += singCard.replace(/^[0-4]/, "") + ",";
							currentResultCards=(currentResultCards).replace(/(V[^,]+,)\1*/g, "$1");
						}
						if (currentResultCards.length >= resultCards.length)
						{
							var times:int=0;
							var currentyRCArray:Array = currentResultCards.replace(/,$/,"").split(",");
							for (var i:int = 0; i < currentyRCArray.length;)   
							{
								currentCompCards += currentyRCArray[i] + ",";
								if (++times == resultCards.replace(/,$/,"").split(",").length)
								{
									i = ++currentCompCardsTimes;
									times = 0;
									if (prioritySequence.indexOf(currentCompCards) > -1)
									{
										var ptn:RegExp=/^.*V[2XY].*$/;
										if (ptn.test(currentCompCards))
										{
											return false;
										}
										else
										{
											var usedObj:String = "";
											for each(var card:PokerButton in currentBout)   
											{ 
												for each(var selectStr:String in currentCompCards.replace(/,$/, "").split(","))   
												{	
													if (card.value.toString().replace(/^[0-4]/,"") == selectStr)
													{
														if (usedObj != card.value.toString().replace(/^[0-4]/,""))
														{
															usedObj = selectStr;
															card.setSelected(true);
														}
													}
												}
											}
											return true;  
										}
									}
									currentCompCards="";
								}
								else
								{
									i++;
								}
							}
						}
						
					}
					else if (multiple == 2)
					{
						// 双顺
					}
					else if (multiple > 2)
					{
						// 三顺
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
				newCardArray2.push(new CardReStrut(priAf2, map2[priAf2] as int));
			}
			// 重新构造按同号顺序由大到小排序后的字段串
			var reCardArray2:Array=newCardArray2.sort(boutCardSorter);

			var newCardString2:String="";
			for (var i:int=0; i < reCardArray2.length; i++)
			{
				newCardString2+=((CardReStrut)(reCardArray2[i])).getCardName();
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
			var newCardArray:Array=new Array();
			for each (var cardAf:String in cardArray)
			{
				// 去花色
				var priAf:String=cardAf.replace(/\b\dV/g, "V");
				newCardArray.push(new CardReStrut(priAf, map[priAf] as int));
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
				newCardString+=((CardReStrut)(reCardArray[i])).getCardName();
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
		private static function boutCardSorter(card1:CardReStrut, card2:CardReStrut):int
		{
			// 实现排序功能
			// 数量相同时比较牌号大小
			if (card1.getCardCount() == card2.getCardCount())
			{
				if (prioritySequence.indexOf(card1.getCardName()) > prioritySequence.indexOf(card2.getCardName()))
				{
					return 1;
				}
				else if (prioritySequence.indexOf(card1.getCardName()) < prioritySequence.indexOf(card2.getCardName()))
				{
					return -1;
				}
				else
				{
					return 0;
				}
			}
			else if (card1.getCardCount() < card2.getCardCount())
			{
				return 1;
			}
			else if (card1.getCardCount() > card2.getCardCount())
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
		 * @param boutCards
		 * @return
		 *
		 */
		private static function getMultiple(boutCards:String):int
		{
			// 去花色
			var resultCards:String=(boutCards + ",").replace(/\b\dV/g, "V");
			// 去重复项目
			resultCards=(resultCards).replace(/(V[^,]+,)\1*/g, "$1");
			return (boutCards + ",").replace(/\b\dV/g, "V").length / resultCards.length;
		}
	}
}