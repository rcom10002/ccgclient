package info.knightrcom.service
{

	public class LocalCustomPokerService extends LocalAbstractService
	{
		public static const READ_POKER:LocalAbstractService=new LocalCustomPokerService("CustomPokerService", "READ_POKER");
		
		public static const SAVE_CUSTOM_POKER:LocalAbstractService=new LocalCustomPokerService("CustomPokerService", "SAVE_CUSTOM_POKER");
		
		public static const BATCH_CUSTOM_POKER:LocalAbstractService=new LocalCustomPokerService("CustomPokerService", "BATCH_CUSTOM_POKER");

		public function LocalCustomPokerService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
