package org.farmcode.display.assets
{

	public interface ISpriteAsset extends IContainerAsset, IShapeAsset
	{
		function get useHandCursor():Boolean;
		function set useHandCursor(value:Boolean):void;
		
		function get buttonMode():Boolean;
		function set buttonMode(value:Boolean):void;
		
		function get hitArea():ISpriteAsset;
		function set hitArea(value:ISpriteAsset):void;
	}
}