package info.knightrcom
{

	import flash.events.MouseEvent;

	import info.knightrcom.service.LocalAdminLoginService;
	import info.knightrcom.service.LocalApplicationServerOperationService;
	import info.knightrcom.util.HttpServiceProxy;

	import mx.controls.Alert;
	import mx.events.ListEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;

	public class UIManager
	{

		public function UIManager()
		{
		}

		public static var adminApp:Administration;

		/**
		 *
		 * @param event
		 *
		 */
		public static function btnSubmitClickHandler(event:MouseEvent):void
		{
			HttpServiceProxy.send(LocalAdminLoginService.LOGIN_ADMIN_SERVER, {USERNAME: adminApp.txtUsername.text, PASSWORD: adminApp.txtPassword.text}, null, function(event:ResultEvent):void
				{
					if (new XML(event.result).result == "SUCCESS")
					{
						adminApp.currentState="MAIN";
					}
				}, function(event:FaultEvent):void
				{
					Alert.show("服务器请求失败！");
				});
		}

		/**
		 *
		 * @param event
		 *
		 */
		public static function btnResetClickHandler(event:MouseEvent):void
		{
			adminApp.txtUsername.text="";
			adminApp.txtPassword.text="";
			adminApp.txtUsername.setFocus();
		}

		/**
		 *
		 * @param event
		 *
		 */
		public static function itemClickHandler(event:ListEvent):void
		{
			var item:Object=event.currentTarget.selectedItem;
			if (event.target.dataDescriptor.isBranch(item))
			{
				event.target.selectedItem=null;
				return;
			}
			var label:String=item.@label;
			switch (label)
			{
				case "组用户管理":
					adminApp.functionWindowArea.currentState="GROUP_USER_EDIT";
					break;
				case "普通用户管理":
					adminApp.functionWindowArea.currentState="SOLO_USER_EDIT";
					break;
				case "启动游戏服务器":
					HttpServiceProxy.send(LocalApplicationServerOperationService.START_APPLICATION_SERVER, null, null, function(event:ResultEvent):void
						{
							Alert.show("游戏服务器启动成功！");
						}, function(event:FaultEvent):void
						{
							Alert.show("游戏服务器启动失败！");
						});
					break;
				case "关闭游戏服务器":
					HttpServiceProxy.send(LocalApplicationServerOperationService.STOP_APPLICATION_SERVER, null, null, function():void
						{
							Alert.show("游戏服务器关闭成功！");
						}, function():void
						{
							Alert.show("游戏服务器关闭失败！");
						});
					break;
				case "重新启动游戏服务器":
					HttpServiceProxy.send(LocalApplicationServerOperationService.RESTART_APPLICATION_SERVER, null, null, function():void
						{
							Alert.show("游戏服务器重新启动成功！");
						}, function():void
						{
							Alert.show("游戏服务器重新启动失败！");
						});
					break;
				case "游戏参数":
					adminApp.functionWindowArea.currentState="GAME_PARAM_EDIT";
					break;
				case "大连红五":
					adminApp.functionWindowArea.currentState="GAME_RED5_PARAM_EDIT";
					break;
				case "斗地主":
					adminApp.functionWindowArea.currentState="GAME_FIGHTLANDLORD_PARAM_EDIT";
					break;
				case "穷胡":
					adminApp.functionWindowArea.currentState="GAME_QIONGWIN_PARAM_EDIT";
					break;
				case "推倒胡":
					adminApp.functionWindowArea.currentState="GAME_PUSHDOWNWIN_PARAM_EDIT";
					break;
				default:
					adminApp.currentState="MAIN";
					Alert.show("该功能正在完善中");
			}
		}
	}
}