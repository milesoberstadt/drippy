package prefs
{
	public class ClientPreferences extends Object
	{
		public var clientHeight:Number;
		public var clientWidth:Number;
		
		public var clientScale:Number;
		
		public var aspectRatio:Number;
		
		public var boxingOrientation:String;
		public var boxingAmount:Number;
		
		public function ClientPreferences(_width:Number=0, _height:Number=0)
		{
			clientWidth = _width;
			clientHeight = _height;
			aspectRatio = _width/_height;
		}
	}
}