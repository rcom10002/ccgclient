package info.knightrcom.service
{

	public class LocalGameConfigureService extends LocalAbstractService
	{
		public static const RETRIEVE_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService");

		public static const CREATE_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "CREATE_GAME_CONFIGURE");
		public static const READ_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "READ_GAME_CONFIGURE");
		public static const UPDATE_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_GAME_CONFIGURE");
		public static const DELETE_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "DELETE_GAME_CONFIGURE");
		/** 游戏读取 */
		public static const READ_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "READ_ROOM_CONFIGURE");
		/** 红五 */
		public static const UPDATE_REDFIVE_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_REDFIVE_ROOM_CONFIGURE");
		/** 斗地主 */
		public static const UPDATE_FIGHT_LANDLORD_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_FIGHT_LANDLORD_ROOM_CONFIGURE");
		/** 推倒 */
		public static const UPDATE_PUSHDOWN_WIN_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_PUSHDOWN_WIN_ROOM_CONFIGURE");
		/** 穷胡 */
		public static const UPDATE_QIONG_WIN_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_QIONG_WIN_ROOM_CONFIGURE");

		public function LocalGameConfigureService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
