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
	
	import mx.core.FlexGlobals;
	import mx.effects.Move;
	import mx.events.CloseEvent;
	
	import objects.MultiPointLine;
	import objects.SerializedBitmap;
	import objects.SettingsManager;
	import objects.StencilRequest;
	
	import spark.effects.Scale;
	
	public class StencilPlacer extends Sprite
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
		
		private var stencilArray:Array = new Array();
		private var currentStencilIndex:int = 0;
		
		public var stencil:Sprite = new Sprite();
		public var uniformScale:Boolean = false;
		private var closeSprite:Sprite = new Sprite();
		private var leftSprite:Sprite = new Sprite();
		private var rightSprite:Sprite = new Sprite();
		private var moveSprite:Sprite = new Sprite();
		private var scaleSprite:Sprite = new Sprite();
		
		private var ratio:Number;
		//We need the application scale a couple times
		private var appScale:Number = FlexGlobals.topLevelApplication.runtimeDPI / FlexGlobals.topLevelApplication.applicationDPI;
		
		private var dragHandleOffset:Point;
		
		private var _canvasHolder:Object;
		
		private var bMouseEnabled:Boolean = false;
		
		public function StencilPlacer(canvasHolder:Object)
		{
			_canvasHolder = canvasHolder;
			SettingsManager.currentBrushType = "";
			
			addChild(stencil);
			
			closeSprite.addChild(new CloseButtonImage());
			leftSprite.addChild(new LeftButtonImage());
			rightSprite.addChild(new RightButtonImage());
			moveSprite.addChild(new MoveButtonImage());
			scaleSprite.addChild(new ScaleButtonImage());
			
			closeSprite.addEventListener(TouchEvent.TOUCH_END, closeThis);
			closeSprite.addEventListener(MouseEvent.CLICK, closeThis);
			addChild(closeSprite);
			
			moveSprite.addEventListener(TouchEvent.TOUCH_BEGIN, startMovingStencil);
			moveSprite.addEventListener(MouseEvent.MOUSE_DOWN, startMovingStencil);
			addChild(moveSprite);
			
			scaleSprite.addEventListener(TouchEvent.TOUCH_BEGIN, startScalingStencil);
			scaleSprite.addEventListener(MouseEvent.MOUSE_DOWN, startScalingStencil);
			addChild(scaleSprite);
			
			if(_canvasHolder.serverPrefs.reconstructedStencils.length > 1)
			{
				leftSprite.addEventListener(TouchEvent.TOUCH_BEGIN, prevStencil);
				leftSprite.addEventListener(MouseEvent.CLICK, prevStencil);
				addChild(leftSprite);
				
				rightSprite.addEventListener(TouchEvent.TOUCH_BEGIN, nextStencil);
				rightSprite.addEventListener(MouseEvent.CLICK, nextStencil);
				addChild(rightSprite);
			}
			
			stencil.addEventListener(TouchEvent.TOUCH_BEGIN, placeStencil);
			if (bMouseEnabled)
				stencil.addEventListener(MouseEvent.MOUSE_DOWN, placeStencil);
			
			if (_canvasHolder.serverPrefs.reconstructedStencils.length)
			{
				stencilArray = _canvasHolder.serverPrefs.reconstructedStencils;
				//Show first stencil
				updateStencil();
			}
				
			else
			{
				//If there's no stencils we should probably self destruct...or something
			}
		}
		
		private function placeStencil(e:Event):void
		{
			if (e is MouseEvent)
			{
				trace("Starting new stencil with mouse");
				_canvasHolder.canvas.startNewStencil(stencil, _canvasHolder.currentLayerAssignment);
				stencil.addEventListener(MouseEvent.MOUSE_MOVE, drawOnStencil);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopStencil);
			}
			
			else if (e is TouchEvent)
			{
				trace("Starting new stencil with touch");
				_canvasHolder.canvas.startNewStencil(stencil, _canvasHolder.currentLayerAssignment, TouchEvent(e).touchPointID);
				stencil.addEventListener(TouchEvent.TOUCH_MOVE, drawOnStencil);
				stage.addEventListener(TouchEvent.TOUCH_END, stopStencil);
			}
		}
		
		private function stopStencil(e:Event):void
		{
			if (e is MouseEvent)
			{
				stencil.removeEventListener(MouseEvent.MOUSE_MOVE, drawOnStencil);
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopStencil);
				
				_canvasHolder.canvas.currentLineArray.splice(0,1);
			}
			else if (e is TouchEvent)
			{
				stencil.removeEventListener(TouchEvent.TOUCH_MOVE, drawOnStencil);
				stage.removeEventListener(TouchEvent.TOUCH_END, stopStencil);
				
				for each(var m:MultiPointLine in _canvasHolder.canvas.currentLineArray)
				{
					if (m.touchPointID == TouchEvent(e).touchPointID)
					{
						var i:int = _canvasHolder.canvas.currentLineArray.indexOf(m);
						_canvasHolder.canvas.currentLineArray.splice(i,1);
						break;
					}
				}
			}
		}
		
		private function drawOnStencil(e:Event):void
		{
			var pointToSend:Point;
			var stencilReq:StencilRequest;
			//Apparently local coordinates aren't attunded to scale
			if (e is MouseEvent)
			{
				pointToSend = new Point(this.x + stencil.x + (MouseEvent(e).localX*stencil.scaleX), this.y + stencil.y + (MouseEvent(e).localY*stencil.scaleY));
				_canvasHolder.canvas.currentLineArray[0].push(pointToSend);
				
				if (_canvasHolder.canvas.currentLineArray[0].pointArray.length > 1)
				{
					stencilReq = _canvasHolder.canvas.doStenciling();
					_canvasHolder.queueObjectToSend(stencilReq);
				}
			}
			else if (e is TouchEvent)
			{
				pointToSend = new Point(this.x + stencil.x + (TouchEvent(e).localX*stencil.scaleX), this.y + stencil.y + (TouchEvent(e).localY*stencil.scaleY));
				var index:int = -1;
				for each(var m:MultiPointLine in _canvasHolder.canvas.currentLineArray)
				{
					if (m.touchPointID == TouchEvent(e).touchPointID)
					{
						index = _canvasHolder.canvas.currentLineArray.indexOf(m);
						break;
					}
				}
				
				if (index != -1)
				{
					_canvasHolder.canvas.currentLineArray[index].push(pointToSend);
					
					if (_canvasHolder.canvas.currentLineArray[index].pointArray.length > 1)
					{
						stencilReq = _canvasHolder.canvas.doStenciling(index);
						_canvasHolder.queueObjectToSend(stencilReq);
					}
				}
				else
					trace("Line not found");
			}
		}
		
		private function prevStencil(e:Event):void
		{
			if (--currentStencilIndex < 0)
				currentStencilIndex = stencilArray.length - 1;
			
			updateStencil();
		}
		
		private function nextStencil(e:Event):void
		{
			if (++currentStencilIndex > stencilArray.length - 1)
				currentStencilIndex = 0;
			
			updateStencil();
		}
		
		private function updateStencil():void
		{
			var scalePercent:Number;
			var bmRef:Bitmap = stencilArray[currentStencilIndex];
			
			var s1:Number = ((FlexGlobals.topLevelApplication.height * appScale) / bmRef.height)/2;
			var s2:Number = ((FlexGlobals.topLevelApplication.width * appScale) / bmRef.width)/2;
			
			scalePercent = Math.min(s1,s2);
			
			while(stencil.numChildren > 0)
				stencil.removeChildAt(0);
			
			
			//Make a new stencil so we don't scale the original
			var currentStencil:Bitmap = new Bitmap(new BitmapData(bmRef.width, bmRef.height, true, 0x000000));
			currentStencil.bitmapData.draw(bmRef);
			bmRef = null;
			currentStencil.smoothing = true;
			currentStencil.scaleX = scalePercent;
			currentStencil.scaleY = scalePercent;
			stencil.addChild(currentStencil);
			
			stencil.x = (stencil.width>stencil.height?stencil.width:stencil.height) * 0.1;
			stencil.y = (stencil.width>stencil.height?stencil.width:stencil.height) * 0.1;
			
			closeSprite.x = 0;
			closeSprite.y = 0;
			moveSprite.x = 0;
			moveSprite.y = stencil.height + (stencil.y * 2) - moveSprite.height;
			scaleSprite.x = stencil.width + (stencil.x * 2) - scaleSprite.width;
			scaleSprite.y = stencil.height + (stencil.y * 2) - scaleSprite.height;
			
			rightSprite.x = stencil.width + (stencil.x);
			rightSprite.y = 0;
			leftSprite.x = rightSprite.x - (leftSprite.width*2);
			leftSprite.y = 0;
			
			ratio = stencil.width / stencil.height;
		}
		
		private function startMovingStencil(e:Event):void
		{
			if (e is MouseEvent)
			{
				dragHandleOffset = new Point(MouseEvent(e).localX, MouseEvent(e).localY);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, updateStencilPos);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopMovingStencil);
			}
			else if (e is TouchEvent)
			{
				dragHandleOffset = new Point(TouchEvent(e).localX, TouchEvent(e).localY);
				stage.addEventListener(TouchEvent.TOUCH_MOVE, updateStencilPos);
				stage.addEventListener(TouchEvent.TOUCH_END, stopMovingStencil);
			}
		}
		
		private function updateStencilPos(e:Event):void
		{
			//If we move these before validating the parent container's size will reflect the new size
			if (e is MouseEvent)
			{
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
		
		private function stopMovingStencil(e:Event):void
		{
			if (e is MouseEvent)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateStencilPos);
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopMovingStencil);
			}
			
			else if (e is TouchEvent)
			{
				stage.removeEventListener(TouchEvent.TOUCH_MOVE, updateStencilPos);
				stage.removeEventListener(TouchEvent.TOUCH_END, stopMovingStencil);
			}
		}
		
		private function startScalingStencil(e:Event):void
		{
			if (e is MouseEvent)
			{
				dragHandleOffset = new Point(MouseEvent(e).localX, MouseEvent(e).localY);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, updateStencilScale);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopScalingStencil);
			}
				
			else if (e is TouchEvent)
			{
				dragHandleOffset = new Point(TouchEvent(e).localX, TouchEvent(e).localY);
				stage.addEventListener(TouchEvent.TOUCH_MOVE, updateStencilScale);
				stage.addEventListener(TouchEvent.TOUCH_END, stopScalingStencil);
			}
		}
		
		private function updateStencilScale(e:Event):void
		{
			//First we'll deal with where the scale button should be, then we'll figure the rest out
			if (e is MouseEvent)
			{
				if (MouseEvent(e).stageY - this.y - dragHandleOffset.y < _canvasHolder.canvas.height + _canvasHolder.canvas.y - scaleSprite.height - this.y)
					scaleSprite.y = MouseEvent(e).stageY - _canvasHolder.canvas.y - this.y - dragHandleOffset.y;
				else 
					scaleSprite.y = _canvasHolder.canvas.height - scaleSprite.height - this.y;
				
				if (MouseEvent(e).stageX - this.x - dragHandleOffset.x < _canvasHolder.canvas.width + _canvasHolder.canvas.x - scaleSprite.width - this.x)
					scaleSprite.x = MouseEvent(e).stageX - _canvasHolder.canvas.x - this.x - dragHandleOffset.x;
				else
				{
					scaleSprite.x = _canvasHolder.canvas.width - scaleSprite.width - this.x;
				}
			}
			
			else if (e is TouchEvent)
			{
				if (TouchEvent(e).stageY - this.y - dragHandleOffset.y < _canvasHolder.canvas.height + _canvasHolder.canvas.y - scaleSprite.height - this.y)
					scaleSprite.y = TouchEvent(e).stageY - _canvasHolder.canvas.y - this.y - dragHandleOffset.y;
				else 
					scaleSprite.y = _canvasHolder.canvas.height - scaleSprite.height - this.y;
				
				if (TouchEvent(e).stageX - this.x - dragHandleOffset.x < _canvasHolder.canvas.width + _canvasHolder.canvas.x - scaleSprite.width - this.x)
					scaleSprite.x = TouchEvent(e).stageX - _canvasHolder.canvas.x - this.x - dragHandleOffset.x;
				else
				{
					scaleSprite.x = _canvasHolder.canvas.width - scaleSprite.width - this.x;
				}
			}
			
			scaleSprite.x = Math.max(scaleSprite.x, (scaleSprite.width * 2) + (stencil.x*2));
			scaleSprite.y = Math.max(scaleSprite.y, (scaleSprite.height * 2) + (stencil.y*2));
			
			//Not as simple as x = y. We need to keep it the same aspect ratio.
			if (uniformScale)
			{
				
				//scaleSprite.x = scaleSprite.y * ratio;
				//If new x < canvas edge
				if ((scaleSprite.y * ratio) + scaleSprite.width  < _canvasHolder.canvas.width - this.x)
					scaleSprite.x = scaleSprite.y * ratio;
				
				else
					scaleSprite.y = scaleSprite.x / ratio;
			}
			
			moveSprite.y = scaleSprite.y;
			
			//scaleSprite.x = stencil.width + (stencil.x * 2) - scaleSprite.width;
			stencil.width = scaleSprite.x + scaleSprite.width - (stencil.x * 2);
			//scaleSprite.y = stencil.height + (stencil.y * 2) - scaleSprite.height;
			stencil.height = scaleSprite.y + scaleSprite.height - (stencil.y * 2);
			
			//stencil.width = scaleSprite.x - (stencil.x + closeSprite.x + closeSprite.width);
			//stencil.height = scaleSprite.y - (stencil.y + closeSprite.y + closeSprite.height);
			
			rightSprite.x = scaleSprite.x + scaleSprite.width - rightSprite.width;
			leftSprite.x = rightSprite.x - (leftSprite.width*2);
		}
		
		private function stopScalingStencil(e:Event):void
		{
			if (e is MouseEvent)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateStencilScale);
				stage.removeEventListener(MouseEvent.MOUSE_UP, stopScalingStencil);
			}
				
			else if (e is TouchEvent)
			{
				stage.removeEventListener(TouchEvent.TOUCH_MOVE, updateStencilScale);
				stage.removeEventListener(TouchEvent.TOUCH_END, stopScalingStencil);
			}
			
		}
		
		private function closeThis(e:Event):void
		{
			stage.removeEventListener(MouseEvent.CLICK, closeThis);
			stage.removeEventListener(TouchEvent.TOUCH_END, closeThis);
			SettingsManager.currentBrushType = "normal";
			_canvasHolder.deleteChild(this);
		}
	}
}