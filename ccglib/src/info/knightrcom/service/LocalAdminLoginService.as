package info.knightrcom.service
{
	public class LocalAdminLoginService extends LocalAbstractService
	{

		public static const LOGIN_ADMIN_SERVER:LocalAbstractService = new LocalAdminLoginService("AdminLoginService", "LOGIN_ADMIN_SERVER");

		public function LocalAdminLoginService(service:String, processId:String = null)
		{
			super(service, processId);
		}
	}
}
