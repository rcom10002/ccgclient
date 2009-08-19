package info.knightrcom.service
{

	public class LocalReportScoreService extends LocalAbstractService
	{
		public static const RETRIEVE_REPORT_SCORE:LocalAbstractService=new LocalReportScoreService("ReportScoreService");

		public static const READ_PERIODLY_SUM:LocalAbstractService=new LocalReportScoreService("ReportScoreService", "READ_PERIODLY_SUM");

		public static const CSV_EXPORT:LocalAbstractService=new LocalReportScoreService("ReportScoreService", "CSV_EXPORT");

		public function LocalReportScoreService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
