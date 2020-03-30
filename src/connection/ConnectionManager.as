package connection
{
	import flash.display.Sprite;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import objects.FillRequest;
	import objects.LayerIndex;
	import objects.ManagementRequest;
	import objects.MultiPointLine;
	import objects.SocketEvent;
	import objects.StencilRequest;
	import objects.StickerRequest;
	import objects.UndoRequest;
	
	import org.osmf.events.TimeEvent;
	
	import prefs.ClientPreferences;
	import prefs.ServerPreferences;

	//Apparently your class needs to extend something like Sprite to be able to dispatch events.
	public class ConnectionManager extends Sprite
	{
		private var _clientSocket:Socket;
		
		private var sendableObjectStack:Array = new Array();
		private var bReadyToSend:Boolean = true;
		
		private var bWaitForACK:Boolean = false;
		
		//This byte array generally holds the current amount of file we've recieved
		private var socketRecievedBA:ByteArray;
		private var msgLength:int = 0;
		
		public function ConnectionManager()
		{
			
		}
		
		public function set clientSocket(socket:Socket):void
		{
			_clientSocket = socket;
			_clientSocket.addEventListener(ProgressEvent.SOCKET_DATA, onClientSocketData);
			_clientSocket.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, outputProgress);
		}
		
		public function get clientSocket():Socket
		{
			return _clientSocket;
		}
		
		private function onClientSocketData(e:ProgressEvent):void
		{
			while (clientSocket.bytesAvailable > 0)
			{
				if (msgLength == 0)
				{
					//A new object appears!
					socketRecievedBA = new ByteArray();
					msgLength = clientSocket.readInt();
					trace("Got a new object with message length of " + msgLength);
				}
				
				var toRead:int = (msgLength > clientSocket.bytesAvailable) ? clientSocket.bytesAvailable : msgLength;
				
				clientSocket.readBytes(socketRecievedBA, socketRecievedBA.length, toRead);
				
				msgLength -= toRead;
				
				if (msgLength > 0)
					break;
				
				else if(msgLength <= 0)
					readObject();
			}
		}
		
		public function readObject():void
		{
			var connectionEvent:ConnectionEvent;
			
			socketRecievedBA.position = 0;
			
			//All objects that get sent through this need ALL CONSTRUCTOR PARAMS to be optional!
			var sentObject:Object = socketRecievedBA.readObject();
			trace("Got object: " + sentObject);
			if (sentObject is ClientPreferences)
			{
				connectionEvent = new ConnectionEvent("onReceiveClientPreferences");
			}
			else if (sentObject is ServerPreferences)
			{
				connectionEvent = new ConnectionEvent("onReceiveServerPreferences");
			}
				
			else if (sentObject is Sprite)
			{
				connectionEvent = new ConnectionEvent("onReceiveSprite");
			}
				
			else if (sentObject is MultiPointLine)
			{
				connectionEvent = new ConnectionEvent("onReceiveMultiPointLine");
			}
				
			else if (sentObject is FillRequest)
			{
				connectionEvent = new ConnectionEvent("onReceiveFillRequest");
			}
				
			else if (sentObject is StickerRequest)
			{
				connectionEvent = new ConnectionEvent("onReceiveStickerRequest");
			}
				
			else if (sentObject is StencilRequest)
			{
				connectionEvent = new ConnectionEvent("onRecieveStencilRequest");
			}
				
			else if (sentObject is LayerIndex)
			{
				connectionEvent = new ConnectionEvent("onReceiveLineIndex");
			}
				
			else if (sentObject is UndoRequest)
			{
				connectionEvent = new ConnectionEvent("onReceiveUndoRequest");
			}
			
			else if (sentObject is ManagementRequest)
			{
				connectionEvent = new ConnectionEvent(ConnectionEvent.ON_RECEIVE_MAN_REQ);
			}
				
			else if (sentObject is String)
			{
				//Currently we don't don't do ACK messages, but if we did, we'd use the following to manage the sending stack...
				//manageString(sentObject as String);
				//return;
				connectionEvent = new ConnectionEvent("onReceiveString");
			}
			
			connectionEvent.receivedObject = sentObject;
			dispatchEvent(connectionEvent);
		}
		
		public function queueObjectToSend(o:Object):void
		{				
			trace("Queueing object: " + o);
			sendableObjectStack.push(o);
			
			//If we're not sending anything currently, we should start
			if (bReadyToSend)
			{
				trace("Since the queue is empty, we're calling processQueue()");
				processQueue();
			}
		}
		
		private function processQueue():void
		{
			trace("Sending sendObject object: " + sendableObjectStack[0]);
			sendObject(sendableObjectStack[0]);
		}
		
		private function sendObject(o:Object):void
		{
			bReadyToSend = false;
			
			var ba:ByteArray = new ByteArray();
			ba.writeObject(o);
			ba.position = 0;
			clientSocket.writeInt(ba.length);
			clientSocket.writeBytes(ba);
			trace("Flushing object: " + o);
			clientSocket.flush();
		}
		
		private function outputProgress(e:OutputProgressEvent):void
		{
			trace((e.bytesTotal-e.bytesPending) + "/" + e.bytesTotal);
			//This could be giving us problems for a couple reasons. It could that we need a delay before sending again, 
			//or we might just need to deal with the time between the sending and the client receiving...
			if (e.bytesPending == 0 && !bWaitForACK && sendableObjectStack.length>0)
			{
				//Since we get here AFTER sending an object, that's when we mark the object as sent by removing it
				trace("Object send complete, removing object " + sendableObjectStack[0]);
				sendableObjectStack.splice(0,1);
				//Then we'll send the next thing...assuming it exists...
				if (sendableObjectStack.length>0)
				{
					trace("outputProgress is continuing the queue");
					processQueue();
				}
				
				else
				{
					trace("outputProgress just finished the last object, bReady=true");
					dispatchEvent(new SocketEvent(SocketEvent.QUEUE_PROCESSED));
					bReadyToSend = true;
				}
			}
			
			else if (e.bytesPending == 0 && sendableObjectStack.length == 0)
			{
				trace("We should probably never get here.");
				bReadyToSend = true;
			}
		}
		
		/*private function manageString(s:String):void
		{
			//TODO: remove check for "ack_object", we don't send it from the host anyway. 
			if (s == "ack_object")
			{
				if (sendableObjectStack.length > 0)
				{
					bReadyToSend = false;
					sendObject(sendableObjectStack[0]);
					sendableObjectStack.splice(0,1);
				}
				else
					bReadyToSend = true;
			}
			//If it's something we're not handling here, dispatch an event.
			else
			{
				var connectionEvent:ConnectionEvent = new ConnectionEvent("onReceiveString");
				connectionEvent.receivedObject = s;
				dispatchEvent(connectionEvent);
			}
		}*/
	}
}