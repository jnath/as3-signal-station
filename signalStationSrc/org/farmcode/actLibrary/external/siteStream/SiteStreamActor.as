package org.farmcode.actLibrary.external.siteStream
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import org.farmcode.actLibrary.core.UniversalActorHelper;
	import org.farmcode.actLibrary.errors.ErrorDetails;
	import org.farmcode.actLibrary.errors.acts.ErrorAct;
	import org.farmcode.actLibrary.external.siteStream.actTypes.*;
	import org.farmcode.actLibrary.external.siteStream.errors.SiteStreamErrors;
	import org.farmcode.acting.ActingNamspace;
	import org.farmcode.acting.universal.UniversalActExecution;
	import org.farmcode.acting.universal.phases.LogicPhases;
	import org.farmcode.acting.universal.phases.ObjectPhases;
	import org.farmcode.siteStream.SiteStream;
	import org.farmcode.siteStream.events.SiteStreamErrorEvent;
	
	use namespace ActingNamspace;

	public class SiteStreamActor extends UniversalActorHelper
	{
		public var lookupObjectPhases:Array = [SiteStreamPhases.LOOKUP_OBJECT];
		public var resolvePathsPhases:Array = [SiteStreamPhases.RESOLVE_PATHS,ObjectPhases.REFERENCE_RESOLVED,LogicPhases.PROCESS_COMMAND];
		public var releasePathPhases:Array = [SiteStreamPhases.RELEASE_PATH];
		public var releaseObjectPhases:Array = [SiteStreamPhases.RELEASE_OBJECT];
		
		public function get rootUrl():String{
			return siteStream.rootURL;
		}
		public function set rootUrl(value:String):void{
			if(value!=siteStream.rootURL){
				siteStream.rootURL = value;
			}
		}
		public function get baseUrl():String{
			if(siteStream.baseClassURL==siteStream.baseDataURL){
				return siteStream.baseClassURL;
			}else{
				return null;
			}
		}
		public function set baseUrl(value:String):void{
			siteStream.baseClassURL = value;
			siteStream.baseDataURL = value;
		}
		public function get baseDataURL():String{
			return siteStream.baseDataURL;
		}
		public function set baseDataURL(value:String):void{
			siteStream.baseDataURL = value;
		}
		public function get baseClassURL():String{
			return siteStream.baseClassURL;
		}
		public function set baseClassURL(value:String):void{
			siteStream.baseClassURL = value;
		}
		public function get siteStream():SiteStream{
			return _siteStream;
		}
		
		protected function get errorAct():ErrorAct{
			if(!_errorAct){
				_errorAct = new ErrorAct();
				addChild(_errorAct);
			}
			return _errorAct;
		}
		private var _errorAct:ErrorAct;
		
		protected var _baseUrl:String = "";
		protected var _siteStream:SiteStream;
		protected var loadRequests: Dictionary;
		
		public function SiteStreamActor(){
			metadataTarget = this;
			
			this.loadRequests = new Dictionary();
			_siteStream = this.createSiteStream();
			_siteStream.addEventListener(SiteStreamErrorEvent.CLASS_FAILURE, onClassFailure);
			_siteStream.addEventListener(SiteStreamErrorEvent.DATA_FAILURE, onDataFailure);
		}
		protected function onClassFailure(e:SiteStreamErrorEvent):void{
			errorAct.perform(null,this,SiteStreamErrors.CLASS_ERROR,new ErrorDetails(e.text));
		}
		protected function onDataFailure(e:SiteStreamErrorEvent):void{
			errorAct.perform(null,this,SiteStreamErrors.DATA_ERROR,new ErrorDetails(e.text));
		}
		protected function createSiteStream():SiteStream{
			var ret:SiteStream = new SiteStream();
			return ret;
		}
		
		[ActRule(ActClassRule)]
		[ActReaction(phases="{lookupObjectPhases}")]
		public function lookupObject(cause:ILookupObjectPathAct):void{
			if(cause.lookupObject)cause.lookupObjectPath = siteStream.getPath(cause.lookupObject);
		}
		[ActRule(ActClassRule)]
		[ActReaction(phases="{resolvePathsPhases}")]
		public function resolvePaths(execution:UniversalActExecution, cause:IResolvePathsAct):void{
			var request: LoadRequest = this.loadRequests[cause];
			if (request){
				request.addExecution(execution);
				return;
			}else{
				var loadBundles:Array = [];
				for each(var path:String in cause.resolvePaths){
					if(path!=null){
						loadBundles.push(new LoadBundle(path));
					}
				}
				if(loadBundles.length){
					request = new LoadRequest(execution, cause, loadBundles, this);
					this.loadRequests[cause] = request;
					request.startLoad();
					return;
				}
			}
			execution.continueExecution();
		}
		
		
		public function disposeRequest(request: LoadRequest): void
		{
			var cause:IResolvePathsAct = request.cause;
			request.dispose();
			delete this.loadRequests[cause];
		}
		[ActRule(ActClassRule)]
		[ActReaction(phases="{releasePathPhases}")]
		public function releasePath(cause:IReleasePathAct):void{
			siteStream.releaseObject(cause.releasePath);
		}
		[ActRule(ActClassRule)]
		[ActReaction(phases="{releaseObjectPhases}")]
		public function releaseObject(cause:IReleaseObjectAct):void{
			var path:String = siteStream.getPath(cause.releaseObject);
			if(path)siteStream.releaseObject(path);
		}
	}
}

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.Dictionary;

import org.farmcode.actLibrary.external.siteStream.SiteStreamActor;
import org.farmcode.actLibrary.external.siteStream.actTypes.IResolvePathsAct;
import org.farmcode.acting.universal.UniversalActExecution;
import org.farmcode.siteStream.SiteStream;

class LoadRequest
{
	public var parent:SiteStreamActor;
	public var executions: Array;
	public var cause:IResolvePathsAct;
	protected var loadBundles: Array;
	protected var currentBundle:LoadBundle;
	protected var currentLoadIndex: uint;
	
	public function LoadRequest(execution:UniversalActExecution, cause: IResolvePathsAct, loadBundles:Array, parent:SiteStreamActor){
		this.executions = [execution];
		this.cause = cause;
		this.parent = parent;
		this.loadBundles = loadBundles;
	}
	
	public function startLoad(): void
	{
		currentLoadIndex = 0;
		loadNextBundle();
	}
	private function loadNextBundle(): void
	{
		if(currentLoadIndex<loadBundles.length){
			var bundle: LoadBundle = loadBundles[currentLoadIndex];
			bundle.addEventListener(Event.COMPLETE, this.handleBundleCompleteEvent);
			bundle.load(this.parent.siteStream);
		}else{
			this.complete();
		}
	}
	
	public function addExecution(execution:UniversalActExecution): void{
		if (this.executions.indexOf(execution) < 0){
			this.executions.push(execution);
		}
	}
		
	protected function handleBundleCompleteEvent(event: Event): void{
		currentLoadIndex++;
		var targetBundle: LoadBundle = event.target as LoadBundle;
		targetBundle.removeEventListener(Event.COMPLETE, this.handleBundleCompleteEvent);
		
		cause.resolveSuccessful = targetBundle.success;
		loadNextBundle();
	}
	
	public function complete(): void{
		// TODO: Dispose self and dispatch event instead
		var result:Dictionary = new Dictionary();
		for each(var bundle: LoadBundle in loadBundles){
			if(bundle.success){
				result[bundle.path] = bundle.result;
			}
		}
		cause.resolvedObjects = result;
		
		// sometimes dispose gets called as a result of continuing act, so we need a copy of the array
		var executions:Array = this.executions.slice();
		for (var i: uint = 0; i < executions.length; ++i){
			var execution: UniversalActExecution = executions[i];
			execution.continueExecution();
		}
		this.parent.disposeRequest(this);
	}
	
	public function dispose(): void{
		this.parent = null;
		this.cause = null;
		this.executions = null;
		this.loadBundles = null;
	}
}

[Event(type="flash.events.Event", name="complete")]
class LoadBundle extends EventDispatcher
{
	public var path:String;
	public var success: Boolean;
	private var _result:*;
	
	public function LoadBundle(path:String){
		this.path = path;
	}
	
	public function get result():*{
		return _result;
	}
	
	public function load(siteStream: SiteStream): void{
		siteStream.getObject(path, onItemLoad);
	}
		
	protected function onItemLoad(content:Object):void{
		success = true;
		_result = content;
		dispatchCompleteEvent();
	}
	
	protected function dispatchCompleteEvent(): void{
		dispatchEvent(new Event(Event.COMPLETE));
	}
}