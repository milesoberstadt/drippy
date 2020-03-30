package components
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	import mx.core.FlexGlobals;
	import mx.messaging.config.ServerConfig;
	
	import objects.SettingsManager;	
	
	public class ColorPicker extends Sprite
	{
		private var colorArray:Array = new Array(0x000000, 0x861710, 0x944005, 0x644224, 0x949313, 0x2f6e18, 0x0f811e,
				0x08634b, 0x257b7b, 0x105677, 0x14376a, 0x492468, 0x660940, 0x8c4457, 0x1f1f1f, 0xAE2014, 0xc55509, 
				0x825630, 0xc0c11a, 0x3f9121, 0x17ac27, 0x0c8161, 0x33a1a2, 0x17719c, 0x1c478b, 0x623087, 0x880c55, 0xba5b73, 
				0x727272, 0xd6281c, 0xf0690c, 0x9e6c3d, 0xeced20, 0x51b12c, 0x1dd032, 0x119f76, 0x3fc4c6, 0x1e8cc0, 0x2458aa, 
				0x783ea7, 0xa81169, 0xe1718d, 0xa4a4a4, 0xe14d44, 0xf38333, 0xb18962, 0xf0f044, 0x6fc14e, 0x41db52, 0x36b492, 
				0x61d2d2, 0x41a1cc, 0x4974bc, 0x9161ba, 0xb83985, 0xe78fa5, 0xffffff, 0xe77771, 0xf69f63, 0xc5a68c, 0xf5f36b, 
				0x90d278, 0x6ae477, 0x64c7ab, 0x86ddde, 0x6db7d9, 0x7394cd, 0xac87cb, 0xcb66a3, 0xedacbc); 
			
		private var vertCollumns:Number = 14;
		private var collumnPadding:Number = 5;
		private var squareSize:Number = 50;
		
		public var selectedColor:uint;
		
		public var selectionSquare:Sprite = new Sprite();
		
		public function ColorPicker()
		{ 
			for(var i:Number = 0; i<colorArray.length; i++)
			{
				var square:Sprite = new Sprite();
				square.graphics.beginFill((colorArray[i]), 1);
				square.graphics.drawRect(0,0,squareSize,squareSize);
				square.graphics.endFill();

				square.x = (i%vertCollumns * squareSize) + (i%vertCollumns * collumnPadding);
				square.y = (Math.floor(i/vertCollumns) * squareSize) + (Math.floor(i/vertCollumns) * collumnPadding);
				
				square.addEventListener(MouseEvent.CLICK, sendColor);
				addChild(square);
			}
			
			selectColor(SettingsManager.currentLineColor);
		}
		
		private function sendColor(e:MouseEvent):void
		{
			//trace(colorArray.indexOf(e.target));
			var squareBMD:BitmapData = new BitmapData(e.target.width, e.target.height);
			squareBMD.draw(Sprite(e.target));
			//trace(squareBMD.getPixel(0,0));
			selectColor(squareBMD.getPixel(0,0));
		}
		
		private function selectColor(color:uint):void
		{
			//Remove the child 
			if (this.contains(selectionSquare))
				removeChild(selectionSquare);
			
			selectionSquare = new Sprite();
			selectionSquare.graphics.beginFill(0xFFFFFF, 1);
			selectionSquare.graphics.drawRect(0,0,(squareSize + (collumnPadding*2)),(squareSize + (collumnPadding*2)));
			selectionSquare.graphics.endFill();
			
			var selectionNumber:Number = colorArray.indexOf(color);
			selectionSquare.x = (selectionNumber % vertCollumns * squareSize) + (selectionNumber % vertCollumns * collumnPadding) - collumnPadding;
			selectionSquare.y = (Math.floor(selectionNumber/vertCollumns) * squareSize) + (Math.floor(selectionNumber/vertCollumns) * collumnPadding) - collumnPadding;
			
			addChildAt(selectionSquare, 0);
			
			//var vn:ViewNavigator = new ViewNavigator();
			SettingsManager.currentLineColor = color;
			//trace(vn.activeView);
		}
	}
}