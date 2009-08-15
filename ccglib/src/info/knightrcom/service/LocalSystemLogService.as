package info.knightrcom.service
{

	public class LocalSystemLogService extends LocalAbstractService
	{

		public static const SYSTEM_INFO:LocalAbstractService=new LocalSystemLogService("SystemLogService");

		public function LocalSystemLogService(service:String, processId:String=null)
		{
			super(service, processId);
		}

	}
}
