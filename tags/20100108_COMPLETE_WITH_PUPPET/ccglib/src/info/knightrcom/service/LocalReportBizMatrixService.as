package info.knightrcom.service
{

	public class LocalReportBizMatrixService extends LocalAbstractService
	{
		public static const RETRIEVE_REPORT_BIZ_MATRIX:LocalAbstractService=new LocalReportBizMatrixService("ReportBizMatrixService");

		public static const CSV_EXPORT:LocalAbstractService=new LocalReportBizMatrixService("ReportBizMatrixService", "CSV_EXPORT");

		public function LocalReportBizMatrixService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
