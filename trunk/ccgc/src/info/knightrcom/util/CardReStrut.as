package info.knightrcom.util
{

	public class CardReStrut
	{
		private var cardName:String;
		private var cardCount:int;

		public function CardReStrut(_cardName:String, _cardCount:int)
		{
			cardName=_cardName;
			cardCount=_cardCount;
		}

		public function getCardName():String
		{
			return cardName;
		}

		public function getCardCount():int
		{
			return cardCount;
		}

	}
}