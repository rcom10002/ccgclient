package info.knightrcom.service
{

	public class LocalReportTemplateManageService extends LocalAbstractService
	{
		public static const RETRIEVE_SQL_TEMPLATE:LocalAbstractService=new LocalGameConfigureService("ReportTemplateManageService");

		/** 报表模板管理*/
		public static const CREATE_SQL_TEMPLATE:LocalAbstractService=new LocalGameConfigureService("ReportTemplateManageService", "CREATE_SQL_TEMPLATE");
		public static const READ_SQL_TEMPLATE:LocalAbstractService=new LocalGameConfigureService("ReportTemplateManageService", "READ_SQL_TEMPLATE");
		public static const UPDATE_SQL_TEMPLATE:LocalAbstractService=new LocalGameConfigureService("ReportTemplateManageService", "UPDATE_SQL_TEMPLATE");
		public static const DELETE_SQL_TEMPLATE:LocalAbstractService=new LocalGameConfigureService("ReportTemplateManageService", "DELETE_SQL_TEMPLATE");

		public function LocalReportTemplateManageService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
