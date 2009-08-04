package info.knightrcom.service
{
	public class LocalSystemMessageService extends LocalAbstractService
	{
	    public static const SUBMIT_CHEAT:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "SUBMIT_CHEAT");

		public function LocalSystemMessageService(service:String, processId:String = null)
		{
			super(service, processId);
		}
	}
}