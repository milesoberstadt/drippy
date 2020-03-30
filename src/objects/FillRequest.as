package objects
{
	/**
	 * FillRequests are a way of passing a fill command to a different client.
	 * x:Number This is the localized x to the canvas
	 * y:Number This is the localized y to the canvas
	 * color:uint This is the RGB value of the color, alpha value gets added later 
	 **/
	public class FillRequest extends DrawableBase
	{
		public var _x:Number;
		public var _y:Number;
		public var _color:uint;
		
		public function FillRequest(x:Number = 0, y:Number = 0, color:uint = 0x000000, index:LayerIndex = null)
		{
			_x = x;
			_y = y;
			_color = color;
			
			layerIndex = index;
		}
	}
}