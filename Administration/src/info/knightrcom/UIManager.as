package info.knightrcom
{

	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	import info.knightrcom.service.LocalAdminLoginService;
	import info.knightrcom.service.LocalApplicationServerOperationService;
	import info.knightrcom.service.MultiPuppetWindow;
	import info.knightrcom.util.HttpServiceProxy;
	
	import mx.containers.Canvas;
	import mx.controls.Alert;
	import mx.controls.Label;
	import mx.events.CloseEvent;
	import mx.events.ListEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;

	public class UIManager
	{

		public function UIManager()
		{
		}

		public static var adminApp:Administration;
		public static var puppet:MultiPuppetWindow;
		
		[Embed(source="assets/document.png")]
		public static var document_icon:Class;
		
		[Embed(source="assets/home.png")]
		public static var home_icon:Class;

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
					    var entity:* = new XML(event.result).entity;
					    var role:String = entity.role;
					    adminApp.menuTree.dataProvider = adminApp[role + "MenuXML"];
					    if (role == "Administrator") {
					        
					    } else if (role == "GroupUser") {
					        
					    }
					    adminApp.currentProfileId = entity.profileId;
					    adminApp.currentUserId = entity.userId;
					    adminApp.currentRlsPath = entity.rslPath;
					    adminApp.currentRole = entity.role;
						adminApp.currentState="MAIN";
					} else {
						Alert.show("用户登录失败！请检查用户名与密码！", "警告");
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
				case "用户管理":
					adminApp.functionWindowArea.currentState="SOLO_USER_EDIT";
					break;
				case "用户关系浏览":
					adminApp.functionWindowArea.currentState="USER_RELATIONSHIP_VIEW";
					break;
				case "积分充值":
					adminApp.functionWindowArea.currentState="RECHARGE_VIEW";
					break;
				case "启动游戏服务器":
					Alert.yesLabel = "确认";
					Alert.noLabel = "取消";
				    Alert.show( "确定要启动游戏服务器？",
								"消息", 
								Alert.YES | Alert.NO,
								adminApp,
								function handleAlert(event:CloseEvent):void {
								    if(event.detail == Alert.YES)
								    {
										HttpServiceProxy.send(LocalApplicationServerOperationService.START_APPLICATION_SERVER, null, null, function(event:ResultEvent):void
											{
												var result:XML = new XML(event.result);
												if (result.entity == "UPDATE_WARNING") {
													Alert.show("游戏服务器已经是启动状态，该操作被中止！");
												} else {
													Alert.show("游戏服务器启动成功！");
												}
											}, function():void
											{
												Alert.show("游戏服务器启动失败！");
											});
									}
								},
								null,
								Alert.YES);
					break;
				case "关闭游戏服务器":
					Alert.yesLabel = "确认";
					Alert.noLabel = "取消";
				    Alert.show( "确定要关闭游戏服务器？",
								"消息", 
								Alert.YES | Alert.NO,
								adminApp,
								function handleAlert(event:CloseEvent):void {
								    if(event.detail == Alert.YES)
								    {
										HttpServiceProxy.send(LocalApplicationServerOperationService.STOP_APPLICATION_SERVER, null, null, function(event:ResultEvent):void
											{
												var result:XML = new XML(event.result);
												if (result.entity == "UPDATE_WARNING") {
													Alert.show("游戏服务器已经是关闭状态，该操作被中止！");
												} else {
													Alert.show("游戏服务器关闭成功！");
												}
											}, function():void
											{
												Alert.show("游戏服务器关闭失败！");
											});
									}
								},
								null,
								Alert.YES);
					break;
				case "重启游戏服务器":
					Alert.yesLabel = "确认";
					Alert.noLabel = "取消";
				    Alert.show( "确定要重启游戏服务器？",
								"消息", 
								Alert.YES | Alert.NO,
								adminApp,
								function handleAlert(event:CloseEvent):void {
								    if(event.detail == Alert.YES)
								    {
										HttpServiceProxy.send(LocalApplicationServerOperationService.RESTART_APPLICATION_SERVER, null, null, function(event:ResultEvent):void
											{
												Alert.show("游戏服务器重新启动成功！");
											}, function():void
											{
												Alert.show("游戏服务器重新启动失败！");
											});
									}
								},
								null,
								Alert.YES);
					break;
				case "服务器参数":
					adminApp.functionWindowArea.currentState="SERVER_PARAM_EDIT";
					break;
				case "游戏大厅":
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
				case "管理员帮助手册":
					adminApp.functionWindowArea.currentState="ADMIN_MANUAL";
					break;
				case "关于管理平台":
					adminApp.functionWindowArea.currentState="ABOUT_GAME_PLATFORM";
					break;
				case "注销登录":
					Alert.yesLabel = "确认";
					Alert.noLabel = "取消";
				    Alert.show( "确定要注销登录？",
								"消息", 
								Alert.YES | Alert.NO,
								adminApp,
								function handleAlert(event:CloseEvent):void {
								    if(event.detail == Alert.YES)
								    {
								        flash.external.ExternalInterface.call("location.reload", true);
								    }
								    else if(event.detail == Alert.NO)
								    {
										adminApp.functionWindowArea.currentState="WELCOME";
								    }
								},
								null,
								Alert.YES);
					break;
				case "积分结算报表":
					adminApp.functionWindowArea.currentState="REPORT_SCORE_EDIT";
					break;
				case "业务分析报表":
					adminApp.functionWindowArea.currentState="REPORT_BUSINESS_EDIT";
					break;
				case "即时消息发布":
					adminApp.functionWindowArea.currentState="SERVER_MESSAGE_SEND";
					adminApp.functionWindowArea.serverMessageWindow.consoleMessage.text = "";
					adminApp.functionWindowArea.serverMessageWindow.instantMessage.text = "";
					adminApp.functionWindowArea.serverMessageWindow.radioInstantMessage.selected = true;
					break;
				case "平台信息发布":
					adminApp.functionWindowArea.currentState="SERVER_MESSAGE_SEND";
					adminApp.functionWindowArea.serverMessageWindow.consoleMessage.text = "";
					adminApp.functionWindowArea.serverMessageWindow.instantMessage.text = "";
					adminApp.functionWindowArea.serverMessageWindow.radioConsoleMessage.selected = true;
					break;
				case "报表模板管理":
					adminApp.functionWindowArea.currentState="REPORT_TEMPLATE_MANAGE_EDIT";
					break;
				case "动态报表分析器":
					adminApp.functionWindowArea.currentState="DYNA_REPORT";
					break;
				case "服务器状态查看":
					adminApp.functionWindowArea.currentState="SYSTEM_STATUS";
					break;
				case "日志查看":
					adminApp.functionWindowArea.currentState="SYSTEM_LOG";
					break;
				case "不良举报":
					adminApp.functionWindowArea.currentState="GAME_FEEDBACK";
					break;
				case "充值历史报表":
					adminApp.functionWindowArea.currentState="REPORT_RECHARGE_HISTORY";
					break;
				case "业务汇总报表":
					adminApp.functionWindowArea.currentState="REPORT_BIZ_MATRIX";
					break;
				case "自主牌型设置":
					adminApp.functionWindowArea.currentState="CUSTOM_POKER_WINDOW";
					break;
				case "でく・ロボット":
					adminApp.functionWindowArea.currentState="PUPPET_LAUNCHER_WINDOW";
					break;
				case "PUPPET":
					adminApp.functionWindowArea.currentState="MULTI_PUPPET_LAUNCHER_WINDOW";
					break;
				default:
					adminApp.functionWindowArea.currentState="WELCOME";
					Alert.show("该功能正在完善中");
			}
		}
		
		public static function addTab(lbl:String, child:Canvas, contentString:String=null, icon:Class=null):void {
			if(lbl=="") lbl = "(Untitled)";
			
			var curNum:Number = puppet.nav.numChildren + 1;
			
			if (contentString != null && contentString.length > 0) {
				var air:AirLoadSWF = new AirLoadSWF();
				air.addSwf(child, contentString);
			}
			child.setStyle("closable", true);
			child.label = lbl;
			if(icon) {
				child.icon = icon;
			}
			else {
				child.icon = document_icon;
			}
			var label:Label = new Label();
			//label.text = contentString;
			label.setStyle("horizontalCenter", -16); 
			label.setStyle("verticalCenter", 50);
			label.setStyle("fontSize", 24);
			child.addChild(label);
			puppet.nav.addChild(child);
		}
	}
}
