package info.knightrcom.service
{

	public class LocalCustomPokerService extends LocalAbstractService
	{
		public static const READ_POKER:LocalAbstractService=new LocalCustomPokerService("CustomPokerService", "READ_POKER");

		public function LocalCustomPokerService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
