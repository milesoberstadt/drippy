package objects
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class TransformContainer extends Sprite
	{
		private var d1:Dot, d2:Dot, d3:Dot, d4:Dot;
		private var clickedDot:Dot;
		private var image:NonAffineSprite;
		
		private var displayBitmap:Bitmap;
		
		public function TransformContainer(displayObject:Bitmap)
		{
			displayBitmap = displayObject;
			
			if (stage)
				continueInit();
			else
				this.addEventListener(Event.ADDED_TO_STAGE, continueInit);
		}
		
		private function continueInit(e:Event=null):void
		{
			d1 = new Dot();
			d2 = new Dot();
			d3 = new Dot();
			d4 = new Dot();
			
			image = new NonAffineSprite(displayBitmap);
			image.d1 = d1;
			image.d2 = d2;
			image.d3 = d3;
			image.d4 = d4;
			
			this.addChild(image);
			
			d1.x = image.x;
			d1.y = image.y;
			d2.x = image.x + image.width;
			d2.y = image.y;
			d3.x = image.x;
			d3.y = image.y + image.height;
			d4.x = image.x + image.width;
			d4.y = image.y + image.height;
			
			this.addChild(d1);
			this.addChild(d2);
			this.addChild(d3);
			this.addChild(d4);
			
			d1.addEventListener(MouseEvent.MOUSE_DOWN, listenForDrag);
			d2.addEventListener(MouseEvent.MOUSE_DOWN, listenForDrag);
			d3.addEventListener(MouseEvent.MOUSE_DOWN, listenForDrag);
			d4.addEventListener(MouseEvent.MOUSE_DOWN, listenForDrag);
		}
		
		private function listenForDrag(e:MouseEvent):void
		{
			clickedDot = e.target as Dot;
			if (clickedDot!=null)
			{
				clickedDot.removeEventListener(MouseEvent.MOUSE_DOWN, listenForDrag);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, dragPoint);
				stage.addEventListener(MouseEvent.MOUSE_UP, doneDragging);
			}
		}
		
		private function dragPoint(e:MouseEvent):void
		{
			clickedDot.x = e.stageX;
			clickedDot.y = e.stageY;
			
			image.updateCorners();
		}
		
		private function doneDragging(e:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragPoint);
			stage.removeEventListener(MouseEvent.MOUSE_UP, doneDragging);
			e.target.addEventListener(MouseEvent.MOUSE_DOWN, listenForDrag);
			clickedDot = null;
		}
	}
}