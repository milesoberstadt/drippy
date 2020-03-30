package objects
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;

	public class SerializedBitmap extends Object
	{
		public var bytes:ByteArray = new ByteArray();
		public var width:Number;
		public var height:Number;		
		
		public function SerializedBitmap(bitmap:Bitmap = null)
		{
			super();
			
			if (bitmap!=null)
			{
				setBitmap(bitmap);
			}
		}
		
		public function setBitmap(bitmap:Bitmap):void
		{
			bytes.writeBytes(bitmap.bitmapData.getPixels(bitmap.bitmapData.rect));
			width = bitmap.bitmapData.width;
			height = bitmap.bitmapData.height;
		}
		
		public function getBitmap():Bitmap
		{
			if (bytes!=null)
			{
				var bitmapData:BitmapData = new BitmapData(width, height, true, 0);
				bitmapData.setPixels(bitmapData.rect, bytes);
				var bitmap:Bitmap = new Bitmap(bitmapData);
				return bitmap;
			}
			else
				return null;
		}
		
	}
}