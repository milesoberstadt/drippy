package config
{
	import com.adobe.crypto.MD5;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public final class ServerConfiguration extends Object
	{
		public static var serverName:String = "My First Server";
		public static var backgroundDir:String = "Backgrounds\\";
		public static var defaultBackground:String = "wall3.png";
		public static var foregroundDir:String = "Foregrounds\\";
		public static var defaultForeground:String = "codemonkey.png";
		public static var stickersDir:String = "Stickers\\";
		public static var stencilsDir:String = "Stencils\\";
		public static var managementPasswordHash:String = MD5.hash("drippy");
		
		public static var savedImagesDir:String = "C:\\drippy images\\";
		
		public function ServerConfiguration()
		{
			super();
		}
		
		public static function loadConfiguration():void
		{
			var file:File = File.applicationStorageDirectory.resolvePath("config.xml");
			var myXML:XML = new XML();
			
			if (file.exists)
			{
				var myXMLURL:URLRequest = new URLRequest(file.url);
				var myLoader:URLLoader = new URLLoader(myXMLURL);
				myLoader.addEventListener(Event.COMPLETE, xmlLoaded);
			}
			
			else 
			{
				//myXML = createConfig();
			}
			
			function xmlLoaded(event:Event):void
			{
				myXML = XML(myLoader.data);
				//trace("Data loaded.");
				
				//Validate that settings exist so we don't clear them...
				if (String(myXML.serverName.@value).length > 0)
					serverName = myXML.serverName.@value;
				if (String(myXML.backgroundDir.@value).length > 0)
					backgroundDir = myXML.backgroundDir.@value;
				if (String(myXML.defaultBackground.@value).length > 0)
					defaultBackground = myXML.defaultBackground.@value;
				if (String(myXML.foregroundDir.@value).length > 0)
					foregroundDir = myXML.foregroundDir.@value;
				if (String(myXML.defaultForeground.@value).length > 0)
					defaultForeground = myXML.defaultForeground.@value;
				if (String(myXML.stickersDir.@value).length > 0)
					stickersDir = myXML.stickersDir.@value;
				if (String(myXML.stencilsDir.@value).length > 0)
					stencilsDir = myXML.stencilsDir.@value;
				if (String(myXML.savedImagesDir.@value).length > 0)
					savedImagesDir = myXML.savedImagesDir.@value;
				if (String(myXML.managementPasswordHash.@value).length > 0)
					managementPasswordHash = myXML.managementPasswordHash.@value;
				
			}
		}
		
		public static function saveConfiguration():void
		{
			var xml:XML = createConfig();
			var file:File = File.applicationStorageDirectory.resolvePath("config.xml");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(xml.toString());
			fileStream.close();
		}
		
		private static function createConfig():XML
		{
			var xml:XML = new XML();
			xml =
			<preferences>
				<serverName value={serverName}/>
				<backgroundDir value={backgroundDir}/>
				<defaultBackground value={defaultBackground}/>
				<foregroundDir value={foregroundDir}/>
				<defaultForeground value={defaultForeground}/>
				<stickersDir value={stickersDir}/>
				<stencilsDir value={stencilsDir}/>
				<savedImagesDir value={savedImagesDir}/>
				<managementPasswordHash value={managementPasswordHash}/>
			</preferences>;
			
			return xml;
		}
			
	}
}