package org.farmcode.display.layout.frame
{
	import org.farmcode.display.layout.core.IMarginLayoutInfo;
	
	public interface IFrameLayoutInfo extends IMarginLayoutInfo
	{
		function get anchor():String;
		function get fitPolicy():String;
		function get scaleXPolicy():String;
		function get scaleYPolicy():String;
	}
}