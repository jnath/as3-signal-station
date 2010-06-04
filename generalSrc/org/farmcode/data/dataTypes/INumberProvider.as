package org.farmcode.data.dataTypes
{
	import org.farmcode.acting.actTypes.IAct;

	public interface INumberProvider
	{
		function get numericalValue():Number;
		
		/**
		 * handler(from:INumericalData)
		 */
		function get numericalValueChanged():IAct;
	}
}