package utils
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import objects.SerializedBitmap;

	public final class FileUtils extends Object
	{
		public function FileUtils()
		{
			
		}
		
		public static function getFileList(url:String):Array
		{
			var dir:File = File.applicationDirectory.resolvePath(url);
			var fileListArray:Array = dir.getDirectoryListing();
			
			return fileListArray;
		}
		
		public static function loadImage(url:String, container:Array, serialize:Boolean=false):void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			loader.load(new URLRequest(url));
			
			function imageLoaded(e:Event):void
			{
				var bmp:Bitmap = Bitmap(loader.content);
				var sb:SerializedBitmap;
				if (serialize)
				{
					sb = new SerializedBitmap(bmp);
					container.push(sb);
				}
				else
					container.push(bmp);
			}
		}
		
		public static function loadImagesAtURL(url:String, serializedContainer:Array, nonserializedContainer:Array, callback:Function):void
		{
			var dir:File = File.applicationDirectory.resolvePath(url);
			var fileListArray:Array = dir.getDirectoryListing(); //Full file list
			var actualURLStoLoad:Array = []; //urls of usable files
			var fileCount:int = 0;
			var imagesLoaded:int = 0;
			
			//Find the number of files which are usable so we know when we're done
			for each(var f:File in fileListArray)
			{
				if (f.extension == "jpg" || f.extension == "png")
				{
					fileCount++;
					actualURLStoLoad.push(f.url);
				}
			}
			
			//Load all the images syncronously so arrays match directory order
			var i:int = 0;
			loadImage();
			
			function loadImage():void
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				loader.load(new URLRequest(actualURLStoLoad[i]));
			}
			
			function imageLoaded(e:Event):void
			{
				imagesLoaded++;
				var bmp:Bitmap = Bitmap(LoaderInfo(e.target).content);
				var sb:SerializedBitmap = new SerializedBitmap(bmp);
				serializedContainer.push(sb);
				nonserializedContainer.push(bmp);
				
				if(imagesLoaded == fileCount)
				{
					//Since we can't dispatch events (we're not an instanciated class, how would anything listen to us?) we'll just do a callback
					callback();
				}
				else
				{
					i++;
					loadImage();
				}
			}
		}
	}
}