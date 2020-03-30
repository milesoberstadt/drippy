package objects
{
	import flash.display.Bitmap;

	public class StencilRequest extends DrawableBase
	{
		public var stencilDrawing:SerializedBitmap;
		
		public function StencilRequest(stencil:Bitmap = null, index:LayerIndex = null)
		{
			if (stencil)
				stencilDrawing = new SerializedBitmap(stencil);
			
			layerIndex = index;
		}
	}
}