package utils
{
	import connection.ConnectionEvent;
	
	import flash.net.Socket;
	
	import objects.DrippyClient;

	public final class ServerUtils extends Object
	{
		public static var clientArray:Array = [];
		
		public static var managementArray:Array = [];
		
		public function ServerUtils()
		{
		}
		
		public static function getClientFromConnection(e:ConnectionEvent):DrippyClient
		{
			for each (var client:DrippyClient in clientArray)
			{
				if (client.CM.clientSocket == Socket(e.currentTarget.clientSocket))
				{
					return client;
				}
			}
			
			return null;
		}
		
		public static function getManagerFromConnection(e:ConnectionEvent):DrippyClient
		{
			for each (var manager:DrippyClient in managementArray)
			{
				if (manager.CM.clientSocket == Socket(e.currentTarget.clientSocket))
				{
					return manager;
				}
			}
			
			return null;
		}
		
		public static function removeClient(e:ConnectionEvent):void
		{
			for (var i:Number=0; i<clientArray.length; i++)
			{
				if (clientArray[i].CM.clientSocket == Socket(e.currentTarget.clientSocket))
					clientArray.splice(i, 1);
			}
		}
		
		public static function moveClientToManager(e:ConnectionEvent):void
		{
			var newManager:DrippyClient = getClientFromConnection(e);
			if (newManager)
			{
				managementArray.push(newManager);
				removeClient(e);
			}
		}
		
		public static function rebroadcastObject(o:Object, originalClientSocket:Socket = null):void
		{
			//If originalClientSocket is null, I assume we should broadcast to ALL clients
			for each (var clientToSend:DrippyClient in clientArray)
			{
				if (originalClientSocket == null || clientToSend.CM.clientSocket != originalClientSocket)
				{
					//Make sure we're connected, otherwise we won't be able to send.
					if (clientToSend.CM.clientSocket.connected == true)
						clientToSend.CM.queueObjectToSend(o);
				}
			}
		}
	}
}