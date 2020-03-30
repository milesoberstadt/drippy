package objects
{
	import flash.display.Sprite;
	import flash.geom.Point;

	public class MultiPointLine extends DrawableBase
	{
		public var pointArray:Array;
		public var lineColor:uint = 0x000000;
		public var lineThickness:Number = 5;
		public var touchPointID:int;
		
		public function MultiPointLine()
		{
			super();
			
			pointArray = new Array();
		}
		
		public function startLine(point:Point, color:uint, index:LayerIndex):void
		{
			pointArray.push(point);
			lineColor = color;
			layerIndex = index;
		}
		
		public function push(point:Point):void
		{
			pointArray.push(point);
		}
		
		/**
		* This function is meant to scale points in a line, 
		* generally when sent from another client.
		**/
		public function scaleLine(scaleAmount:Number):void
		{
			lineThickness *= scaleAmount;
			
			for (var i:int=0; i<pointArray.length; i++)
			{
				Point(pointArray[i]).x *= scaleAmount;
				Point(pointArray[i]).y *= scaleAmount;
			}
		}
		
		public function generateSprite():Sprite
		{
			var lineLayer:Sprite = new Sprite();
			
			lineLayer.graphics.clear();
			lineLayer.graphics.lineStyle(lineThickness, lineColor);
			//Move to point 0, then do every other point
			lineLayer.graphics.moveTo(pointArray[0].x, pointArray[0].y);
			for (var i:int=1; i<pointArray.length; i++)
				lineLayer.graphics.lineTo(pointArray[i].x, pointArray[i].y);
			
			return lineLayer;
		}
	}
}