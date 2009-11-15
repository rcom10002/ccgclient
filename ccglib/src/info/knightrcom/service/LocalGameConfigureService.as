package info.knightrcom.service
{

	public class LocalGameConfigureService extends LocalAbstractService
	{
		public static const RETRIEVE_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService");

		/** 游戏大厅*/
		public static const CREATE_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "CREATE_GAME_CONFIGURE");
		public static const READ_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "READ_GAME_CONFIGURE");
		public static const UPDATE_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_GAME_CONFIGURE");
		public static const DELETE_GAME_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "DELETE_GAME_CONFIGURE");
		/** 游戏房间读取 */
		public static const READ_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "READ_ROOM_CONFIGURE");
		/** 红五 */
		public static const UPDATE_RED5_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_RED5_ROOM_CONFIGURE");
		public static const CREATE_RED5_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "CREATE_RED5_ROOM_CONFIGURE");
		public static const DELETE_RED5_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "DELETE_RED5_ROOM_CONFIGURE");
		/** 斗地主 */
		public static const UPDATE_FIGHT_LANDLORD_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_FIGHT_LANDLORD_ROOM_CONFIGURE");
		public static const CREATE_FIGHT_LANDLORD_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "CREATE_FIGHT_LANDLORD_ROOM_CONFIGURE");
		public static const DELETE_FIGHT_LANDLORD_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "DELETE_FIGHT_LANDLORD_ROOM_CONFIGURE");
		/** 推倒 */
		public static const UPDATE_PUSHDOWN_WIN_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_PUSHDOWN_WIN_ROOM_CONFIGURE");
		public static const CREATE_PUSHDOWN_WIN_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "CREATE_PUSHDOWN_WIN_ROOM_CONFIGURE");
		public static const DELETE_PUSHDOWN_WIN_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "DELETE_PUSHDOWN_WIN_ROOM_CONFIGURE");
		/** 穷胡 */
		public static const UPDATE_QIONG_WIN_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "UPDATE_QIONG_WIN_ROOM_CONFIGURE");
		public static const CREATE_QIONG_WIN_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "CREATE_QIONG_WIN_ROOM_CONFIGURE");
		public static const DELETE_QIONG_WIN_ROOM_CONFIGURE:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "DELETE_QIONG_WIN_ROOM_CONFIGURE");
		/** 检查服务器是否关闭 */
		public static const IS_SERVER_CLOSE_STATUS:LocalAbstractService=new LocalGameConfigureService("GameConfigureService", "IS_SERVER_CLOSE_STATUS");
		
		public function LocalGameConfigureService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
