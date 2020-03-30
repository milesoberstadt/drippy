package objects
{
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	public class SerializableObject implements IExternalizable 
	{
		private static var count:int = 0;

		public var ID:String;
		protected var number:Number = 0;
		private var string:String = '';
		private var padding:ByteArray;
		
		public function SerializableObject( objectSize:Number = 40, tag:String = 'default' )
		{
			registerClassAlias( "SerializableObject", SerializableObject );
			
			ID = "ID#" + SerializableObject.count++;
			number = Math.random();
			string = tag;
			var rawPadding:Number = objectSize - ID.length - string.length - 32;
			padding = createPadding( rawPadding >= 0 ? rawPadding : 0 );
		}
		
		public function toString():String
		{
			return "ID=" + ID + ", number=" + number.toFixed( 2 ) + ", string= " + string + ", padding= " + padding.length + " bytes";
		}
		
		//IExternalizable interface implementation
		public function writeExternal( output:IDataOutput ):void
		{
			output.writeUTF( ID );
			output.writeFloat( number );
			output.writeUTF( string );
			output.writeInt( padding.length ); //write byte array size
			output.writeBytes( padding );
		}
		
		public function readExternal( input:IDataInput ):void
		{
			ID = input.readUTF();
			number = input.readFloat();
			string = input.readUTF();
			var temp:int = input.readInt(); //read byte array size
			input.readBytes( padding, 0, temp );
		}
		
		private function createPadding( size:Number ):ByteArray
		{
			var ba:ByteArray = new ByteArray();
			for( var i:uint = 0; i < size; i++ )
			{
				ba.writeByte( 0xff );
			}
			return ba;
		}
		
	}
}