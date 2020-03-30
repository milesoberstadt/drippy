package components
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.FlexGlobals;
	
	import objects.SettingsManager;
	
	public class SizePicker extends Sprite
	{
		private var maxWidth:Number = 100;
		private var minWidth:Number = 0;
		
		private var sliderBar:Sprite = new Sprite();
		private var sizeSelector:Sprite = new Sprite();
		private var brushPreview:Sprite = new Sprite();
		
		public function SizePicker()
		{
			sliderBar.graphics.beginFill(0xFFFFFF, 1);
			sliderBar.graphics.drawRect(0,0,500,25);
			sliderBar.graphics.endFill();
		
			addChild(sliderBar);
			
			
			sizeSelector.graphics.beginFill(0x000000, 1);
			sizeSelector.graphics.drawRect(0,0,30,100);
			sizeSelector.graphics.endFill();
			
			sizeSelector.addEventListener(MouseEvent.MOUSE_DOWN, listenForDrag);
			
			addChild(sizeSelector);
			
			//brushPreview.width = maxWidth;
			//brushPreview.height = maxWidth;
			brushPreview.x = sliderBar.x + sliderBar.width + maxWidth;
			brushPreview.y = maxWidth / 2; //sliderBar.y + sliderBar.height/2;
			addChild(brushPreview);
			
			sliderBar.y = brushPreview.y - sliderBar.height/2;
			sizeSelector.y = (sliderBar.y + (sliderBar.height/2)) - sizeSelector.height/2;
			
			setSize(SettingsManager.currentBrushSize);
		}
		
		private function listenForDrag(e:MouseEvent):void
		{
			stage.addEventListener(MouseEvent.MOUSE_UP, stopListeningForDrag);
			e.target.addEventListener(Event.ENTER_FRAME, getDragPos);
		}
		
		private function stopListeningForDrag(e:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopListeningForDrag);
			e.target.removeEventListener(Event.ENTER_FRAME, getDragPos);
		}
		
		private function getDragPos(e:Event):void
		{
			//relative mouse divided by the bar's width gives us a percent. Multiply by stuff and add the min to get new val 
			var newPos:Number = Math.floor((mouseX - sliderBar.x)/sliderBar.width*(maxWidth-minWidth)+minWidth);
			//Make sure we're at least at the min
			newPos = newPos<minWidth?minWidth:newPos;
			//Make sure we're not over our max
			newPos = newPos>maxWidth?maxWidth:newPos;
			
			setSize(newPos);
		}
		
		private function setSize(newSize:Number):void
		{
			//This is the percent
			//trace((newSize - minWidth)/(maxWidth-minWidth));
			sizeSelector.x = sliderBar.x + ((newSize - minWidth) /(maxWidth-minWidth) * sliderBar.width);
			//This allows us to keep the slider inside the bar
			sizeSelector.x -= ((newSize - minWidth)/(maxWidth-minWidth)) * sizeSelector.width;
			SettingsManager.currentBrushSize = newSize;
			
			brushPreview.graphics.clear();
			brushPreview.graphics.beginFill(SettingsManager.currentLineColor, 1);
			brushPreview.graphics.drawCircle(0,0,newSize);
			brushPreview.graphics.endFill();
		}
	}
}