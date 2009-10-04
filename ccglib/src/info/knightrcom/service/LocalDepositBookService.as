package info.knightrcom.service
{

	public class LocalDepositBookService extends LocalAbstractService
	{
		public static const GET_MY_RECHARGE_RECORD:LocalAbstractService=new LocalReportScoreService("DepositBookService", "GET_MY_RECHARGE_RECORD");

		public static const GET_PLAYER_RECHARGE_RECORD:LocalAbstractService=new LocalReportScoreService("DepositBookService", "GET_PLAYER_RECHARGE_RECORD");

		public static const SAVE_RECHARGE_RECORD:LocalAbstractService=new LocalReportScoreService("DepositBookService", "SAVE_RECHARGE_RECORD");

		public function LocalDepositBookService(serviceId:String, processId:String=null)
		{
			super(serviceId, processId);
		}

	}
}
