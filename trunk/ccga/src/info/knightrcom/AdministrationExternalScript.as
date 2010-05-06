// ActionScript file


import flash.events.MouseEvent;

import info.knightrcom.UIManager;
import info.knightrcom.service.LocalAbstractService;
import info.knightrcom.util.ListenerBinder;
import info.knightrcom.util.Logger;

import mx.events.FlexEvent;
import mx.events.ItemClickEvent;
import mx.events.ListEvent;
import mx.states.State;
import mx.utils.URLUtil;

/**
 * 
 * @param event
 * 
 */
public function applicationCompleteHandler(event:FlexEvent):void
{
    if (!URLUtil.getServerName(Application.application.loaderInfo.url)) {
        LocalAbstractService.RemoteServerURI = "127.0.0.1:8080";
    }
    for each (var currentState:State in this.states)
    {
        trace(currentState.name);
        this.currentState = currentState.name;
    }
    this.currentState = "LOGIN";
    UIManager.adminApp = this;
    ListenerBinder.bind(menuTree, ListEvent.ITEM_CLICK, UIManager.itemClickHandler);
    ListenerBinder.bind(btnSubmit, MouseEvent.CLICK, UIManager.btnSubmitClickHandler);
    ListenerBinder.bind(btnReset, MouseEvent.CLICK, UIManager.btnResetClickHandler);
}

/**
 * 
 * @param obj
 * @param model
 * 
 */
public function log(obj:*, model:String = null):void {
    if (obj && String(obj).length > 0) {
        this.lblLogger.text = Logger.print(obj, model);
    } else {
        this.lblLogger.text = "";
    }
}
