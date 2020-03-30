package objects
{
	public class UndoRequest
	{
		public var layerIndex:LayerIndex;
		
		public function UndoRequest(index:LayerIndex = null)
		{
			layerIndex = index;
		}
	}
}