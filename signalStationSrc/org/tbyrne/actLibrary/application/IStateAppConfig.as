package org.tbyrne.actLibrary.application
{
	public interface IStateAppConfig extends IAppConfig
	{
		function get defaultAppStatePath():String;
		function get appStates():Array;
	}
}