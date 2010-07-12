package org.farmcode.actLibrary.application
{
	import flash.display.DisplayObjectContainer;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	
	import org.farmcode.actLibrary.display.visualSockets.VisualSocketActor;
	import org.farmcode.actLibrary.display.visualSockets.VisualSocketNamespace;
	import org.farmcode.actLibrary.display.visualSockets.debug.VisualSocketOutliner;
	import org.farmcode.actLibrary.display.visualSockets.plugs.IPlugDisplay;
	import org.farmcode.actLibrary.display.visualSockets.sockets.DisplaySocket;
	import org.farmcode.actLibrary.display.visualSockets.sockets.IDisplaySocket;
	import org.farmcode.actLibrary.external.browser.BrowserActor;
	import org.farmcode.acting.actTypes.IAct;
	import org.farmcode.acting.acts.Act;
	import org.farmcode.acting.universal.UniversalActExecution;
	import org.farmcode.display.assets.IDisplayAsset;
	import org.farmcode.display.assets.IInteractiveObjectAsset;
	import org.farmcode.display.assets.nativeAssets.NativeAssetFactory;
	
	use namespace VisualSocketNamespace;
	
	/*[SWF(width=1000, height=750, frameRate=30, backgroundColor="#ffffff")]
	[Frame(factoryClass="org.farmcode.display.progress.SimpleSWFPreloaderFrame")] */ // this must be on subclass
	public class VisualSocketApplication extends StateApplication implements IDisplaySocket
	{
		
		/**
		 * @inheritDoc
		 */
		public function get plugDisplayChanged():IAct{
			if(!_plugDisplayChanged)_plugDisplayChanged = new Act();
			return _plugDisplayChanged;
		}
		
		
		override public function set container(value:DisplayObjectContainer) : void{
			super.container = value;
			_proxiedDisplaySocket.container = NativeAssetFactory.getNew(value);
		}
		public function get socketId(): String{
			return _proxiedDisplaySocket.socketId;
		}
		public function get plugMappers(): Array{
			return _proxiedDisplaySocket.plugMappers;
		}
		public function get globalPosition(): Rectangle{
			return _proxiedDisplaySocket.globalPosition;
		}
		public function get plugDisplay():IPlugDisplay{
			return _proxiedDisplaySocket.plugDisplay;
		}
		public function set plugDisplay(value:IPlugDisplay):void{
			_proxiedDisplaySocket.plugDisplay = value;
		}
		public function set socketPath(value:String):void{
			_proxiedDisplaySocket.socketPath = value;
		}
		public function get socketPath():String{
			return _proxiedDisplaySocket.socketPath;
		}
		override public function get measurementsChanged() : IAct{
			return _proxiedDisplaySocket.measurementsChanged;
		}
		override public function get displayMeasurements() : Rectangle{
			return _proxiedDisplaySocket.displayMeasurements;
		}
		
		protected var _visSocketActor:VisualSocketActor;
		protected var _config:IVisualSocketAppConfig;
		protected var _proxiedDisplaySocket:DisplaySocket;
		protected var _plugDisplayChanged:Act;
		
		public function VisualSocketApplication(asset:IDisplayAsset=null){
			super(asset);
			_proxiedDisplaySocket = new DisplaySocket("");
			_proxiedDisplaySocket.displayDepth = 0;// forces app to lowest level, allowing debug bar to sit at top.
			_proxiedDisplaySocket.plugDisplayChanged.addHandler(onPlugDisplayChanged);
			_proxiedDisplaySocket.measurementsChanged
		}
		protected function onPlugDisplayChanged(from:DisplaySocket):void{
			_plugDisplayChanged.perform(this);
		}
		override public function removeMainDisplay():void{
			super.removeMainDisplay();
			_proxiedDisplaySocket.container = null;
		}
		override public function addMainDisplay():void{
			super.addMainDisplay();
			_proxiedDisplaySocket.container = _asset.parent;
		}
		override public function setDisplayPosition(x:Number, y:Number, width:Number, height:Number) : void{
			super.setDisplayPosition(x, y, width, height);
			_proxiedDisplaySocket.setDisplayPosition(x, y, width, height);
		}
		override protected function init():void{
			super.init();
			
			_visSocketActor = new VisualSocketActor();
			_visSocketActor.rootSocket = this;
			_universalActorHelper.addChild(_visSocketActor);
			
			var browserActor:BrowserActor = new BrowserActor();
			_universalActorHelper.addChild(browserActor);
			
			Config::DEBUG
			{
				var onKeyDown:Function = function(e:KeyboardEvent, from:IInteractiveObjectAsset):void{
					if(e.ctrlKey && e.altKey){
						if(e.keyCode==79)VisualSocketOutliner.outlineSocket(_debugArea.graphics,_visSocketActor.rootSocketBundle);		// o
					}
				}
				_lastStage.keyDown.addHandler(onKeyDown);
			}
		}
		override protected function setRootObject(execution:UniversalActExecution, object:Object):void{
			_config = object as IVisualSocketAppConfig;
			_visSocketActor.rootDataMappers = _config.rootDataMappers;
			super.setRootObject(execution, object);
		}
	}
}