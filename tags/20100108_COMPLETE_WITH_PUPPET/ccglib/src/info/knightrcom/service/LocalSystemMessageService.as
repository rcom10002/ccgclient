package info.knightrcom.service
{
	public class LocalSystemMessageService extends LocalAbstractService
	{
	    public static const SEND_SYSTEM_MESSAGE:LocalAbstractService = new LocalSystemInfoService("SystemMessageService", "SEND_SYSTEM_MESSAGE");

		public function LocalSystemMessageService(service:String, processId:String = null)
		{
			super(service, processId);
		}
	}
}