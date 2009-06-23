package info.knightrcom.service
{
	public class LocalApplicationServerOperationService extends LocalAbstractService
	{

		public static const START_APPLICATION_SERVER:LocalAbstractService = new LocalApplicationServerOperationService("ApplicationServerOperationService", "START_APPLICATION_SERVER");
		public static const STOP_APPLICATION_SERVER:LocalAbstractService = new LocalApplicationServerOperationService("ApplicationServerOperationService", "STOP_APPLICATION_SERVER");
		public static const RESTART_APPLICATION_SERVER:LocalAbstractService = new LocalApplicationServerOperationService("ApplicationServerOperationService", "RESTART_APPLICATION_SERVER");

		public function LocalApplicationServerOperationService(service:String, processId:String = null)
		{
			super(service, processId);
		}
	}
}
