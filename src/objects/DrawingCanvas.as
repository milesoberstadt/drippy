package objects
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.IBitmapDrawable;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BitmapFilterType;
	import flash.filters.GradientGlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.engine.SpaceJustifier;
	import flash.utils.ByteArray;
	
	import mx.core.FlexGlobals;
	
	import spark.primitives.Line;
	import spark.primitives.Rect;
	
	public class DrawingCanvas extends Sprite
	{
		private var lineLayer:Sprite;
		//var lastSmoothedMouseX:Number;
		//var lastSmoothedMouseY:Number;
		//var lastMouseX:Number;
		//var lastMouseY:Number;
		//var lastThickness:Number;
		//var lastRotation:Number;
		private var lineColor:uint;
		private var lineThickness:Number;
		private var lineRotation:Number;
		
		//Smoothing stuff
		/*var L0Sin0:Number;
		var L0Cos0:Number;
		var L1Sin1:Number;
		var L1Cos1:Number;
		var sin0:Number;
		var cos0:Number;
		var sin1:Number;
		var cos1:Number;
		var dx:Number;
		var dy:Number;
		*/
		//var dist:Number;
		private var targetLineThickness:Number;
		//var colorLevel:Number;
		//var targetColorLevel:Number;
		//var smoothedMouseX:Number;
		//var smoothedMouseY:Number;
		private var tipLayer:Sprite;
		
		private var boardBitmap:Bitmap;
		private var boardBitmapData:BitmapData;
		private var bitmapHolder:Sprite;
		private var boardWidth:Number;
		private var boardHeight:Number;
		private var smoothingFactor:Number;
		private var mouseMoved:Boolean;
		
		private var dotRadius:Number;
		private var startX:Number;
		private var startY:Number;
		private var undoStack:Array;
		private var minThickness:Number;
		private var thicknessFactor:Number;
		private var mouseChangeVectorX:Number;
		private var mouseChangeVectorY:Number;
		private var lastMouseChangeVectorX:Number;
		private var lastMouseChangeVectorY:Number;
		
		private var thicknessSmoothingFactor:Number;
		/*
		var controlVecX:Number;
		var controlVecY:Number;
		var controlX1:Number;
		var controlY1:Number;
		var controlX2:Number;
		var controlY2:Number;
		*/
		private var tipTaperFactor:Number;
		
		//private var numUndoLevels:Number;
		
		//private var controlPanel:Sprite;
		
		//var panelColor:uint;
		
		private var boardMask:Sprite;
		
		/**
		 * Contains all drawn objects
		 * */
		public var drawnObjectArray:Array;
		/**
		 * Contains all the objects that the parent of THIS object has drawn
		 * */
		public var myLayerIndexes:Array = [] ;
		
		public var currentLineArray:Array = [];
		
		private var currentStencil:Sprite; //This holds currently scaled stencil, so we can use it to mask
		private var currentStencilDrawings:Array = new Array(); //This holds all the stenciled drawings
		
		/**
		 * Contains stickers gotten from server (we need access when we redraw
		 * */
		public var stickerArray:Array = [];
		
		private var currentLayerIndex:LayerIndex;
		
		public function DrawingCanvas(_width:Number, _height:Number)
		{
			//boardBitmapData = new BitmapData(boardWidth, boardHeight, false);
			//boardBitmap = new Bitmap(boardBitmapData);
			//numUndoLevels = 20;
			drawnObjectArray = new Array();
			
			bitmapHolder = new Sprite();
			
			lineLayer = new Sprite();
			
			boardWidth = _width;
			boardHeight = _height;
			
			boardBitmapData = new BitmapData(boardWidth, boardHeight, true, 0x000000);
			boardBitmap = new Bitmap(boardBitmapData);
			
			this.addChild(bitmapHolder);
			bitmapHolder.addChild(boardBitmap);
		}
		
		/**
		 * If given a bitmapDataTarget, this will copy to that bitmapData instead of the canvas. 
		 * */
		public function fill(x:Number, y:Number, color:uint, bitmapDataTarget:BitmapData=null):void
		{	
			var ucolor:uint = color;
			ucolor += (0xFF<<24); //Add the alpha channel, 0xFF is 1, bitwise shifted by 24. I don't understand this.
			
			var snapshot1:BitmapData = new BitmapData(this.width, this.height, false, 0xFFFFFFFF);
			snapshot1.draw(bitmapHolder, null, null, null, null, true);
			var snapshot2:BitmapData = snapshot1.clone();
			snapshot1.floodFill(x, y, ucolor);
			
			var compareResult:Object = snapshot1.compare(snapshot2);
			if (compareResult)
			{
				var comp:BitmapData = BitmapData(compareResult);
				//trace(comp.rect.x + ", " + comp.rect.y + ", " + comp.rect.width + ", " + comp.rect.height);
				var alphaVal:uint = ucolor >> 24 & 0x000000FF;
				comp.applyFilter(comp, comp.rect, new Point(0,0), new GradientGlowFilter(0, 90, [ucolor, ucolor], [0, alphaVal], [0,255], 
					2, 2, 3, BitmapFilterQuality.HIGH, BitmapFilterType.FULL, true));
				var bmp:BitmapData = new BitmapData(this.width, this.height);
				if (bitmapDataTarget == null)
					boardBitmapData.copyPixels(comp,comp.rect,new Point(0,0), null, null, true);
				else 
					bitmapDataTarget.copyPixels(comp,comp.rect,new Point(0,0), null, null, true);
			}
			//This is a slow, but perfect method.
			//boardBitmapData = BMPFunctions.floodFill(boardBitmapData, x, y, ucolor, 60, true);
			
			//This is really all we need for a basic fill...
			//boardBitmapData.floodFill(x, y, ucolor);
		}
		
		public function draw(graphic:IBitmapDrawable, bScaleObject:Boolean = false):void
		{
			if (bScaleObject && (graphic is Sprite || graphic is Bitmap))
			{
				var bmp:Bitmap = graphic as Bitmap;
				var sprite:Sprite = graphic as Sprite;
				
				var scaleMatrix:Matrix = new Matrix();
				
				if (bmp)
				{
					scaleMatrix.scale(bmp.scaleX, bmp.scaleY);
					boardBitmapData.draw(graphic, scaleMatrix, null, null, null, true);
				}
				else if (sprite)
				{
					scaleMatrix.scale(sprite.scaleX, sprite.scaleY);
					boardBitmapData.draw(graphic, scaleMatrix, null, null, null, true);
				}
				else 
					boardBitmapData.draw(graphic, null, null, null, null, true);
			}
			else
				boardBitmapData.draw(graphic, null, null, null, null, true);
		}
		
		public function drawLine(line:MultiPointLine):void
		{
			var lineAsSprite:Sprite = line.generateSprite();
			var bmd:BitmapData = new BitmapData(boardBitmapData.width, boardBitmapData.height, true, 0x000000);
			bmd.draw(lineAsSprite, null, null, null, null, true);
			
			boardBitmapData.copyPixels(bmd, bmd.rect, new Point(0,0), null, null, true);
			//boardBitmapData.draw(line.generateSprite());
		}
		
		
		/**
		 * If given a bitmapDataTarget, this will copy to that bitmapData instead of the canvas, it will also skip re-adding it to the drawn array  
		 * */
		public function drawSticker(stickerReq:StickerRequest, bitmapDataTarget:BitmapData = null):void
		{
			var sb:Bitmap = stickerArray[stickerReq._stickerIndex];
			//Make a new sticker so we don't scale the original
			var currentSticker:Bitmap = new Bitmap(new BitmapData(sb.width, sb.height, true, 0x000000));
			currentSticker.bitmapData.draw(sb, null, null, null, null, true);
			sb = null;
			currentSticker.smoothing = true;
			
			var scaleMatrix:Matrix = new Matrix;
			scaleMatrix.scale(stickerReq._width/currentSticker.width, stickerReq._height/currentSticker.height);
			scaleMatrix.tx = stickerReq._x;// - this.x;
			scaleMatrix.ty = stickerReq._y;// - this.y;
			//currentSticker.x = stickerReq._x;
			//currentSticker.y = stickerReq._y;
			//currentSticker.width = stickerReq._width;
			//currentSticker.height = stickerReq._height;
			
			if (bitmapDataTarget == null)
			{
				boardBitmapData.draw(currentSticker, scaleMatrix, null, null, null, true);
			
				drawnObjectArray.push(stickerReq);
			}
			else 
				bitmapDataTarget.draw(currentSticker, scaleMatrix, null, null, null, true);
		}
		
		public function saveLineAt(index:int):void
		{
			drawnObjectArray.push(currentLineArray[index]);
			myLayerIndexes.push(currentLineArray[index].layerIndex);
		}
		
		public function startNewStencil(stencil:Sprite, index:LayerIndex, touchID:int = 0):void
		{	
			currentLayerIndex = index;
			
			currentStencil = new Sprite();
			var bmd:BitmapData = new BitmapData(stencil.width, stencil.height, true, 0x00000000);
			
			var scaleMatrix:Matrix = new Matrix;
			scaleMatrix.scale(stencil.scaleX, stencil.scaleY);
			
			bmd.draw(stencil, scaleMatrix, null, null, null, true);

			var bit:Bitmap = new Bitmap(bmd, "auto", true);
			bit.x = stencil.x + stencil.parent.x;
			bit.y = stencil.y + stencil.parent.y;
			
			currentStencilDrawings.push(bit);
			var currentLine:MultiPointLine = new MultiPointLine();
			currentLine.lineColor = SettingsManager.currentLineColor;
			currentLine.lineThickness = SettingsManager.currentBrushSize;
			if (touchID != 0)
				currentLine.touchPointID = touchID;
			currentLineArray.push(currentLine);
		}
		
		public function doStenciling(index:int = -1):StencilRequest
		{
			if (index == -1)
				index = currentLineArray.length-1;
			
			var lineAsSprite:Sprite = currentLineArray[index].generateSprite();
			
			var bmRef:Bitmap =  Bitmap(currentStencilDrawings[currentStencilDrawings.length-1]);
			
			//We have to make a bitmap copy of the stencil so we don't draw outside the lines
			var maskBitmap:Bitmap = new Bitmap(new BitmapData(bmRef.width, bmRef.height, true, 0x00000000), "auto", true);
			maskBitmap.x = bmRef.x;
			maskBitmap.y = bmRef.y;
			lineAsSprite.mask = maskBitmap;
			//Add the stencil mask to the display list after it's assigned as a mask
			bitmapHolder.addChild(currentStencil);
			var newBit:Bitmap = bmRef;
			
			newBit.blendMode = BlendMode.ERASE;
				
			var drawableSprite:Sprite = new Sprite();
			drawableSprite.addChild(lineAsSprite);
			drawableSprite.addChild(newBit);
			drawableSprite.blendMode = BlendMode.LAYER;
			
			//stage.addChild(drawableSprite);
			
			//bmd.draw(lineAsSprite);
			//trace(bmd.rect);
			boardBitmapData.draw(drawableSprite, null, null, null, null, true);
			
			//We need to return a drawn bitmap so we can send it to the server
			var returnBM:Bitmap = new Bitmap(new BitmapData(boardBitmap.width, boardBitmap.height, true, 0x00000000), "auto", true);
			returnBM.bitmapData.draw(drawableSprite, null, null, null, null, true);
			var stencilReq:StencilRequest = new StencilRequest(returnBM, currentLayerIndex);
			myLayerIndexes.push(currentLayerIndex);
			drawnObjectArray.push(stencilReq);
			return stencilReq;
		}
		
		public function redraw():void
		{
			var tempBitmapData:BitmapData = new BitmapData(boardWidth, boardHeight, true, 0x000000);
			
			for (var i:int = 0; i<drawnObjectArray.length; i++)
			{
				if (drawnObjectArray[i] is MultiPointLine)
					tempBitmapData.draw(MultiPointLine(drawnObjectArray[i]).generateSprite(), null, null, null, null, true);
				else if (drawnObjectArray[i] is FillRequest)
				{
					var fr:FillRequest = drawnObjectArray[i] as FillRequest;
					fill(fr._x, fr._y, fr._color, tempBitmapData);
				}
				else if (drawnObjectArray[i] is StencilRequest)
				{
					var sr:StencilRequest = drawnObjectArray[i] as StencilRequest;
					var db:Bitmap = sr.stencilDrawing.getBitmap();
					var scaleMatrix:Matrix = new Matrix();
					scaleMatrix.scale(db.scaleX, db.scaleY);
					tempBitmapData.draw(db, scaleMatrix, null, null, null, true);
				}
				/*else if (drawnObjectArray[i] is Sprite) //Stencils are actually saved as Sprites
				{
					var ds:Sprite = drawnObjectArray[i] as Sprite;
					var scaleMatrix:Matrix = new Matrix();
					scaleMatrix.scale(ds.scaleX, ds.scaleY);
					tempBitmapData.draw(ds, scaleMatrix, null, null, null, true);
				}*/
				else if (drawnObjectArray[i] is StickerRequest)
				{
					
					drawSticker(drawnObjectArray as StickerRequest, tempBitmapData);
				}
				else
					trace("Redraw encountered unhandled type: " + drawnObjectArray[i]);
					
			}
			
			clear();
			boardBitmapData.copyPixels(tempBitmapData,new Rectangle(boardBitmap.x,boardBitmap.y,boardBitmap.width,boardBitmap.height), new Point(0,0), tempBitmapData);
			//boardBitmapData = tempBitmapData;
		}
		
		public function undoLineAt(layerIndex:LayerIndex):void
		{
			for (var i:int = 0; i<drawnObjectArray.length; i++)
			{
				if (drawnObjectArray[i] is DrawableBase)
				{
					if(drawnObjectArray[i].layerIndex._index == layerIndex._index)
					{	
						drawnObjectArray.splice(i,1);
						redraw();
						
						break;
					}
				}
				else
					trace("undoLineAt encountered unhandled type: " + drawnObjectArray[i]);
			}
		}
		
		public function clear():void
		{
			boardBitmapData.fillRect(new Rectangle(0,0,boardBitmap.width,boardBitmap.height), 0xFFFFFF); //= new BitmapData(boardWidth, boardHeight, false);
			drawnObjectArray = [];
			myLayerIndexes = [];
		}
	}
}