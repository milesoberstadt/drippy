package objects
{
	import connection.ConnectionManager;
	
	import flash.geom.Point;
	import flash.net.Socket;
	
	import prefs.ClientPreferences;

	public class DrippyClient extends Object
	{
		public var CM:ConnectionManager = new ConnectionManager();
		public var color:String;
		public var brushType:String;
		
		public var startPoint:Point;
		public var lastPoint:Point;
		
		//private var lineArray:Array;
		
		public var preferences:ClientPreferences;
		
		public function DrippyClient()
		{
			//lineArray = new Array();
		}
		
		/*public function pushLine(line:MultiPointLine):void
		{
			lineArray.push(line);
		}*/
	}
}