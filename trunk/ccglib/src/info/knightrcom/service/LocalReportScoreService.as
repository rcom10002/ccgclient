package info.knightrcom.service
{
	public class LocalReportScoreService extends LocalAbstractService
	{
		public static const RETRIEVE_REPORT_SCORE:LocalAbstractService = new LocalReportScoreService("ReportScoreService");

		public function LocalReportScoreService(serviceId:String, processId:String = null)
		{
			super(serviceId, processId);
		}

	}
}
