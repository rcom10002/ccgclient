package info.knightrcom.model
{
	public class OperationMethod
	{
		public function OperationMethod(thisMethod:String)
		{
			this.thisMethod = thisMethod;
		}

		private var thisMethod:String;

		public function set method(thisMethod:String):void {
			this.thisMethod = thisMethod;
		}

		public function toString():String {
			return this.thisMethod;
		}

		public static const UNKNOWN:OperationMethod = new OperationMethod("UNKNOWN");

		public static const CREATE:OperationMethod = new OperationMethod("CREATE");
		public static const UPDATE:OperationMethod = new OperationMethod("UPDATE");
		public static const DELETE:OperationMethod = new OperationMethod("DELETE");

	}
}
