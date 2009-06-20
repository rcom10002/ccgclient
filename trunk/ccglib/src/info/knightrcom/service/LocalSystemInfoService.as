package info.knightrcom.service
{
	public class LocalSystemInfoService extends LocalAbstractService
	{

		public static const SUBMIT_CHEAT:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "SUBMIT_CHEAT");
		public static const FEEDBACK_HISTORY:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "FEEDBACK_HISTORY");
		public static const GAME_RUNTIME_INFO:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "GAME_RUNTIME_INFO");
		public static const GAME_INFO:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "GAME_INFO");

		public function LocalSystemInfoService(service:String, processId:String = null)
		{
			super(service, processId);
		}
	}
}
