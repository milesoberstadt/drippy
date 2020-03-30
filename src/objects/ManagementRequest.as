package objects
{
	import com.adobe.crypto.MD5;

	public class ManagementRequest extends Object
	{
		private var _password:String;
		
		public function ManagementRequest()
		{
			super();
		}
		
		public function get password():String
		{
			return _password;
		}
		
		public function set password(plainPass:String):void
		{
			//For some reason this is getting called when it's received, so it rehashes the hash
			//_password = encode(plainPass);
			_password = plainPass;
		}
		
		public function encode(s:String):String
		{
			var encodedString:String = MD5.hash(s);
			return encodedString;
		}
		
	}
}