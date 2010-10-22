package org.tbyrne.display.transition
{
	import org.tbyrne.display.assets.assetTypes.IBitmapAsset;
	import org.tbyrne.display.assets.assetTypes.IDisplayAsset;
	
	public interface ITransition
	{
		
		function set timing(value:String):void;
		function get timing():String;
		function set duration(value:Number):void;
		function get duration():Number;
		
		function beginTransition(start:IDisplayAsset, finish:IDisplayAsset, bitmap:IBitmapAsset, duration:Number):void;
		function doTransition(start:IDisplayAsset, finish:IDisplayAsset, bitmap:IBitmapAsset, duration:Number, currentTime:Number):void;
		function endTransition(start:IDisplayAsset, finish:IDisplayAsset, bitmap:IBitmapAsset, duration:Number):void;
	}
}