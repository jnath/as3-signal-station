package org.farmcode.sodalityWebApp.appState.states
{
	import org.farmcode.sodalityWebApp.appState.AppStateMatch;

	public class LiteralAppState extends AbstractAppState
	{
		public var path:String;
		
		public function LiteralAppState(path:String=null){
			super();
			this.path = path;
		}
		override public function match(path:String):AppStateMatch{
			if(this.path==path){
				var ret:AppStateMatch = new AppStateMatch();
				ret.parameters = getBaseParams(path);
				return ret;
			}
			return null;
		}
	}
}