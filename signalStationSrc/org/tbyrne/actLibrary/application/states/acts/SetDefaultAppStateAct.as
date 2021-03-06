package org.tbyrne.actLibrary.application.states.acts
{
	import flash.utils.Dictionary;
	
	import org.tbyrne.actLibrary.application.states.AppStateMatch;
	import org.tbyrne.actLibrary.external.siteStream.actTypes.IResolvePathsAct;

	public class SetDefaultAppStateAct extends SetAppStateAct implements IResolvePathsAct
	{
		public function get dataPath():String{
			return _dataPath;
		}
		public function set dataPath(value:String):void{
			_dataPath = value;
		}
		
		public function get data():*{
			return _data;
		}
		public function set data(value:*):void{
			_data = value;
		}
		override public function get appStateMatch():AppStateMatch{
			var ret:AppStateMatch = super.appStateMatch;
			if(ret && _dataPath){
				if(!ret.parameters)ret.parameters = new Dictionary();
				ret.parameters["*"] = _dataPath;
			}
			return ret;
		}
		
		public function get resolveSuccessful():Boolean{
			return _resolveSuccessful;
		}
		public function set resolveSuccessful(value:Boolean):void{
			_resolveSuccessful = value;
		}
		
		private var _resolveSuccessful:Boolean;
		private var _data:*;
		private var _dataPath:String;
		
		public function SetDefaultAppStateAct(stateId:String=null, parameters:Object=null){
			super(stateId, parameters);
		}
		public function get resolvePaths():Array{
			return _data?[]:[_dataPath];
		}
		public function set resolvedObjects(value:Dictionary):void{
			data = value[_dataPath];
		}
		
	}
}