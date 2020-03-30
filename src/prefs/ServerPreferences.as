package prefs
{
	import objects.SerializedBitmap;

	public class ServerPreferences extends Object
	{
		public var serverHeight:Number;
		public var serverWidth:Number;
		
		public var aspectRatio:Number;
		
		public var background:SerializedBitmap;
		public var foreground:SerializedBitmap;
		//Supported scale modes are none, stretch, letterbox
		public var bgScaleMode:String = "";
		
		public var stickerArray:Array; //Array of sticker bitmaps, they NEED to be serialized!
		public var stencilArray:Array;
		public var reconstructedStickers:Array = [];
		public var reconstructedStencils:Array = [];
		
		public function ServerPreferences(_height:Number=0, _width:Number=0)
		{
			serverWidth = _width;
			serverHeight = _height;
			aspectRatio = _width/_height;
			
			stickerArray = new Array();
			stencilArray = new Array();
		}
		
		public function reconstructStickers():void
		{
			if(stickerArray.length)
			{
				reconstructedStickers = new Array();
				
				for each (var oSticker:SerializedBitmap in stickerArray)
				{
					reconstructedStickers.push(oSticker.getBitmap());
				}
			}
		}
		
		public function reconstructStencils():void
		{
			if(stencilArray.length)
			{
				reconstructedStencils = new Array();
				
				for each (var oStencil:SerializedBitmap in stencilArray)
				{
					reconstructedStencils.push(oStencil.getBitmap());
				}
			}
		}
	}
}