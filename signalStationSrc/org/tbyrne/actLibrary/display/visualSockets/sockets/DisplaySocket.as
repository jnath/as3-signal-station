package org.tbyrne.actLibrary.display.visualSockets.sockets
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import org.tbyrne.actLibrary.display.visualSockets.mappers.IPlugMapper;
	import org.tbyrne.actLibrary.display.visualSockets.plugs.IPlugDisplay;
	import org.tbyrne.acting.actTypes.IAct;
	import org.tbyrne.acting.acts.Act;
	import org.tbyrne.core.DelayedCall;
	import org.tbyrne.display.assets.assetTypes.IAsset;
	import org.tbyrne.display.assets.nativeTypes.IDisplayObjectContainer;
	import org.tbyrne.display.assets.nativeTypes.IDisplayObject;
	import org.tbyrne.display.core.IOutroView;
	import org.tbyrne.display.core.IScopedObject;
	import org.tbyrne.display.core.IView;
	import org.tbyrne.display.layout.ILayoutSubject;
	import org.tbyrne.display.layout.LayoutSubject;
	import org.tbyrne.display.layout.core.ILayoutInfo;

	public class DisplaySocket extends LayoutSubject implements IDisplaySocket, ILayoutSubject, IView
	{
		
		/**
		 * @inheritDoc
		 */
		public function get assetChanged():IAct{
			if(!_assetChanged)_assetChanged = new Act();
			return _assetChanged;
		}
		/**
		 * @inheritDoc
		 */
		public function get plugDisplayChanged():IAct{
			if(!_plugDisplayChanged)_plugDisplayChanged = new Act();
			return _plugDisplayChanged;
		}
		
		protected var _plugDisplayChanged:Act;
		protected var _assetChanged:Act;
		
		protected var _oldMeasWidth:Number;
		protected var _oldMeasHeight:Number;
		
		private var _socketId: String;
		private var _socketPath: String;
		private var _displayDepth: int = -1;
		private var _plugMappers: Array;
		private var _scopeDisplayMappers: Array;
		private var _plugDisplay: IPlugDisplay;
		private var _container:IDisplayObjectContainer;
		private var _displayPosition:Rectangle = new Rectangle();
		private var _introOutroOverlap:Number = 0;
		private var _outroBegunAt:Number;
		private var _outroLength:Number;
		
		private var _lastDisplayObject:IDisplayObject;
		private var _lastParent:IDisplayObjectContainer;
		private var _lastDepth:int;

		public function DisplaySocket(socketId: String = null, container:IDisplayObjectContainer=null, plugMappers:Array=null){
			this.socketId = socketId;
			this.container = container;
			this.plugMappers = plugMappers;
		}
		public function get asset():IDisplayObject{
			return _container;
		}
		/*
		globalPosition is currently only used for debugging and is therefore not optimised.
		*/
		public function get globalPosition():Rectangle{
			var tl:Point = _container.localToGlobal(_displayPosition.topLeft);
			var br:Point = _container.localToGlobal(_displayPosition.bottomRight);
			return new Rectangle(tl.x,tl.y,br.x-tl.x,br.y-tl.y);
		}
		
		public function get socketId(): String{
			return this._socketId;
		}
		public function set socketId(value: String): void{
			this._socketId = value;
		}
		public function get socketPath(): String{
			return this._socketPath;
		}
		public function set socketPath(value: String): void{
			this._socketPath = value;
		}
		public function get displayDepth(): int{
			return this._displayDepth;
		}
		public function set displayDepth(value: int): void{
			if(_displayDepth != value){
				this._displayDepth = value;
				if(value!=-1 && _container && _plugDisplay){
					_container.setAssetIndex(_plugDisplay.display,value);
				}
			}
		}
		
		[Property(toString="true",clonable="true")]
		public function get introOutroOverlap():Number{
			return _introOutroOverlap;
		}
		public function set introOutroOverlap(value:Number):void{
			_introOutroOverlap = value;
		}
		
		[Property(toString="true", clonable="true")]
		public function get plugMappers(): Array{
			return this._plugMappers;
		}
		//TODO:should all plugMappers be IScopeDisplayObjects
		public function set plugMappers(value: Array): void{
			for each(var scopeDisp:IScopedObject in _scopeDisplayMappers){
				if(scopeDisp.scope==container)scopeDisp.scope = null;
			}
			this._plugMappers = value;
			_scopeDisplayMappers = [];
			for each(var mapper:IPlugMapper in _plugMappers){
				var cast:IScopedObject = (mapper as IScopedObject);
				if(cast && !cast.scope){
					cast.scope = container;
					_scopeDisplayMappers.push(cast);
				}
			}
			
		}
		[Property(toString="true", clonable="true")]
		public function get container(): IDisplayObjectContainer{
			return _container;
		}
		public function set container(value: IDisplayObjectContainer): void{
			var depth:int = _displayDepth;
			if (_plugDisplay && _container){
				var remDepth:int = removeDisplay(_plugDisplay);
				if(depth==-1){
					depth = remDepth;
				}
			}
			var oldAsset:IAsset = _container;
			_container = value;
			if (_plugDisplay && _container){
				addDisplay(_plugDisplay.display, depth);
			}
			for each(var scopeDisp:IScopedObject in _scopeDisplayMappers){
				scopeDisp.scope = value;
			}
			if(_assetChanged)_assetChanged.perform(this,oldAsset);
		}
		[Property(toString="true", clonable="true")]
		public function get plugDisplay(): IPlugDisplay{
			return _plugDisplay;
		}
		public function set plugDisplay(value: IPlugDisplay): void{
			if(_plugDisplay!=value){
				var depth:int = _displayDepth;
				if (_plugDisplay){
					if(_plugDisplay.displaySocket==this){
						_plugDisplay.displaySocket = null;
					}
					if(_container && isNaN(_outroBegunAt)){
						var remDepth:int = removeDisplay(_plugDisplay);
						if(depth==-1){
							depth = remDepth;
						}
					}else if(_lastParent){
						_lastParent.addAssetAt(_plugDisplay.display,_lastDepth);
					}
					
					_plugDisplay.displayChanged.removeHandler(onDisplayChanged);
					_plugDisplay.measurementsChanged.removeHandler(onPlugMeasChanged);
				}
				_plugDisplay = value;
				if (_plugDisplay){
					_plugDisplay.displaySocket = this; // this must be done before adding to stage
					_lastParent = _plugDisplay.display.parent;
					if(_lastParent){
						_lastDepth = _lastParent.getAssetIndex(_plugDisplay.display);
					}
					// call setDisplayPosition before adding the plugDisplay to stage so that it has the correct position for transitioning.
					_plugDisplay.setPosition(_displayPosition.x,_displayPosition.y);
					_plugDisplay.setSize(_displayPosition.x,_displayPosition.y);
					if(_container){
						addDisplayAfterDelay(_plugDisplay,depth);
					}
					_plugDisplay.displayChanged.addHandler(onDisplayChanged);
					_plugDisplay.measurementsChanged.addHandler(onPlugMeasChanged);
				}
				if(_plugDisplayChanged)_plugDisplayChanged.perform(this);
				invalidateMeasurements();
			}
		}
		public function get layoutDisplay():IDisplayObject{
			return _plugDisplay?_plugDisplay.display:null;
		}
		override protected function measure():void{
			var meas:Point = _plugDisplay.measurements;
			if(meas){
				_measurements.x = meas.x;
				_measurements.y = meas.y;
			}else{
				_measurements.x = NaN;
				_measurements.y = NaN;
			}
		}
		override protected function commitPos():void{
			if(_plugDisplay)_plugDisplay.setPosition(_position.x,_position.y);
		}
		override protected function commitSize():void{
			if(_plugDisplay)_plugDisplay.setSize(_size.x,_size.y);
		}
		protected function onPlugMeasChanged(from:ILayoutSubject, oldWidth:Number, oldHeight:Number):void{
			invalidateMeasurements();
		}
		protected function onDisplayChanged(from:IPlugDisplay, oldDisplay:DisplayObject, newDisplay:DisplayObject):void{
			completeRemoveDisplay(_lastDisplayObject, _container, _lastParent, _lastDepth);
			_lastParent = _plugDisplay.display.parent;
			if(_lastParent)_lastDepth = _lastParent.getAssetIndex(_plugDisplay.display);
			else _lastDepth = -1;
			addDisplay(_plugDisplay.display, _displayDepth);
		}
		protected function removeDisplay(plugDisplay:IPlugDisplay):int{
			var depth:int = _container.getAssetIndex(plugDisplay.display);
			var cast:IOutroView = plugDisplay as IOutroView;
			if(cast){
				_outroLength = cast.showOutro();
				if(_outroLength){
					_outroBegunAt = getTimer()/1000;
					var delayedCall:DelayedCall = new DelayedCall(completeRemoveDisplay,_outroLength,true,[plugDisplay.display,_container,_lastParent,_lastDepth]);
					delayedCall.begin();
				}else{
					completeRemoveDisplay(plugDisplay.display,_container,_lastParent,_lastDepth);
				}
			}else{
				completeRemoveDisplay(plugDisplay.display,_container,_lastParent,_lastDepth);
			}
			return depth;
		}
		protected function completeRemoveDisplay(displayObject:IDisplayObject, container:IDisplayObjectContainer, originalParent:IDisplayObjectContainer, originalDepth:int):void{
			_outroBegunAt = NaN;
			if(originalParent){
				originalParent.addAssetAt(displayObject,originalDepth); 
			}else{
				container.removeAsset(displayObject);
			}
		}
		private var addDelay:DelayedCall;
		protected function addDisplayAfterDelay(plugDisplay:IPlugDisplay, depth:int):void{
			if(addDelay){
				addDelay.clear();
				addDelay = null;
			}
			if(!isNaN(_outroBegunAt)){
				var time:Number = (getTimer()/1000);
				var currentPos:Number = time-_outroBegunAt;
				var introPos:Number = (_introOutroOverlap!=1)?(_outroLength*(1-_introOutroOverlap)):0;
				if(currentPos<introPos){
					addDelay = new DelayedCall(addDisplay,introPos-currentPos,true,[plugDisplay.display,depth]);
					addDelay.begin();
					return;
				}
			}
			addDisplay(plugDisplay.display, depth);
		}
		protected function addDisplay(displayObject:IDisplayObject, depth:int):void{
			addDelay = null;
			_outroBegunAt = NaN;
			_lastDisplayObject = displayObject;
			if(_lastDisplayObject.parent!=_container){
				if(depth==-1)_container.addAsset(_lastDisplayObject);
				else _container.addAssetAt(_lastDisplayObject,depth);
			}else if(_container.getAssetIndex(_lastDisplayObject)!=depth && depth!=-1){
				_container.setAssetIndex(_lastDisplayObject,depth);
			}
		}
	}
}