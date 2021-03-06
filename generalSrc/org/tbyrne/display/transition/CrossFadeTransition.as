package org.tbyrne.display.transition
{
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import org.tbyrne.display.assets.nativeTypes.IBitmap;
	import org.tbyrne.display.assets.nativeTypes.IDisplayObject;
	
	public class CrossFadeTransition extends Transition
	{
		override public function doTransition(start:IDisplayObject, finish:IDisplayObject, bitmap:IBitmap, duration:Number, currentTime:Number):void{
			var bitmapMatrix:Matrix = bitmap.transform.concatenatedMatrix;
			bitmapMatrix.invert();
			
			var fract:Number = (currentTime/duration);
			var invFract:Number = 1-fract;
			
			var matrix:Matrix = start.transform.concatenatedMatrix;
			matrix.concat(bitmapMatrix);
			
			var color:ColorTransform = start.transform.colorTransform;
			color.alphaMultiplier = (1+Math.cos(fract*fract*Math.PI))/2;
			bitmap.bitmapData.draw(start.bitmapDrawable,matrix,color);
			
			matrix = finish.transform.concatenatedMatrix;
			matrix.concat(bitmapMatrix);
			
			color = finish.transform.colorTransform;
			color.alphaMultiplier = (1+Math.cos(invFract*invFract*Math.PI))/2;
			bitmap.bitmapData.draw(finish.bitmapDrawable,matrix,color);
		}
	}
}