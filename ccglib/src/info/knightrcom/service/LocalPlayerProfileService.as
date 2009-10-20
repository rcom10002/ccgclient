package info.knightrcom.service
{
	public class LocalPlayerProfileService extends LocalAbstractService
	{
		public static const RETRIEVE_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService");
		public static const RETRIEVE_PLAYER_ROLE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "RETRIEVE_PLAYER_ROLE");
		public static const RETRIEVE_PLAYER_RLS_PATH:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "RETRIEVE_PLAYER_RLS_PATH");
		public static const SHOW_RLS_PATH_TREE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "SHOW_RLS_PATH_TREE");
		public static const SHOW_RLS_PATH_CHART:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "SHOW_RLS_PATH_CHART");

		public static const CREATE_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "CREATE_PLAYER_PROFILE");
		public static const READ_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "READ_PLAYER_PROFILE");
		public static const UPDATE_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "UPDATE_PLAYER_PROFILE");
		public static const DELETE_PLAYER_PROFILE:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "DELETE_PLAYER_PROFILE");
		
		public static const READ_PLAYER_PROFILE_BY_USER_ID:LocalAbstractService = new LocalPlayerProfileService("PlayerProfileService", "READ_PLAYER_PROFILE_BY_USER_ID");
		public function LocalPlayerProfileService(serviceId:String, processId:String = null)
		{
			super(serviceId, processId);
		}

	}
}
