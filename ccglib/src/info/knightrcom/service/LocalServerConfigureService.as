package info.knightrcom.service
{

	public class LocalServerConfigureService extends LocalAbstractService
	{
		public static const RETRIEVE_SERVER_CONFIGURE:LocalAbstractService=new LocalServerConfigureService("ServerConfigureService");

		/** 服务器参数*/
		public static const CREATE_SERVER_CONFIGURE:LocalAbstractService=new LocalServerConfigureService("ServerConfigureService", "CREATE_SERVER_CONFIGURE");
		public static const READ_SERVER_CONFIGURE:LocalAbstractService=new LocalServerConfigureService("ServerConfigureService", "READ_SERVER_CONFIGURE");
		public static const UPDATE_SERVER_CONFIGURE:LocalAbstractService=new LocalServerConfigureService("ServerConfigureService", "UPDATE_SERVER_CONFIGURE");
		public static const DELETE_SERVER_CONFIGURE:LocalAbstractService=new LocalServerConfigureService("ServerConfigureService", "DELETE_SERVER_CONFIGURE");
		public static const RETRIEVE_SERVER_STATUS:LocalAbstractService=new LocalServerConfigureService("ServerConfigureService", "RETRIEVE_SERVER_STATUS");
		public static const RETRIEVE_LOBBY_STATUS:LocalAbstractService=new LocalServerConfigureService("ServerConfigureService", "RETRIEVE_LOBBY_STATUS");
		

		public function LocalServerConfigureService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
