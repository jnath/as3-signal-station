package org.tbyrne.actLibrary.application.states.states
{
	import org.tbyrne.actLibrary.application.states.AppStateConstants;
	import org.tbyrne.actLibrary.application.states.AppStateMatch;

	public class AppState extends RegExpAppState
	{
		public function AppState(stateId:String=null, statePath:String=null){
			super(stateId, statePath);
		}
		override protected function getStripPattern(path:String) : String{
			var regExpStr:String = super.getStripPattern(path);
			regExpStr = regExpStr.replace(AppStateConstants.STAR_MATCHER,AppStateConstants.STAR_REPLACE);
			regExpStr = regExpStr.replace(AppStateConstants.LABEL_MATCHER,AppStateConstants.LABEL_REPLACE);
			regExpStr = regExpStr.replace(AppStateConstants.START_MATCHER,AppStateConstants.START_REPLACE);
			regExpStr = regExpStr.replace(AppStateConstants.END_MATCHER,AppStateConstants.END_REPLACE);
			return regExpStr;
		}
		override public function reconstitute(match:AppStateMatch):String{
			var ret:String = path;
			for(var prop:String in match.parameters){
				if(prop=="*"){
					ret = ret.replace(AppStateConstants.STAR_MATCHER,match.parameters[prop]);
				}else{
					var matchStr:String = AppStateConstants.LABEL_RECON.replace("$name",prop);
					var matcher:RegExp = new RegExp(matchStr);
					var replaceWith:String = match.parameters[prop];
					if(replaceWith==null)replaceWith = "";
					var replaceStr:String = AppStateConstants.LABEL_RECON_REPLACE.replace("$value",replaceWith);
					ret = ret.replace(matcher,replaceStr);
				}
			}
			ret = ret.replace(AppStateConstants.START_MATCHER,"/");
			ret = ret.replace(AppStateConstants.END_MATCHER,"/");
			return ret;
		}
	}
}