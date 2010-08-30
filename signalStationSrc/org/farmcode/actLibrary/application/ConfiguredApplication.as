package org.farmcode.actLibrary.application
{
	import flash.display.Sprite;
	
	import org.farmcode.actLibrary.core.UniversalActorHelper;
	import org.farmcode.actLibrary.errors.ErrorActor;
	import org.farmcode.actLibrary.external.config.ConfigActor;
	import org.farmcode.actLibrary.external.config.acts.SetPropertyConfigParamAct;
	import org.farmcode.actLibrary.external.siteStream.SiteStreamActor;
	import org.farmcode.actLibrary.external.siteStream.SiteStreamPhases;
	import org.farmcode.actLibrary.external.siteStream.acts.ResolvePathsAct;
	import org.farmcode.actLibrary.external.swfAddress.SWFAddressActor;
	import org.farmcode.acting.ActingNamspace;
	import org.farmcode.acting.actTypes.IUniversalAct;
	import org.farmcode.acting.universal.UniversalActExecution;
	import org.farmcode.acting.universal.UniversalActManager;
	import org.farmcode.core.Application;
	import org.farmcode.display.assets.assetTypes.IContainerAsset;
	import org.farmcode.display.assets.assetTypes.IDisplayAsset;
	import org.farmcode.display.core.IScopedObject;
	import org.farmcode.threading.AbstractThread;
	
	use namespace ActingNamspace;
	
	
	/**
	 * ConfiguredApplication adds the functionality to load a configuration file
	 * via SiteStream using Sodality.
	 */
	/*[SWF(width=1000, height=750, frameRate=30, backgroundColor="#ffffff")]
	[Frame(factoryClass="org.farmcode.display.progress.SimpleSWFPreloaderFrame")] */ // this must be on subclass
	public class ConfiguredApplication extends Application
	{
		protected static const CONFIG_URL_PARAM:String = "configUrl";
		
		public function get configURL():String{
			return _siteStreamActor.rootUrl;
		}
		public function set configURL(value:String):void{
			if(_siteStreamActor.rootUrl != value){
				_siteStreamActor.rootUrl = value;
				if(container){
					configUrlRetrieved();
				}
			}
		}
		override public function set container(value:IContainerAsset):void{
			super.container = value;
			if(value)checkScopeDisplay();
		}
		
		/**
		 * This is used so that apps can get SignalStation running
		 * before they get an asset.
		 */
		protected function get scopeDisplay():IDisplayAsset{
			if(!_scopeDisplay){
				_scopeDisplay = (asset || _container);
			}
			return _scopeDisplay;
		}
		
		protected var _scopeDisplay:IDisplayAsset;
		protected var _siteStreamActor:SiteStreamActor;
		protected var _configActor:ConfigActor;
		protected var _swfAddressActor:SWFAddressActor;
		protected var _appConfig:IAppConfig;
		
		protected var _universalActorHelper:UniversalActorHelper = new UniversalActorHelper();
		
		private var _configURL:String;
		
		private var _actors:Array = [];
		
		Config::DEBUG{
			protected var _debugArea:Sprite;
		}
		
		public function ConfiguredApplication(asset:IDisplayAsset=null){
			super(asset);
			_universalActorHelper.metadataTarget = this;
			_universalActorHelper.addChild(retrieveConfigUrlAct);
			_universalActorHelper.addChild(retrieveConfigAct);
			_universalActorHelper.addedChanged.addTempHandler(onAdded);
			
			_siteStreamActor = new SiteStreamActor();
			addActor(_siteStreamActor);
			
			_swfAddressActor = new SWFAddressActor();
			addActor(_swfAddressActor);
			
			_configActor = new ConfigActor();
			setDefaultConfig("configURL","xml/config.xml");
			setDefaultConfig("baseDataURL","");
			setDefaultConfig("baseClassURL","");
			addActor(_configActor);
			
			var errorActor:ErrorActor = new ErrorActor();
			addActor(errorActor);
		}
		protected function onAdded(from:UniversalActorHelper) : void{
			attemptInit();
		}
		override protected function commitStage() : void{
			super.commitStage();
			if(isNaN(AbstractThread.intendedFPS)){
				AbstractThread.intendedFPS = _lastStage.frameRate;
			}
		}
		protected function checkScopeDisplay():void{
			if(!_universalActorHelper.asset){
				UniversalActManager.addManager(scopeDisplay);
				_universalActorHelper.asset = scopeDisplay;
			}
		}
		override protected function init():void{
			super.init();
			
			var act:SetPropertyConfigParamAct = new SetPropertyConfigParamAct(_siteStreamActor,"baseDataURL","baseDataURL");
			act.temporaryPerform(scopeDisplay);
			
			act = new SetPropertyConfigParamAct(_siteStreamActor,"baseClassURL","baseClassURL");
			act.temporaryPerform(scopeDisplay);
			
			if(configURL){
				configUrlRetrieved();
			}else{
				retrieveConfigUrlAct.perform();
			}
		}
		protected function setDefaultConfig(name:String, value:String) : void{
			if(_configActor)_configActor.defaultConfigs[name] = value;
			else if(_lastStage){
				if(!_lastStage.loaderInfo.parameters[name])
					_lastStage.loaderInfo.parameters[name] = value;
			}else{
				throw new Error("Can't set default config values yet");
			}
		}
		protected function addActor(actor:IScopedObject) : void{
			_universalActorHelper.addChild(actor);
		}
		override protected function unbindFromAsset() : void{
			super.unbindFromAsset();
			
			if(!_scopeDisplay!=container){
				_universalActorHelper.asset = null;
				UniversalActManager.removeManager(_scopeDisplay);
				_scopeDisplay = null;
			}
		}
		
		public var retrieveConfigUrlAct:SetPropertyConfigParamAct = new SetPropertyConfigParamAct(this,"configURL",CONFIG_URL_PARAM);
		public function configUrlRetrieved(): void{
			retrieveConfigAct.perform();
		}
		
		public var retrieveConfigAct:ResolvePathsAct = new ResolvePathsAct([""]);
		public var loadConfigAfterPhases:Array = [SiteStreamPhases.RESOLVE_PATHS];
		[ActRule(ActInstanceRule,act="{retrieveConfigAct}",afterPhases="{loadConfigAfterPhases}")]
		public function onConfigRetrieved(execution:UniversalActExecution, cause:ResolvePathsAct): void{
			setRootObject(execution,cause.resolvedObjects[cause.resolvePaths[0]]);
			execution.continueExecution();
		}
		protected function setRootObject(execution:UniversalActExecution, object:Object):void{
			_appConfig = (object as IAppConfig);
			
			if(!asset && _appConfig.assetFactory){
				asset = _appConfig.assetFactory.getCoreSkin(getCoreSkinName()) as IDisplayAsset;
			}
			
			var act:IUniversalAct;
			if(_appConfig.initActs){
				for(var i:int=0; i<_appConfig.initActs.length; i++){
					temporaryPerformAct(_appConfig.initActs[i],execution);
				}
			}
			if(!isNaN(_appConfig.applicationScale))applicationScale = _appConfig.applicationScale;
		}
		protected function getCoreSkinName():String{
			throw new Error("getCoreSkinName should be overriden");
		}
		protected function temporaryPerformAct(act:IUniversalAct, execution:UniversalActExecution):void{
			act.scope = asset;
			act.perform(execution);
			act.scope = null;
		}
	}
}
import org.farmcode.acting.universal.rules.ActClassRule;
import org.farmcode.acting.universal.rules.ActInstanceRule;

class ClassIncluder{
	public function ClassIncluder(){
		var includeClass:Class;
		includeClass = ActClassRule;
		includeClass = ActInstanceRule;
	}
}