package connection
{
	import flash.events.Event;
	
	public class ConnectionEvent extends Event
	{
		public static const ON_RECEIVE_STRING:String = "onReceiveString";
		
		public static const ON_RECEIVE_SPRITE:String = "onReceiveSprite";
		
		public static const ON_RECEIVE_CLIENTPREFERENCES:String = "onReceiveClientPreferences";
		
		public static const ON_RECEIVE_SERVERPREFERENCES:String = "onReceiveServerPreferences";
		
		public static const ON_RECEIVE_MULTIPOINTLINE:String = "onReceiveMultiPointLine";
		
		public static const ON_RECEIVE_FILLREQUEST:String = "onReceiveFillRequest";
		
		public static const ON_RECIEVE_STICKERREQUEST:String = "onReceiveStickerRequest";
		
		public static const ON_RECIEVE_STENCILREQUEST:String = "onReceiveStencilRequest";
		
		public static const ON_RECEIVE_LINEINDEX:String = "onReceiveLineIndex";
		
		public static const ON_RECEIVE_UNDO:String = "onReceiveUndoRequest";
		
		public static const ON_RECEIVE_MAN_REQ:String = "onReceiveManagementRequest";
		
		public var receivedObject:Object = new Object();
		
		public function ConnectionEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false):void
		{
			super(type, bubbles, cancelable);
		}

	}
}