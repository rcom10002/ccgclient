package info.knightrcom.service
{
	public class LocalPlayerProfileService extends LocalAbstractService
	{
		public static const RETRIEVE_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService");

		public static const CREATE_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "CREATE_PLAYER_PROFILE");
		public static const READ_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "READ_PLAYER_PROFILE");
		public static const UPDATE_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "UPDATE_PLAYER_PROFILE");
		public static const DELETE_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "DELETE_PLAYER_PROFILE");

		public function LocalPlayerProfileService(serviceId:String, processId:String = null)
		{
			super(serviceId, processId);
		}

	}
}
