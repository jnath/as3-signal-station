package org.tbyrne.behaviour.rules
{
	import org.tbyrne.behaviour.IBehavingItem;
	
	public interface ISingleItemRule extends IBehaviourRule
	{
		function set behavingItem(value:IBehavingItem):void;
		function get behavingItem():IBehavingItem;
	}
}