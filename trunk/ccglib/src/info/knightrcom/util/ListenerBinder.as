package info.knightrcom.util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getQualifiedClassName;
	
	import info.knightrcom.event.*;
	import info.knightrcom.service.LocalErrorReportService;
	
	import mx.controls.Alert;
	
	public class ListenerBinder
	{
		public function ListenerBinder()
		{
		}

		public static const debug:Boolean = true;

		/**
		 * 特定游戏类型绑定
		 * 
		 * @param target 要进行事件绑定的对象
		 * @param gameType 游戏类型
		 * @param type 事件类型
		 * @param listener 监听函数
		 * @return 
		 * 
		 */
		public static function gameBind(target:EventDispatcher, gameType:uint, type:String, listener:Function):void {
			if (target == null) {
				throw Error("EventDispatcher类型参数target为空！\nError #1009: 无法访问空对象引用的属性或方法。");
			}
			if (target.hasEventListener(type) && debug) {
                Logger.warn("目标对象" + target + "已经含有" + type + "事件句柄");
				// Alert.show("警告：目标对象" + target + "已经含有" + type + "事件句柄");
			}
            Logger.debug("绑定游戏事件：" + gameType + type);
			target.addEventListener(gameType + type, function (event:Event):void {
				try {
					listener(event);
				} catch (e:Error) {
					if (debug) {
						Alert.show(e.getStackTrace(), e.message);
					}
                    HttpServiceProxy.send(LocalErrorReportService.UPLOAD_ERROR_INFORMATION, {NAME : e.name, MESSAGE : e.message, STACK_TRACE : e.getStackTrace()});
				}
			});
		}

		/**
		 * 事件绑定
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
                Logger.warn("目标对象" + target + "已经含有" + type + "事件句柄");
			}
			var gamePrefix:String = "";
			if (target is GameEvent) {
			    gamePrefix = getQualifiedClassName(target);
			}
			target.addEventListener(gamePrefix + type, function (event:Event):void {
				try {
					listener(event);
				} catch (e:Error) {
					if (debug) {
						Alert.show(e.getStackTrace(), e.message);
					}
					HttpServiceProxy.send(LocalErrorReportService.UPLOAD_ERROR_INFORMATION, {NAME : e.name, MESSAGE : e.message, STACK_TRACE : e.getStackTrace()});
				}
			});
		}
// TODO THIS IS A TODO IMPLEMENTATION
//		/**
//		 * 
//		 * @param target 要进行事件绑定的对象
//		 * @param type 事件类型
//		 * @param listener 监听函数
//		 * @return 
//		 * 
//		 */
//		public static function bindOnce(target:EventDispatcher, type:String, listener:Function):void {
//			if (target == null) {
//				throw Error("EventDispatcher类型参数target为空！\nError #1009: 无法访问空对象引用的属性或方法。");
//			}
//			var gamePrefix:String = "";
//			if (target is GameEvent) {
//			    gamePrefix = getQualifiedClassName(target);
//			}
//			target.addEventListener(gamePrefix + type, function (event:Event):void {
//				try {
//					listener(event);
//					EventDispatcher(event.target).removeEventListener(type, listener);
//				} catch (e:Error) {
//					if (debug) {
//						Alert.show(e.getStackTrace(), e.message);
//					}
//				}
//			});
//		}
	}
}