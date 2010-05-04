package info.knightrcom {
    import flash.events.DataEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.XMLSocket;
    
    import info.knightrcom.command.GameCommand;
    import info.knightrcom.command.PlatformCommand;
    import info.knightrcom.command.PlayerCommand;
    import info.knightrcom.event.FightLandlordGameEvent;
    import info.knightrcom.event.PlatformEvent;
    import info.knightrcom.event.PlayerEvent;
    import info.knightrcom.event.PushdownWinGameEvent;
    import info.knightrcom.event.QiongWinGameEvent;
    import info.knightrcom.event.Red5GameEvent;
    import info.knightrcom.service.LocalErrorReportService;
    import info.knightrcom.util.HttpServiceProxy;
    import info.knightrcom.util.ListenerBinder;
    import info.knightrcom.util.Logger;
    
    import mx.controls.Alert;
    import mx.utils.Base64Decoder;
    import mx.utils.Base64Encoder;

    /**
     * 
     * Socket包装类
     * 
     */
    public class GameSocketProxy extends EventDispatcher {

        private var port:int = -1;
        private var host:String;
        private var socket:XMLSocket;
        private var _timeout:int = 30 * 1000;
        private var base64Encoder:Base64Encoder;
        private var base64Decoder:Base64Decoder;

        /**
         * 
         * @param host
         * @param port
         * @param testConnection
         * 
         */
        public function GameSocketProxy(host:String, port:uint, testConnection:Boolean = true) {
            try {
                super();
                this.port = port;
                this.host = host;
                socket = new XMLSocket();
                base64Encoder = new Base64Encoder();
                base64Decoder = new Base64Decoder();
                ListenerBinder.bind(socket, Event.CLOSE, closeHandler);
                ListenerBinder.bind(socket, Event.CONNECT, connectHandler);
                ListenerBinder.bind(socket, DataEvent.DATA, dataHandler);
                ListenerBinder.bind(socket, IOErrorEvent.IO_ERROR, ioErrorHandler);
                ListenerBinder.bind(socket, SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
                if (testConnection) {
                    socket.connect(host, port);
                }
            } catch (err:Error) {
                trace(err.message);
            }
        }

        /**
         * 返回超时时间，单位毫秒
         */
        public function get timeout():int {
            return this._timeout;
        }

        /**
         * 设置超时时间
         * 
         * @param value 超时时间，单位毫秒
         */
        public function set timeout(value:int):void {
            this._timeout = value;
        }

        // 通信事件句柄定义开始
        public function closeHandler(event:Event):void {
            dispatchEvent(new PlatformEvent(PlatformEvent.SERVER_DISCONNECTED));
        }

        public function connectHandler(event:Event):void {
            dispatchEvent(new PlatformEvent(PlatformEvent.SERVER_CONNECTED));
        }

        public function dataHandler(event:DataEvent):void {
            event.data = decodeForBase64String(event.data);
            if (event.data == null || event.data.length == 0) {
                return;
            }
            // 解析消息，消息格式：消息编号、消息反馈结果、消息反馈内容
            var results:Array = event.data.split("~");
            var msgType:uint = results.shift();
            var msgNumber:Number = results.shift();
            var msgResult:String = results.shift();
            var msgContent:String = results.join("~");
            if (msgContent != null) {
                if (msgContent.length == 0 || "NULL" == msgContent.toUpperCase()) {
                    msgContent = null;
                }
            }
            if (msgType == PlatformEvent.EVENT_TYPE) {
                dispatchEvent(new PlatformEvent(msgResult, msgContent));
            } else if (msgType == PlayerEvent.EVENT_TYPE) {
                dispatchEvent(new PlayerEvent(msgResult, msgContent));
            } else if (msgType == Red5GameEvent.EVENT_TYPE) {
                dispatchEvent(new Red5GameEvent(msgResult, msgContent));
            } else if (msgType == FightLandlordGameEvent.EVENT_TYPE) {
                dispatchEvent(new FightLandlordGameEvent(msgResult, msgContent));
            } else if (msgType == PushdownWinGameEvent.EVENT_TYPE) {
                dispatchEvent(new PushdownWinGameEvent(msgResult, msgContent));
            } else if (msgType == QiongWinGameEvent.EVENT_TYPE) {
                dispatchEvent(new QiongWinGameEvent(msgResult, msgContent));
            }
        }

        public function ioErrorHandler(event:IOErrorEvent):void {
            dispatchEvent(new PlatformEvent(PlatformEvent.SERVER_IO_ERROR));
        }

        public function securityErrorHandler(event:SecurityErrorEvent):void {
            dispatchEvent(new PlatformEvent(PlatformEvent.SERVER_SECURITY_ERROR));
        }
        // 通信事件句柄定义结束

        /**
         * 发送系统平台数据
         * 
         * @param command
         * @param content
         * 
         */
        public function sendPlatformData(command:PlatformCommand, content:String = null):void {
            var message:Array = [command.type, command.number, command.signature, content];
            sendSocket(message.join("~"));
        }

        /**
         * 发送游戏数据
         * 
         * @param command
         * @param content
         * 
         */
        public function sendGameData(command:GameCommand, content:String = null):void {
            var message:Array = [command.type, command.number, command.signature, content];
            sendSocket(message.join("~"));
        }

        /**
         * 发送玩家数据
         * 
         * @param command
         * @param content
         * 
         */
        public function sendPlayerData(command:PlayerCommand, content:String = null):void {
            var message:Array = [command.type, command.number, command.signature, content];
            sendSocket(message.join("~"));
        }

        /**
         * 
         * 执行连接操作
         * 
         */
        public function connect():void {
            socket.connect(this.host, this.port);
        }

        /**
         * 
         * 断开连接
         * 
         */
        public function disconnect():void {
            socket.close();
        }

        /**
         * 
         * @return 
         * 
         */
        public function get connected():Boolean {
            return socket.connected;
        }

        /**
         * 发送Socket数据
         * 
         * @param data
         * 
         */
        private function sendSocket(data:String):void {
            try {
                socket.send(encodeForBase64String(data));
                Logger.debug("DATA SENT " + data);
            } catch (e:Error) {
				HttpServiceProxy.send(LocalErrorReportService.UPLOAD_ERROR_INFORMATION, {NAME : e.name, MESSAGE : e.message, STACK_TRACE : e.getStackTrace()});
                Alert.show("数据发送失败！与服务器通信受阻，建议重新进入系统！", "错误");
            }
        }

        /**
         * 
         * @param data
         * @return 
         * 
         */
        private function encodeForBase64String(data:String):String {
            base64Encoder.encode(data);
            var encodedData:String = new String(base64Encoder.flush());
            base64Encoder.reset();
            return encodedData;
        }

        /**
         * 
         * @param data
         * @return 
         * 
         */
        private function decodeForBase64String(data:String):String {
            base64Decoder.decode(data);
            var decodedData:String = new String(base64Decoder.flush());
            base64Decoder.reset();
            return decodedData;
        }
    }
}
