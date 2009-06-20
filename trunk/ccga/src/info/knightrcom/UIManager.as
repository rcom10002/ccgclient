package info.knightrcom
{
	import info.knightrcom.service.GroupUserWindow;
	
	import mx.controls.Alert;
	import mx.events.ListEvent;
	
	public class UIManager
	{
		public function UIManager()
		{
		}

		public static var adminApp:Administration;

		public static function itemClickHandler(event:ListEvent):void {
            var item:Object = event.currentTarget.selectedItem;
            if (event.target.dataDescriptor.isBranch(item)) {
                event.target.selectedItem = null;
                return;
            }
            var label:String = item.@label;
            switch (label) {
            	case "组用户管理":
            		adminApp.currentState = "GROUP_USER_EDIT";
            		break;
            	case "普通用户管理":
            		adminApp.currentState = "SOLO_USER_EDIT";
            		break;
            	default:
            		adminApp.currentState = "MAIN";
            		Alert.show("该功能正在完善中");
            }
		}
	}
}