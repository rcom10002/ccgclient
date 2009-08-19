package info.knightrcom.service
{
	public class LocalDynaReportService extends LocalAbstractService
	{
		public static const READ_DYNA_REPORT:LocalDynaReportService = new LocalDynaReportService("DynaReportService", "READ_DYNA_REPORT");
		
		public static const CSV_EXPORT:LocalDynaReportService = new LocalDynaReportService("DynaReportService", "CSV_EXPORT");
		
		public function LocalDynaReportService(service:String, processId:String = null)
		{
			super(service, processId);
		}

	}
}