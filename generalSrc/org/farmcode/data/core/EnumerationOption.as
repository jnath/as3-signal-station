package org.farmcode.data.core
{
	import org.farmcode.acting.actTypes.IAct;
	import org.farmcode.acting.acts.Act;
	import org.farmcode.data.dataTypes.IStringProvider;
	
	public class EnumerationOption extends BooleanData implements IStringProvider
	{
		
		override public function get value():*{
			return _value;
		}
		public function set value(value:*):void{
			if(_value!=value){
				_value = value;
			}
		}
		
		public function get stringValue():String{
			return _stringValue;
		}
		public function set stringValue(value:String):void{
			if(_stringValue!=value){
				_stringValue = value;
				if(_stringValueChanged)_stringValueChanged.perform(this);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get stringValueChanged():IAct{
			if(!_stringValueChanged)_stringValueChanged = new Act();
			return _stringValueChanged;
		}
		
		protected var _stringValueChanged:Act;
		private var _stringValue:String;
		private var _value:*;
		
		public function EnumerationOption()
		{
		}
	}
}