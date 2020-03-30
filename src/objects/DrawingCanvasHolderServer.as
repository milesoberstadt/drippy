package objects
{
	import config.ServerConfiguration;
	
	import connection.ConnectionEvent;
	import connection.ConnectionManager;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import mx.core.FlexGlobals;
	import mx.graphics.codec.PNGEncoder;
	
	import prefs.ClientPreferences;
	import prefs.ServerPreferences;
	
	import spark.components.Group;
	
	import utils.ServerUtils;
	
	public class DrawingCanvasHolderServer extends Sprite
	{
		/* Begin properties from drippy.mxml */
		public var serverPrefs:ServerPreferences;
		
		public var backgroundHolder:Sprite;
		public var canvas:DrawingCanvas;
		public var foregroundHolder:Sprite;
		
		private var nextLineAssignment:int = 0;
		
		//We'll probably need one of these for each client...later
		//public var clientArray:Array = [];
		
		/* Begin properties from DrawingCanvasHolderClient.as */
		//TODO: make some kind of orgainzation for these properties, preferably some kind of global instance that can be eaisliy accessed
		
		public var scale:Number;
		
		public function get currentLayerAssignment():LayerIndex
		{
			return new LayerIndex(nextLineAssignment++);
		}
		
		public var myMenu:Group;
		
		//This determines whether we want to handle mouse events, otherwise we'll just use touch events
		public var bMouseEvents:Boolean = false;
		
		public function DrawingCanvasHolderServer()
		{
			super();
			
			this.addEventListener(Event.ADDED_TO_STAGE, continueInit);
		}
		
		private function continueInit(e:Event):void
		{
			scale = FlexGlobals.topLevelApplication.runtimeDPI / FlexGlobals.topLevelApplication.applicationDPI;
		}
		
		
		
		public function onMultiPointLine(e:ConnectionEvent):void
		{
			//First we need to figure out what client this is from
			var sendingClient:DrippyClient = ServerUtils.getClientFromConnection(e);
			
			var currentLine:MultiPointLine = e.receivedObject as MultiPointLine;
			
			//Scale to get to a standardized scale and one that draws well for us.
			//We're going from the client's scale
			currentLine.scaleLine(scale * sendingClient.preferences.clientScale);
			
			canvas.drawnObjectArray.push(currentLine);
			
			canvas.draw(currentLine.generateSprite());
			
			//Any time we get a line, we should respond with a new identifier 
			sendLineIndex(sendingClient.CM);
			
			//Next, we'll send the line to every client that didn't send it to us
			ServerUtils.rebroadcastObject(currentLine, Socket(e.currentTarget.clientSocket));
		}
		
		public function onFillRequest(e:ConnectionEvent):void
		{
			//First we need to figure out what client this is from
			var sendingClient:DrippyClient = ServerUtils.getClientFromConnection(e);
			
			var currentFill:FillRequest = e.receivedObject as FillRequest;
			
			//Scale to get to a standardized scale and one that draws well for us.
			//We're going from the client's scale
			currentFill._x *= (scale * sendingClient.preferences.clientScale);
			currentFill._y *= (scale * sendingClient.preferences.clientScale);
			
			canvas.drawnObjectArray.push(currentFill);
			
			canvas.fill(currentFill._x, currentFill._y, currentFill._color);
			//Any time we get a line, we should respond with a new identifier 
			sendLineIndex(sendingClient.CM);
			
			//Next, we'll send the line to every client that didn't send it to us
			ServerUtils.rebroadcastObject(currentFill, Socket(e.currentTarget.clientSocket));
		}
		
		public function onStickerRequest(e:ConnectionEvent):void
		{
			//First we need to figure out what client this is from
			var sendingClient:DrippyClient = ServerUtils.getClientFromConnection(e);
			
			var currentSticker:StickerRequest = e.receivedObject as StickerRequest;
			
			//Scale to get to a standardized scale and one that draws well for us.
			//We're going from the client's scale
			currentSticker._x *= (scale * sendingClient.preferences.clientScale);
			currentSticker._y *= (scale * sendingClient.preferences.clientScale);
			currentSticker._width *= (scale * sendingClient.preferences.clientScale);
			currentSticker._height *= (scale * sendingClient.preferences.clientScale);
			
			canvas.drawnObjectArray.push(currentSticker);
			
			//We NEED to make sure to give canvas a refrence to the sticker array first
			canvas.drawSticker(currentSticker);
			//Any time we get a line, we should respond with a new identifier 
			sendLineIndex(sendingClient.CM);
			
			//Next, we'll send the line to every client that didn't send it to us
			ServerUtils.rebroadcastObject(currentSticker, Socket(e.currentTarget.clientSocket));
		}
		
		public function onStencilRequest(e:ConnectionEvent):void
		{
			//First we need to figure out what client this is from
			var sendingClient:DrippyClient = ServerUtils.getClientFromConnection(e); 
			
			var currentStencil:StencilRequest = e.receivedObject as StencilRequest;
			var stencilBM:Bitmap = currentStencil.stencilDrawing.getBitmap();
			//Scale to server size, clients know this and can rescale when they get it.
			//This doesn't need it's position scaled, it's a bitmap.draw of the whole canvas
			stencilBM.scaleX *= (scale * sendingClient.preferences.clientScale);
			stencilBM.scaleY *= (scale * sendingClient.preferences.clientScale);
			
			canvas.drawnObjectArray.push(stencilBM);
			
			//Draw doesn't draw scale matrix by default
			canvas.draw(stencilBM, true);
			
			sendLineIndex(sendingClient.CM);
			
			ServerUtils.rebroadcastObject(new StencilRequest(stencilBM), Socket(e.currentTarget.clientSocket));
		}
		
		public function onUndoRequest(e:ConnectionEvent):void
		{
			var ur:UndoRequest = e.receivedObject as UndoRequest;
			canvas.undoLineAt(ur.layerIndex);
			
			ServerUtils.rebroadcastObject(ur, Socket(e.currentTarget.clientSocket));
		}
		
		/*public function onSprite(e:ConnectionEvent):void
		{
			/*var line:Line = e.receivedObject.line;
			if (line != null)
			canvas.draw(line);*/
		//}
		
		public function sendLineIndex(cm:ConnectionManager):void
		{
			cm.queueObjectToSend(new LayerIndex(nextLineAssignment++));
		}
		
		
		/**
		 * After recieving an object from a client, we use it, then broadcast it to other clients to keep everything synched.
		 */
		
		
		public function doBrushwork(e:Event):void
		{
			//trace(TouchEvent(e).touchPointID);
			if (SettingsManager.currentBrushType == "normal")
				startLine(e);
			else if (SettingsManager.currentBrushType == "fill")
			{			
				var fillReq:FillRequest;
				
				if (e is MouseEvent)
				{
					canvas.fill(MouseEvent(e).localX, MouseEvent(e).localY, SettingsManager.currentLineColor);
					fillReq = new FillRequest(MouseEvent(e).localX, MouseEvent(e).localY, SettingsManager.currentLineColor);
				}
				else if (e is TouchEvent)
				{
					canvas.fill(TouchEvent(e).localX, TouchEvent(e).localY, SettingsManager.currentLineColor);
					fillReq = new FillRequest(TouchEvent(e).localX, TouchEvent(e).localY, SettingsManager.currentLineColor)
				}
				
				if (fillReq)
				{
					fillReq.layerIndex = currentLayerAssignment;
					canvas.drawnObjectArray.push(fillReq);
					canvas.myLayerIndexes.push(currentLayerAssignment);
					ServerUtils.rebroadcastObject(fillReq);
					//serverConnection.queueObjectToSend(fillReq);
				}
			}
		}
		
		private function startLine(e:Event):void
		{
			var currentLine:MultiPointLine = new MultiPointLine();
			currentLine = new MultiPointLine();
			if(e is TouchEvent)
				currentLine.touchPointID = TouchEvent(e).touchPointID;
			currentLine.lineColor = SettingsManager.currentLineColor;
			currentLine.lineThickness = SettingsManager.currentBrushSize;

			currentLine.layerIndex = currentLayerAssignment;
			if (e is MouseEvent)
			{
				currentLine.push(new Point(mouseX, mouseY));
				if (bMouseEvents)
				{
					canvas.addEventListener(MouseEvent.MOUSE_MOVE, moveMouse);
					canvas.addEventListener(MouseEvent.MOUSE_UP, endLine);
				}
			}
			else if (e is TouchEvent)
			{
				currentLine.push(new Point(TouchEvent(e).localX, TouchEvent(e).localY));
				canvas.addEventListener(TouchEvent.TOUCH_MOVE, extendTouch);
				canvas.addEventListener(TouchEvent.TOUCH_END, endLine);
			}
				
			canvas.currentLineArray.push(currentLine);
		}
		
		private function moveMouse(e:MouseEvent):void
		{
			extendLine();
			e.updateAfterEvent();
		}
		
		private function extendLine():void
		{
			var pointToSend:Point = new Point(mouseX, mouseY);
			
			canvas.currentLineArray[0].push(pointToSend);
			
			if (canvas.currentLineArray[0].pointArray.length > 1)
				canvas.drawLine(canvas.currentLineArray[0]);
			
		}
		
		private function extendTouch(e:TouchEvent):void
		{
			var pointToSend:Point = new Point(e.localX, e.localY);
			
			var index:int = -1;
			
			for each(var m:MultiPointLine in canvas.currentLineArray)
			{
				if (m.touchPointID == e.touchPointID)
				{
					index = canvas.currentLineArray.indexOf(m);
					break;
				}
			}
			
			if (index != -1)
			{
				canvas.currentLineArray[index].push(pointToSend);
			
				if (canvas.currentLineArray[index].pointArray.length > 1)
					canvas.drawLine(canvas.currentLineArray[index]);
			}
			
		}
		
		public function undo():void
		{
			var layerToUndo:LayerIndex = canvas.myLayerIndexes[canvas.myLayerIndexes.length-1];
			canvas.myLayerIndexes.pop();
			canvas.undoLineAt(layerToUndo);
			
			var undoReq:UndoRequest = new UndoRequest(layerToUndo);
			ServerUtils.rebroadcastObject(undoReq);
			//serverConnection.queueObjectToSend(undoReq);
		}
		
		/**
		 * This is so management can do system wide undos
		 * */
		public function masterUndo():void
		{
			var layerToUndo:LayerIndex = DrawableBase(canvas.drawnObjectArray[canvas.drawnObjectArray.length-1]).layerIndex; //canvas.myLayerIndexes[canvas.myLayerIndexes.length-1];
			canvas.myLayerIndexes.pop();
			canvas.undoLineAt(layerToUndo);
			
			var undoReq:UndoRequest = new UndoRequest(layerToUndo);
			ServerUtils.rebroadcastObject(undoReq);
		}
		
		private function endLine(e:Event):void
		{				
			if (e is MouseEvent)
			{
				canvas.saveLineAt(0);
				ServerUtils.rebroadcastObject(canvas.currentLineArray[0]);
				canvas.currentLineArray.splice(0,1);
			}
			
			else if (e is TouchEvent)
			{
				for each(var m:MultiPointLine in canvas.currentLineArray)
				{
					if (m.touchPointID == TouchEvent(e).touchPointID)
					{
						var i:int = canvas.currentLineArray.indexOf(m);
						canvas.saveLineAt(i);
						ServerUtils.rebroadcastObject(canvas.currentLineArray[i]);
						canvas.currentLineArray.splice(i,1);
						break;
					}
				}
			}
			
			
			canvas.removeEventListener(MouseEvent.MOUSE_MOVE, moveMouse);
			canvas.removeEventListener(TouchEvent.TOUCH_MOVE, extendTouch);
			
			canvas.removeEventListener(MouseEvent.MOUSE_UP, endLine);
			canvas.removeEventListener(TouchEvent.TOUCH_END, endLine);
		}
		
		//We need something like this (same name for both server and client) so other classes can send objects
		public function queueObjectToSend(o:Object):void
		{
			ServerUtils.rebroadcastObject(o);
		}
		
		public function deleteChild(target:DisplayObject):void
		{
			if (canvas.contains(target))
				canvas.removeChild(target);
			else 
				trace("Tried to remove " + target + " from stage, but it isn't a child...");
		}
		
		public function saveAndClear():void
		{
			var snapshot:Bitmap = new Bitmap(new BitmapData(this.width, this.height, false, 0), "auto", true);
			snapshot.bitmapData.draw(backgroundHolder);
			snapshot.bitmapData.draw(canvas);
			snapshot.bitmapData.draw(foregroundHolder);
			
			var png:PNGEncoder = new PNGEncoder();
			
			var ba:ByteArray = png.encode(snapshot.bitmapData);
			
			var date:Date = new Date();
			var unixTime:Number = date.time;
			var dateAsString:String = Number(date.month+1) + "-" + date.date + "-" + date.fullYear;
			var dir:File = File.applicationDirectory.resolvePath(ServerConfiguration.savedImagesDir + dateAsString);
			dir.createDirectory();
			var file:File = File.applicationDirectory.resolvePath(ServerConfiguration.savedImagesDir + dateAsString + "/" + unixTime + ".png");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeBytes(ba);
			fileStream.close();
			
			canvas.clear();
		}
	}
}