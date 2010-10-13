package org.farmcode.display.assets.assetTypes
{
	import flash.display.BitmapData;

	public interface IBitmapAsset extends IDisplayAsset
	{
		function get bitmapData():BitmapData;
		function set bitmapData(value:BitmapData):void;
		function get bitmapPixelSnapping():String;
		function set bitmapPixelSnapping(value:String):void;
		function get smoothing():Boolean;
		function set smoothing(value:Boolean):void;
	}
}