package info.knightrcom.service
{

	public class LocalReportRechargeHistoryService extends LocalAbstractService
	{
		public static const RETRIEVE_REPORT_RECHARGE_HISTORY:LocalAbstractService=new LocalReportRechargeHistoryService("ReportRechargeHistoryService");

		public static const CSV_EXPORT:LocalAbstractService=new LocalReportRechargeHistoryService("ReportRechargeHistoryService", "CSV_EXPORT");

		public function LocalReportRechargeHistoryService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
