package components
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.Multitouch;
	
	import mx.core.FlexGlobals;
	import mx.effects.Move;
	import mx.events.CloseEvent;
	import mx.messaging.MultiTopicConsumer;
	
	import objects.DrawingCanvas;
	import objects.SerializedBitmap;
	import objects.SettingsManager;
	import objects.StickerRequest;
	
	import spark.effects.Scale;

	public class StickerPlacer extends Sprite
	{
		[Embed('../assets/sticker/close.png')]
		[Bindable]
		private var CloseButtonImage:Class;
		
		[Embed('../assets/sticker/left.png')]
		[Bindable]
		private var LeftButtonImage:Class;
		
		[Embed('../assets/sticker/right.png')]
		[Bindable]
		private var RightButtonImage:Class;
		
		[Embed('../assets/sticker/move.png')]
		[Bindable]
		private var MoveButtonImage:Class;
		
		[Embed('../assets/sticker/scale.png')]
		[Bindable]
		private var ScaleButtonImage:Class;
		
		private var stickerArray:Array = new Array();
		private var currentStickerIndex:int = 0;
		
		public var sticker:Sprite = new Sprite();
		public var uniformScale:Boolean = true;
		private var closeSprite:Sprite = new Sprite();
		private var leftSprite:Sprite = new Sprite();
		private var rightSprite:Sprite = new Sprite();
		private var moveSprite:Sprite = new Sprite();
		private var scaleSprite:Sprite = new Sprite();
		//We need the application scale a couple times
		private var appScale:Number = FlexGlobals.topLevelApplication.runtimeDPI / FlexGlobals.topLevelApplication.applicationDPI;
		
		private var dragHandleOffset:Point;
		
		private var _canvasHolder:Object;
		
		public function StickerPlacer(canvasHolder:Object)
		{
			_canvasHolder = canvasHolder;
			
			SettingsManager.currentBrushType = "";
			
			sticker.alpha = 0.7;
			addChild(sticker);
			
			closeSprite.addChild(new CloseButtonImage());
			leftSprite.addChild(new LeftButtonImage());
			rightSprite.addChild(new RightButtonImage());
			moveSprite.addChild(new MoveButtonImage());
			scaleSprite.addChild(new ScaleButtonImage());
			
			closeSprite.addEventListener(TouchEvent.TOUCH_BEGIN, closeThis);
			closeSprite.addEventListener(MouseEvent.CLICK, closeThis);
			
			addChild(closeSprite);
			
			moveSprite.addEventListener(TouchEvent.TOUCH_BEGIN, startMovingSticker);
			moveSprite.addEventListener(MouseEvent.MOUSE_DOWN, startMovingSticker);
			addChild(moveSprite);
			
			scaleSprite.addEventListener(TouchEvent.TOUCH_BEGIN, startScalingSticker);
			scaleSprite.addEventListener(MouseEvent.MOUSE_DOWN, startScalingSticker);
			addChild(scaleSprite);
			
			if(_canvasHolder.serverPrefs.reconstructedStickers.length > 1)
			{
				leftSprite.addEventListener(TouchEvent.TOUCH_BEGIN, prevSticker);
				leftSprite.addEventListener(MouseEvent.CLICK, prevSticker);
				addChild(leftSprite);
				
				rightSprite.addEventListener(TouchEvent.TOUCH_BEGIN, nextSticker);
				rightSprite.addEventListener(MouseEvent.CLICK, nextSticker);
				addChild(rightSprite);
			}
			
			sticker.addEventListener(TouchEvent.TOUCH_BEGIN, placeSticker);
			sticker.addEventListener(MouseEvent.CLICK, placeSticker);
			
			if (_canvasHolder.serverPrefs.reconstructedStickers.length)
			{
				stickerArray = _canvasHolder.serverPrefs.reconstructedStickers;
				//Show first sticker
				updateSticker();
			}
				
			else
			{
				//If there's no stickers we should probably self destruct...or something
			}
		}
		
		private function placeSticker(e:Event):void
		{
			var sr:StickerRequest = new StickerRequest((sticker.x + (this.x)), (sticker.y + (this.y)), sticker.width, sticker.height, currentStickerIndex, _canvasHolder.currentLayerAssignment);
			_canvasHolder.canvas.drawSticker(sr);
			_canvasHolder.canvas.myLayerIndexes.push(sr.layerIndex);
			
			_canvasHolder.queueObjectToSend(sr);
		}
		
		private function prevSticker(e:Event):void
		{
			if (--currentStickerIndex < 0)
				currentStickerIndex = stickerArray.length - 1;
			
			updateSticker();
		}
		
		private function nextSticker(e:Event):void
		{
			if (++currentStickerIndex > stickerArray.length - 1)
				currentStickerIndex = 0;
			
			updateSticker();
		}
		
		private function updateSticker():void
		{
			var scalePercent:Number;
			var bmRef:Bitmap = stickerArray[currentStickerIndex];
			
			/*if (FlexGlobals.topLevelApplication.width > FlexGlobals.topLevelApplication.height)
			{
				if (bmRef.width > bmRef.height)
				{
					scalePercent = ((FlexGlobals.topLevelApplication.height * appScale) / bmRef.height)/2;
				}
				else
				{
					
				}
			}
			else
			{
				if (bmRef.height > bmRef.width)
					scalePercent = ((FlexGlobals.topLevelApplication.width * appScale) / Bitmap(stickerArray[currentStickerIndex]).width)/2;
			}*/
			
			var s1:Number = ((FlexGlobals.topLevelApplication.height * appScale) / bmRef.height)/2;
			var s2:Number = ((FlexGlobals.topLevelApplication.width * appScale) / bmRef.width)/2;
			
			scalePercent = Math.min(s1,s2);
			
			while(sticker.numChildren > 0)
				sticker.removeChildAt(0);
			
			
			//Make a new sticker so we don't scale the original
			var currentSticker:Bitmap = new Bitmap(new BitmapData(bmRef.width, bmRef.height, true, 0x000000));
			currentSticker.bitmapData.draw(bmRef);
			bmRef = null;
			currentSticker.smoothing = true;
			currentSticker.scaleX = scalePercent;
			currentSticker.scaleY = scalePercent;
			sticker.addChild(currentSticker);
			
			sticker.x = (sticker.width>sticker.height?sticker.width:sticker.height) * 0.1;
			sticker.y = (sticker.width>sticker.height?sticker.width:sticker.height) * 0.1;
			
			closeSprite.x = 0;
			closeSprite.y = 0;
			moveSprite.x = 0;
			moveSprite.y = sticker.height + (sticker.y);
			scaleSprite.x = sticker.width + (sticker.x);
			scaleSprite.y = sticker.height + (sticker.y);
			
			rightSprite.x = sticker.width + (sticker.x);
			rightSprite.y = 0;
			leftSprite.x = rightSprite.x - (leftSprite.width*2);
			leftSprite.y = 0;
		}
		
		private function startMovingSticker(e:Event):void
		{
			if (e is MouseEvent)
			{
				var me:MouseEvent = MouseEvent(e);
				dragHandleOffset = new Point(me.localX, me.localY);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, updateStickerPos);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopMovingSticker);
			}
			else if (e is TouchEvent)
			{
				var te:TouchEvent = TouchEvent(e);
				dragHandleOffset = new Point(te.localX, te.localY);
				stage.addEventListener(TouchEvent.TOUCH_MOVE, updateStickerPos);
				stage.addEventListener(TouchEvent.TOUCH_END, stopMovingSticker);
			}
		}
		
		private function updateStickerPos(e:Event):void
		{
			if (e is MouseEvent)
			{
				//If we move these before validating the parent container's size will reflect the new size
				if (MouseEvent(e).stageX - _canvasHolder.canvas.x - moveSprite.x - dragHandleOffset.x < _canvasHolder.canvas.width - this.width)
					this.x = MouseEvent(e).stageX - _canvasHolder.canvas.x - moveSprite.x - dragHandleOffset.x;
				else
					this.x = _canvasHolder.canvas.width - this.width;
				
				if (MouseEvent(e).stageY - _canvasHolder.canvas.y - moveSprite.y - dragHandleOffset.y < _canvasHolder.canvas.height - this.height)
					this.y = MouseEvent(e).stageY - _canvasHolder.canvas.y - moveSprite.y - dragHandleOffset.y;
				else
					this.y = _canvasHolder.canvas.height - this.height;				
			}
			else if (e is TouchEvent)
			{
				//If we move these before validating the parent container's size will reflect the new size
				if (TouchEvent(e).stageX - _canvasHolder.canvas.x - moveSprite.x - dragHandleOffset.x < _canvasHolder.canvas.width - this.width)
					this.x = TouchEvent(e).stageX - _canvasHolder.canvas.x - moveSprite.x - dragHandleOffset.x;
				else
					this.x = _canvasHolder.canvas.width - this.width;
				
				if (TouchEvent(e).stageY - _canvasHolder.canvas.y - moveSprite.y - dragHandleOffset.y < _canvasHolder.canvas.height - this.height)
					this.y = TouchEvent(e).stageY - _canvasHolder.canvas.y - moveSprite.y - dragHandleOffset.y;
				else
					this.y = _canvasHolder.canvas.height - this.height;				
			}
			
			//Limit to the edges of the canvas
			this.x = Math.max(this.x, 0);
			this.y = Math.max(this.y, 0);
		}
		
		private function stopMovingSticker(e:Event):void
		{
			if (e is MouseEvent)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateStickerPos);
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopMovingSticker);
			}
			else if (e is TouchEvent)
			{
				stage.removeEventListener(TouchEvent.TOUCH_MOVE, updateStickerPos);
				stage.removeEventListener(TouchEvent.TOUCH_END, stopMovingSticker);
			}
		}
		
		private function startScalingSticker(e:Event):void
		{
			if (e is MouseEvent)
			{
				dragHandleOffset = new Point(MouseEvent(e).localX, MouseEvent(e).localY);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, updateStickerScale);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopScalingSticker);
			}
			else if (e is TouchEvent)
			{
				dragHandleOffset = new Point(TouchEvent(e).localX, TouchEvent(e).localY);
				stage.addEventListener(TouchEvent.TOUCH_MOVE, updateStickerScale);
				stage.addEventListener(TouchEvent.TOUCH_END, stopScalingSticker);
			}
		}
		
		private function updateStickerScale(e:Event):void
		{
			//First we'll deal with where the scale button should be, then we'll figure the rest out
			if (e is MouseEvent)
			{
				if (MouseEvent(e).stageY - this.y - dragHandleOffset.y < _canvasHolder.canvas.height - scaleSprite.height - this.y)
					scaleSprite.y = MouseEvent(e).stageY - this.y - dragHandleOffset.y;
				else 
					scaleSprite.y = _canvasHolder.canvas.height - scaleSprite.height - this.y;
				
				if (MouseEvent(e).stageX - this.x - dragHandleOffset.x < _canvasHolder.canvas.width - scaleSprite.width - this.x)
					scaleSprite.x = MouseEvent(e).stageX - this.x - dragHandleOffset.x;
				else
					scaleSprite.x = _canvasHolder.canvas.width - scaleSprite.width - this.x;
			}
			
			else if (e is TouchEvent)
			{
				if (TouchEvent(e).stageY - this.y - dragHandleOffset.y < _canvasHolder.canvas.height - scaleSprite.height - this.y)
					scaleSprite.y = TouchEvent(e).stageY - this.y - dragHandleOffset.y;
				else 
					scaleSprite.y = _canvasHolder.canvas.height - scaleSprite.height - this.y;
				
				if (TouchEvent(e).stageX - this.x - dragHandleOffset.x < _canvasHolder.canvas.width - scaleSprite.width - this.x)
					scaleSprite.x = TouchEvent(e).stageX - this.x - dragHandleOffset.x;
				else
					scaleSprite.x = _canvasHolder.canvas.width - scaleSprite.width - this.x;
			}
			
			scaleSprite.x = Math.max(scaleSprite.x, (scaleSprite.width * 2) + (sticker.x*2));
			scaleSprite.y = Math.max(scaleSprite.y, (scaleSprite.height * 2) + (sticker.y*2));
			
			//Not as simple as x = y. We need to keep it the same aspect ratio.
			if (uniformScale)
			{
				var ratio:Number = sticker.width / sticker.height;
				//scaleSprite.x = scaleSprite.y * ratio;
				//If new x < canvas edge
				if (scaleSprite.y * ratio < _canvasHolder.canvas.width - scaleSprite.width - this.x)
					scaleSprite.x = scaleSprite.y * ratio;
					
				else
					scaleSprite.y = scaleSprite.x / ratio;
			}
			
			moveSprite.y = scaleSprite.y;
			
			sticker.width = scaleSprite.x * 0.9;
			sticker.height = scaleSprite.y * 0.9;
			
			rightSprite.x = scaleSprite.x + scaleSprite.width - rightSprite.width;
			leftSprite.x = rightSprite.x - (leftSprite.width*2);
		}
		
		private function stopScalingSticker(e:Event):void
		{
			if (e is MouseEvent)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateStickerScale);
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopScalingSticker);
			}
			else if (e is TouchEvent)
			{
				stage.removeEventListener(TouchEvent.TOUCH_MOVE, updateStickerScale);
				stage.removeEventListener(TouchEvent.TOUCH_END, stopScalingSticker);
			}
		}
		
		private function closeThis(e:Event):void
		{
			if (e is MouseEvent)
				closeSprite.removeEventListener(MouseEvent.CLICK, closeThis);
			else if (e is TouchEvent)
				closeSprite.removeEventListener(TouchEvent.TOUCH_END, closeThis);
			SettingsManager.currentBrushType = "normal";
			_canvasHolder.deleteChild(this);
		}
	}
}