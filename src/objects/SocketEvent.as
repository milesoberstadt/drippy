package objects
{
	import flash.events.Event;
	
	public class SocketEvent extends Event
	{
		public static const QUEUE_PROCESSED:String = "queueProcessed";
		
		public function SocketEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}