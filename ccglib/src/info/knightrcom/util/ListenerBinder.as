package info.knightrcom.util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.controls.Alert;
	
	public class ListenerBinder
	{
		public function ListenerBinder()
		{
		}

		public static const debug:Boolean = true;

		/**
		 * 
		 * @param target 要进行事件绑定的对象
		 * @param type 事件类型
		 * @param listener 监听函数
		 * @return 
		 * 
		 */
		public static function bind(target:EventDispatcher, type:String, listener:Function):void {
			if (target == null) {
				throw Error("EventDispatcher类型参数target为空！\nError #1009: 无法访问空对象引用的属性或方法。");
			}
			if (target.hasEventListener(type) && debug) {
				trace("警告：目标对象" + target + "已经含有" + type + "事件句柄");
				// Alert.show("警告：目标对象" + target + "已经含有" + type + "事件句柄");
			}
			target.addEventListener(type, function (event:Event):void {
				try {
					listener(event);
				} catch (e:Error) {
					if (debug) {
						Alert.show(e.getStackTrace(), e.message);
					}
				}
			});
		}

		/**
		 * 
		 * @param target 要进行事件绑定的对象
		 * @param type 事件类型
		 * @param listener 监听函数
		 * @return 
		 * 
		 */
		public static function bindOnce(target:EventDispatcher, type:String, listener:Function):void {
			if (target == null) {
				throw Error("EventDispatcher类型参数target为空！\nError #1009: 无法访问空对象引用的属性或方法。");
			}
			target.addEventListener(type, function (event:Event):void {
				try {
					listener(event);
					EventDispatcher(event.target).removeEventListener(type, this);
				} catch (e:Error) {
					if (debug) {
						Alert.show(e.getStackTrace(), e.message);
					}
				}
			});
		}
	}
}