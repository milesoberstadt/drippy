package components
{
	/* TODO: Add selection description text. People don't understand what brushes do without explaination*/
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	
	import mx.core.FlexGlobals;
	
	import objects.SettingsManager;
	
	public class BrushTypePicker extends Sprite
	{
		[Embed('../assets/brushTypeNormal.png')]
		[Bindable]
		public var ChangeTypeNormalImage:Class;
		
		[Embed('../assets/brushTypeFill.png')]
		[Bindable]
		public var ChangeTypeFillImage:Class;
		
		private var btnNormalBrush:Sprite = new Sprite();
		private var btnFillBrush:Sprite = new Sprite();
		
		private var currentSelection:String;
		
		private var selectionSprite:Sprite = new Sprite();
		
		public function BrushTypePicker()
		{
			btnNormalBrush.addChild(new ChangeTypeNormalImage());
			btnNormalBrush.addEventListener(MouseEvent.CLICK, changeSelection);
			btnNormalBrush.addEventListener(TouchEvent.TOUCH_END, changeSelection);
			addChild(btnNormalBrush);
			
			btnFillBrush.addChild(new ChangeTypeFillImage());
			btnFillBrush.x = btnNormalBrush.x + (btnNormalBrush.width*2);
			btnFillBrush.addEventListener(MouseEvent.CLICK, changeSelection);
			btnFillBrush.addEventListener(TouchEvent.TOUCH_END, changeSelection);
			addChild(btnFillBrush);
			
			selectionSprite.graphics.beginFill(0xFFD700, 1);
			selectionSprite.graphics.drawRect(0,0,(btnNormalBrush.width * 1.2),(btnNormalBrush.height * 1.2)); //Hopefully all the objects are the same size...
			selectionSprite.graphics.endFill();
			addChildAt(selectionSprite, 0);
			
			changeBrush(SettingsManager.currentBrushType);
		}
		
		private function changeSelection(e:Event):void
		{
			if (e.target == btnNormalBrush && currentSelection != "normal")
			{
				changeBrush("normal");
			}
			else if (e.target == btnFillBrush && currentSelection != "fill")
			{
				changeBrush("fill");
			}
		}
		
		private function changeBrush(newBrush:String):void
		{
			if (newBrush == "normal")
			{
				selectionSprite.x = (btnNormalBrush.x - (btnNormalBrush.width*0.1));
				selectionSprite.y = (btnNormalBrush.y - (btnNormalBrush.height*0.1));
			}
			else if (newBrush == "fill")
			{
				selectionSprite.x = (btnFillBrush.x - (btnFillBrush.width*0.1));
				selectionSprite.y = (btnFillBrush.y - (btnFillBrush.height*0.1));
			}
			
			SettingsManager.currentBrushType = newBrush;
		}
	}
	
}