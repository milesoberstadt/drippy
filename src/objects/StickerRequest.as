package objects
{
	public class StickerRequest extends DrawableBase
	{
		public var _x:Number;
		public var _y:Number;
		public var _width:Number;
		public var _height:Number;
		public var _stickerIndex:int;

		public function StickerRequest(x:Number = 0, y:Number = 0, width:Number = 0, height:Number = 0, stickerIndex:int = 0, index:LayerIndex = null)
		{
			_x = x;
			_y = y;
			_width = width;
			_height = height;
			_stickerIndex = stickerIndex;
			layerIndex = index;
		}
	}
}