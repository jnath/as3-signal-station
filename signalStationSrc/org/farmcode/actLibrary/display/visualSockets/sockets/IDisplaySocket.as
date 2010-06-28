package org.farmcode.actLibrary.display.visualSockets.sockets
{
	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;
	
	import org.farmcode.actLibrary.display.visualSockets.plugs.IPlugDisplay;
	import org.farmcode.acting.actTypes.IAct;

	public interface IDisplaySocket
	{
		
		/**
		 * handler(from:IDisplaySocket)
		 */
		function get plugDisplayChanged():IAct;
		
		function get socketId(): String;
		function get plugMappers(): Array;
		function get globalPosition(): Rectangle;
		
		function get plugDisplay():IPlugDisplay;
		function set plugDisplay(value:IPlugDisplay):void;

		function set socketPath(value:String):void;
		function get socketPath():String;
	}
}