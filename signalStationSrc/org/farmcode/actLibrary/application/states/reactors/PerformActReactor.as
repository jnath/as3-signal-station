package org.farmcode.actLibrary.application.states.reactors
{
	import flash.utils.Dictionary;
	
	import org.farmcode.actLibrary.application.states.AppStateMatch;
	import org.farmcode.actLibrary.core.IRevertableAct;
	import org.farmcode.acting.actTypes.IAct;
	
	public class PerformActReactor implements IAppStateReactor
	{
		
		public function get act():IAct{
			return _act;
		}
		public function set act(value:IAct):void{
			if(_act!=value){
				_act = value;
				_revertableAct = (value as IRevertableAct);
			}
		}
		
		public function get actProps():Dictionary{
			return _actProps;
		}
		public function set actProps(value:Dictionary):void{
			if(_actProps!=value){
				_actProps = value;
				lastPropValues = new Dictionary();
			}
		}
		
		private var _actProps:Dictionary;
		private var _act:IAct;
		private var _revertableAct:IRevertableAct;
		private var lastPropValues:Dictionary;
		
		public function enable(newMatch:AppStateMatch, oldMatch:AppStateMatch):IAct{
			if(_actProps){
				for(var destProp:String in _actProps){
					var sourceProp:String = _actProps[destProp];
					_act[destProp] = lastPropValues[sourceProp] = newMatch.parameters[sourceProp];
				}
			}
			return _act;
		}
		
		public function disable(newMatch:AppStateMatch, oldMatch:AppStateMatch):IAct{
			if(_revertableAct && _revertableAct.doRevert){
				return _revertableAct.revertAct;
			}
			return null;
		}
		
		public function refresh(newMatch:AppStateMatch, oldMatch:AppStateMatch):IAct{
			if(_actProps){
				var doReturn:Boolean;
				for(var destProp:String in _actProps){
					var sourceProp:String = _actProps[destProp];
					var newValue:* = newMatch.parameters[sourceProp];
					if(newValue!=lastPropValues[sourceProp]){
						_act[destProp] = lastPropValues[sourceProp] = newValue;
						doReturn = true;
					}
				}
				if(doReturn){
					return _act;
				}
			}
			return null;
		}
	}
}