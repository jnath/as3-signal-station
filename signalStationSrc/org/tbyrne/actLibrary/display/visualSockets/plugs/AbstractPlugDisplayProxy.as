package org.tbyrne.actLibrary.display.visualSockets.plugs
{
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.tbyrne.actLibrary.display.visualSockets.sockets.IDisplaySocket;
	import org.tbyrne.acting.actTypes.IAct;
	import org.tbyrne.acting.actTypes.IUniversalAct;
	import org.tbyrne.acting.acts.Act;
	import org.tbyrne.acting.acts.UniversalAct;
	import org.tbyrne.acting.universal.UniversalActExecution;
	import org.tbyrne.display.assets.nativeTypes.IDisplayObject;
	import org.tbyrne.display.core.DrawableView;
	import org.tbyrne.display.layout.ILayoutSubject;
	import org.tbyrne.display.layout.core.ILayoutInfo;
	
	public class AbstractPlugDisplayProxy implements ILayoutSubject, IPlugDisplay
	{
		public function get asset():IDisplayObject{
			return _asset;
		}
		public function set asset(value:IDisplayObject):void{
			if(_asset!=value){
				_asset = value;
				commitAsset();
			}
		}
		public function get display():IDisplayObject{
			return _asset;
		}
		
		public function get displaySocket():IDisplaySocket{
			return _displaySocket;
		}
		public function set displaySocket(value:IDisplaySocket):void{
			_displaySocket = value;
		}
		
		//TODO: these shouldn't be tied to _layoutTarget
		public function get position():Point{
			return _layoutTarget.position;
		}
		/**
		 * @inheritDoc
		 */
		public function get positionChanged():IAct{
			return _layoutTarget.positionChanged;
		}
		
		
		public function get size():Point{
			return _layoutTarget.size;
		}
		/**
		 * @inheritDoc
		 */
		public function get sizeChanged():IAct{
			return _layoutTarget.sizeChanged;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function get measurementsChanged():IAct{
			if(!_measurementsChanged)_measurementsChanged = new Act();
			return _measurementsChanged;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get displayChanged():IUniversalAct{
			if(!_displayChanged)_displayChanged = new UniversalAct();
			return _displayChanged;
		}
		
		protected var _displayChanged:UniversalAct;
		protected var _measurementsChanged:Act;
		protected var _oldMeasWidth:Number;
		protected var _oldMeasHeight:Number;
		
		protected var _dataProvider:*;
		protected var _displaySocket:IDisplaySocket;
		protected var _target:DrawableView;
		protected var _asset:IDisplayObject;
		protected var _layoutTarget:ILayoutSubject;
		
		public function AbstractPlugDisplayProxy(target:DrawableView=null){
			setTarget(target);
		}
		public function setDataProvider(value:*, execution:UniversalActExecution=null):void{
			if(_dataProvider!=value){
				if(_target && _dataProvider)uncommitData(execution);
				_dataProvider = value;
				if(_target && _dataProvider)commitData(execution);
			}
		}
		public function getDataProvider():*{
			return _dataProvider;
		}
		protected function setTarget(value:DrawableView):void{
			if(_target!=value){
				if(_target){
					if(_asset)_target.asset = null;
					if(_dataProvider)uncommitData();
					if(_layoutTarget){
						_layoutTarget.measurementsChanged.removeHandler(onLayoutMeasChange);
					}
				}
				_target = value;
				if(_target){
					if(_asset)_target.asset = _asset;
					_layoutTarget = value as ILayoutSubject;
					if(_layoutTarget){
						_layoutTarget.measurementsChanged.addHandler(onLayoutMeasChange);
						dispatchMeasurementChange();
					}
					if(_dataProvider)commitData();
					if(_displayChanged)_displayChanged.perform(this,display);
				}
			}
		}
		
		public function get measurements():Point{
			if(_layoutTarget){
				var meas:Point = _layoutTarget.measurements;
				_oldMeasWidth = meas.x;
				_oldMeasHeight = meas.y;
				return meas; 
			}else{
				_oldMeasWidth = NaN;
				_oldMeasHeight = NaN;
				return null;
			}
		}
		
		public function get layoutInfo():ILayoutInfo{
			return _layoutTarget?_layoutTarget.layoutInfo:null;
		}
		
		public function setPosition(x:Number, y:Number):void{
			if(_layoutTarget){
				_layoutTarget.setPosition(x, y);
			}
		}
		public function setSize(width:Number, height:Number):void{
			if(_layoutTarget){
				_layoutTarget.setSize(width, height);
			}
		}
		protected function commitAsset():void{
			if(_target)_target.asset = _asset;
		}
		protected function commitData(execution:UniversalActExecution=null):void{
			// override me
		}
		protected function uncommitData(execution:UniversalActExecution=null):void{
			// override me
		}
		protected function onLayoutMeasChange(from:ILayoutSubject, oldWidth:Number, oldHeight:Number):void{
			dispatchMeasurementChange();
		}
		protected function dispatchMeasurementChange():void{
			if(_measurementsChanged)_measurementsChanged.perform(this, _oldMeasWidth, _oldMeasHeight);
		} 
	}
}