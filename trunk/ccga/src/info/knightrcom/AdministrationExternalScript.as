// ActionScript file


import mx.states.State;
import mx.events.ListEvent;
import flash.events.MouseEvent;
import info.knightrcom.UIManager;
import mx.events.ItemClickEvent;
import info.knightrcom.util.ListenerBinder;
import mx.events.FlexEvent;

public function applicationCompleteHandler(event:FlexEvent):void
{
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