package {

	import mx.flash.UIMovieClip;
	import flash.text.TextField;

	public dynamic class BaseGameWaiting extends UIMovieClip {

		public function BaseGameWaiting() {
			super();
		}

		public function set tipText(str:String):void {
			txtTip.text = str;
		}
	}
}