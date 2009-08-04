package info.knightrcom.service
{

	public class LocalServerConfigureService extends LocalAbstractService
	{
		public static const RETRIEVE_SERVER_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("ServerConfigureService");

		/** 服务器参数*/
		public static const CREATE_SERVER_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("ServerConfigureService", "CREATE_SERVER_CONFIGURE");
		public static const READ_SERVER_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("ServerConfigureService", "READ_SERVER_CONFIGURE");
		public static const UPDATE_SERVER_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("ServerConfigureService", "UPDATE_SERVER_CONFIGURE");
		public static const DELETE_SERVER_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("ServerConfigureService", "DELETE_SERVER_CONFIGURE");

		public function LocalServerConfigureService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
