package info.knightrcom.service
{
	public class LocalPlayerInfoService extends LocalAbstractService
	{

		public static const SCORE_INFO:LocalAbstractService = new LocalPlayerInfoService("PlayerInfoService");
		public static const HISTORY_RECHARGE_INFO:LocalAbstractService = new LocalPlayerInfoService("PlayerInfoService", "HISTORY_RECHARGE_INFO");
		public static const CHANGE_PASSWORD:LocalAbstractService = new LocalPlayerInfoService("PlayerInfoService", "CHANGE_PASSWORD");

		public function LocalPlayerInfoService(service:String, processId:String = null)
		{
			super(service, processId);
		}

	}
}
