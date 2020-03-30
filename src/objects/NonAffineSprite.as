package objects
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class NonAffineSprite extends Sprite
	{
		private var drawTarget:Bitmap;
		
		public var d1:Dot, d2:Dot, d3:Dot, d4:Dot;
				
		public function NonAffineSprite(objectToDraw:Bitmap)
		{
			super();
			
			drawTarget = objectToDraw;
			
			this.graphics.beginBitmapFill(drawTarget.bitmapData, null, false, true);
			this.graphics.drawTriangles(
				//Vector of Numbers, points for triangles
				Vector.<Number>([0, 0, 
								drawTarget.width, 0,
								(drawTarget.width)*0.5, (drawTarget.height)*0.5,
								0, 0+drawTarget.height,
								(drawTarget.width), (drawTarget.height)]), 
				//Vector of ints, triangles defined by previous Vector.<Number> (index buffer)
				Vector.<int>([0,1,2, 
							2,1,4,
							2,3,4,
							3,0,2]),
				//Vector of Numbers, where the points are on the UVW map, corresponds with order of the first Vector.<Number> 
				Vector.<Number>([0,0, 
								1,0, 
								0.5,0.5,
								0,1, 
								1,1]));
			this.graphics.endFill();
		}
		
		public function updateCorners():void
		{
			this.graphics.clear();
			
			var p1:Point, p2:Point, p3:Point, p4:Point, p5:Point;
			p1 = new Point(d1.x-this.x, d1.y-this.y);
			p2 = new Point(d2.x-this.x, d2.y-this.y);
			//p3 = new Point((((d2.x/2)/2) + ((d4.x/2)/2)) + ((d1.x/2)-this.x), (((d4.y/2)/2) + ((d3.y/2)/2))+ ((d1.y/2)-this.y));
			//p3 = new Point( (((d2.x-d3.x)/2 + (d4.x-d1.x)/2)/2) + ((d1.x/2)-this.x), (((d3.y-d2.y)/2 + (d4.y-d1.y)/2)/2) + ((d1.y/2)-this.y) );
			p3 = getCenterIntersection();
			p4 = new Point(d3.x-this.x, d3.y-this.y);
			p5 = new Point(d4.x-this.x, d4.y-this.y);
			
			this.graphics.beginBitmapFill(drawTarget.bitmapData, null, false, true);
			this.graphics.drawTriangles(
				Vector.<Number>([p1.x, p1.y, 
					p2.x, p2.y,
					p3.x, p3.y, //Average of the x and y differences between both top and bottom, left and right //d1.x+(d2.x/2)-this.x, d2.y+(d3.y/2)-this.y,//cornerX*0.5, cornerY*0.5,
					p4.x, p4.y,
					p5.x, p5.y]), 
				Vector.<int>([0,1,2, 
					2,1,4,
					2,3,4,
					3,0,2]),
				Vector.<Number>([0,0, 
					1,0, 
					0.5,0.5,
					0,1, 
					1,1]));
			this.graphics.endFill();
			
			//Draw the circles
			/*for each (var point:Point in [p1,p2,p3,p4,p5])
			{
				this.graphics.beginFill(0xFF0000);
				this.graphics.drawCircle(point.x, point.y, 5);
				this.graphics.endFill();
			}*/
			
			//Draw verts
			/*this.graphics.lineStyle(3, 0x00FF00);
			this.graphics.moveTo(p1.x, p1.y);
			this.graphics.lineTo(p2.x, p2.y);
			this.graphics.lineTo(p3.x, p3.y);
			this.graphics.lineTo(p1.x, p1.y);
			this.graphics.lineTo(p4.x, p4.y);
			this.graphics.lineTo(p3.x, p3.y);
			this.graphics.lineTo(p5.x, p5.y);
			this.graphics.lineTo(p4.x, p4.y);*/
			
			//Draw diagnals
			/*this.graphics.lineStyle(3, 0xFFFF00);
			this.graphics.moveTo(p1.x, p1.y);
			this.graphics.lineTo(p5.x, p5.y);
			this.graphics.moveTo(p2.x, p2.y);
			this.graphics.lineTo(p4.x, p4.y);*/
			
			
			//Old center tests
			//this.graphics.beginFill(0x00FFFF);
			//var centerX:Number = ((d1.x + ((d2.x-d1.x)/2)) + (d3.x + ((d4.x-d3.x)/2)))/2;
			//var centerY:Number = ((d1.y + ((d3.y-d1.y)/2)) + (d2.y + ((d4.y-d1.y)/2)))/2;
			//this.graphics.drawCircle(centerX, centerY, 5);
			//this.graphics.endFill();
		}
		
		private function getCenterIntersection():Point
		{
			//Not totally sure how this math works, just go with it (http://flassari.is/2009/04/line-line-intersection-in-as3/)
			var x1:Number = d1.x, x2:Number = d4.x, x3:Number = d3.x, x4:Number = d2.x;
			var y1:Number = d1.y, y2:Number = d4.y, y3:Number = d3.y, y4:Number = d2.y;
			var z1:Number= (x1 -x2), z2:Number = (x3 - x4), z3:Number = (y1 - y2), z4:Number = (y3 - y4);
			var d:Number = z1 * z4 - z3 * z2;
			// Get the x and y
			var pre:Number = (x1*y2 - y1*x2), post:Number = (x3*y4 - y3*x4);
			var centerX:Number = ( pre * z2 - z1 * post ) / d;
			var centerY:Number = ( pre * z4 - z3 * post ) / d;
			
			return new Point(centerX, centerY);
		}
		
	}
}