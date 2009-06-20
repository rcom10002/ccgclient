package info.knightrcom.service
{
	/**
	 * 
	 * 
	 * 
	 */
	public class LocalAbstractService
	{
		
		private var serviceName:String;
		
		private var processId:String;
		
		private var uri:String;
		
		private static const REMOTE_SERVER_URI:String = "http://localhost:8080/f3s/#.f3s";
		
		/**
		 * 
		 * @param service
		 * @param processId
		 * 
		 */
		public function LocalAbstractService(serviceName:String, processId:String)
		{
			this.serviceName = serviceName;
			this.processId = processId;
		}

		/**
		 * 
		 * @return 
		 * 
		 */
		public function get service():String {
			return serviceName;
		}

		/**
		 * 
		 * @return 
		 * 
		 */
		public function get process():String {
			return processId;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */
		public function get remoteServerURI():String {
			return REMOTE_SERVER_URI.replace(/#/, serviceName);
		}
	}
}