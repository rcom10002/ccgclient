package info.knightrcom.service
{

	public class LocalReportBusinessService extends LocalAbstractService
	{

		public static const BUSINESS_INFO:LocalAbstractService=new LocalPlayerInfoService("ReportBusinessService");

		public function LocalReportBusinessService(service:String, processId:String=null)
		{
			super(service, processId);
		}

	}
}
