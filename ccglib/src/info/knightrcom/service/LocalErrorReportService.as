package info.knightrcom.service
{
	public class LocalErrorReportService extends LocalAbstractService
	{

		public static const UPLOAD_ERROR_INFORMATION:LocalAbstractService = new LocalErrorReportService("ErrorReportService", "UPLOAD_ERROR_INFORMATION");

		public function LocalErrorReportService(service:String, processId:String = null)
		{
			super(service, processId);
		}
	}
}
