package info.knightrcom.service
{

	public class LocalGameFeedbackService extends LocalAbstractService
	{

		public static const RETRIEVE_GAME_FEEDBACK:LocalAbstractService=new LocalGameFeedbackService("GameFeedbackService");

		public static const GET_JOIN_GAME_PLAYER_INFO:LocalAbstractService=new LocalGameFeedbackService("GameFeedbackService", "GET_JOIN_GAME_PLAYER_INFO");
		
		public static const AUDIT_GAME_FEEDBACK:LocalAbstractService=new LocalGameFeedbackService("GameFeedbackService", "AUDIT_GAME_FEEDBACK");
		
		public function LocalGameFeedbackService(service:String, processId:String=null)
		{
			super(service, processId);
		}

	}
}
