package objects
{
	import flash.display.Sprite;
	
	public class Dot extends Sprite
	{
		public function Dot()
		{
			super();
			
			this.graphics.beginFill(0x0000FF, 1);
			this.graphics.drawCircle(0,0, 10);
			this.graphics.endFill();
		}
	}
}