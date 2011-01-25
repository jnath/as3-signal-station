package org.tbyrne.actLibrary.display.popup.actTypes
{
	import flash.display.DisplayObjectContainer;
	
	import org.tbyrne.acting.actTypes.IUniversalAct;
	import org.tbyrne.display.assets.nativeTypes.IDisplayObjectContainer;
	import org.tbyrne.display.popup.IPopupInfo;
	
	public interface IAddPopupAct extends IUniversalAct
	{
		function get popupInfo():IPopupInfo;
		function get parent():IDisplayObjectContainer;
	}
}