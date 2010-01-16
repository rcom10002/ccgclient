package info.knightrcom.service
{
	public class LocalPuppetConsoleService extends LocalAbstractService
	{
		public static const RETRIEVE_PUPPET_INFO:LocalAbstractService = new LocalPuppetConsoleService("PuppetConsoleService", "RETRIEVE_PUPPET_INFO");
		
		public static const LIST_PUPPET_INFO:LocalAbstractService = new LocalPuppetConsoleService("PuppetConsoleService", "LIST_PUPPET_INFO");

		public function LocalPuppetConsoleService(serviceId:String, processId:String = null)
		{
			super(serviceId, processId);
		}
		
	}
}
