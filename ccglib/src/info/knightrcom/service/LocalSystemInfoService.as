package info.knightrcom.service
{
	public class LocalSystemInfoService extends LocalAbstractService
	{
		public static const LOAD_GAME_RECORD:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "LOAD_GAME_RECORD");

		public static const RETRIEVE_GAME_RUNTIME_INFO:LocalAbstractService = new LocalSystemInfoService("SystemInfoService", "RETRIEVE_GAME_RUNTIME_INFO");

		public function LocalSystemInfoService(service:String, processId:String = null)
		{
			super(service, processId);
		}
	}
}
