package info.knightrcom.service
{
	public class LocalSystemInfoService extends LocalAbstractService
	{

		public static const COMMIT_GAME_FEEDBACK:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "COMMIT_GAME_FEEDBACK");
		public static const RETRIEVE_FEEDBACK_HISTORY:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "RETRIEVE_FEEDBACK_HISTORY");
		public static const RETRIEVE_GAME_RUNTIME_INFO:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "RETRIEVE_GAME_RUNTIME_INFO");

		public function LocalSystemInfoService(service:String, processId:String = null)
		{
			super(service, processId);
		}
	}
}
