package info.knightrcom.service
{
	public class LocalPlayerInfoService extends LocalAbstractService
	{

		public static const SCORE_INFO:LocalAbstractService = new LocalPlayerInfoService("PlayerInfoService");

		public function LocalPlayerInfoService(service:String, processId:String = null)
		{
			super(service, processId);
		}

	}
}
