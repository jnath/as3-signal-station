package org.farmcode.display.containers
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.farmcode.display.DisplayNamespace;
	import org.farmcode.display.assets.AssetNames;
	import org.farmcode.display.assets.assetTypes.IContainerAsset;
	import org.farmcode.display.assets.assetTypes.IDisplayAsset;
	import org.farmcode.display.constants.Direction;
	import org.farmcode.display.controls.ScrollBar;
	import org.farmcode.display.controls.TextLabelButton;
	import org.farmcode.display.core.DrawableView;
	import org.farmcode.display.core.ILayoutView;
	import org.farmcode.display.layout.ILayoutSubject;
	import org.farmcode.display.layout.grid.RendererGridLayout;
	import org.farmcode.display.scrolling.IScrollMetrics;
	import org.farmcode.display.scrolling.IScrollable;
	import org.farmcode.display.scrolling.ScrollMultiplier;
	import org.farmcode.display.scrolling.ScrollWheelScroller;
	import org.farmcode.instanceFactory.IInstanceFactory;
	import org.farmcode.instanceFactory.MultiInstanceFactory;
	import org.farmcode.instanceFactory.SimpleInstanceFactory;
	
	use namespace DisplayNamespace;
	
	public class AbstractList extends ContainerView implements IScrollable
	{
		DisplayNamespace const ASSUMED_DATA_FIELD:String = "data";
		
		DisplayNamespace function get assumedRendererFactory():SimpleInstanceFactory{
			return _assumedRendererFactory;
		}
		DisplayNamespace function get layout():RendererGridLayout{
			return _layout;
		}
		
		public function get rendererFactory():IInstanceFactory{
			return _rendererFactory;
		}
		public function set rendererFactory(value:IInstanceFactory):void{
			if(_rendererFactory != value){
				if(_factoryAssumedAssetSet){
					(_rendererFactory as MultiInstanceFactory).removeProperties(_factoryAssumedAssetProps);
					_factoryAssumedAssetSet = false;
				}
				_rendererFactory = value;
				assessFactory();
			}
		}
		
		public function get hideScrollBarWhenUnusable():Boolean{
			return _hideScrollBarWhenUnusable;
		}
		public function set hideScrollBarWhenUnusable(value:Boolean):void{
			if(_hideScrollBarWhenUnusable != value){
				_hideScrollBarWhenUnusable = value;
				if(_scrollBar){
					_scrollBar.hideWhenUnusable = _hideScrollBarWhenUnusable;
				}
			}
		}
		
		protected var _hideScrollBarWhenUnusable:Boolean = true;
		protected var _dataField:String;
		protected var _rendererFactory:IInstanceFactory;
		protected var _scrollBar:ScrollBar;
		protected var _layout:RendererGridLayout;
		protected var _container:IContainerAsset;
		protected var _scrollBarShown:Boolean;
		
		protected var _assumedRendererAsset:IDisplayAsset;
		protected var _assumedAssetFactory:IInstanceFactory;
		protected var _assumedRendererFactory:SimpleInstanceFactory;
		protected var _scrollRect:Rectangle = new Rectangle();
		protected var _scrollMetrics:IScrollMetrics;
		protected var _mouseWheelScroller:ScrollWheelScroller;
		
		protected var _factoryAssumedAssetSet:Boolean;
		protected var _factoryAssumedAssetProps:Dictionary;
		
		private var _horScrollMetrics:IScrollMetrics;
		private var _verScrollMetrics:IScrollMetrics;
		
		protected var _renderers:Array = [];
		
		public function AbstractList(asset:IDisplayAsset=null){
			super(asset);
		}
		override protected function init() : void{
			super.init();
			createLayout();
			_layout.measurementsChanged.addHandler(onLayoutMeasChange);
			_layout.addRendererAct.addHandler(onAddRenderer);
			_layout.removeRendererAct.addHandler(onRemoveRenderer);
			
			_mouseWheelScroller = new ScrollWheelScroller();
		}
		protected function createLayout() : void{
			_layout = new RendererGridLayout(this);
		}
		override protected function bindToAsset() : void{
			super.bindToAsset();
			var scrollBarAsset:IDisplayAsset = _containerAsset.takeAssetByName(AssetNames.SCROLL_BAR,IDisplayAsset,true);
			if(scrollBarAsset){
				if(!_scrollBar){
					_scrollBar = new ScrollBar();
					_scrollBar.hideWhenUnusable = _hideScrollBarWhenUnusable;
				}
				_scrollBar.asset = scrollBarAsset;
				_scrollBar.scrollSubject = this;
				setScrollBarMetrics(_layout.getScrollMetrics(_scrollBar.direction));
			}
			_assumedRendererAsset = _containerAsset.takeAssetByName(assumedRendererAssetName(),IDisplayAsset,true);
			if(_assumedRendererAsset){
				_containerAsset.removeAsset(_assumedRendererAsset);
				assessFactory();
			}
			_container = _containerAsset.factory.createContainer();
			_containerAsset.addAsset(_container);
			
			var wheelDirection:String;
			if(scrollBarAsset){
				wheelDirection = _scrollBar.direction;
			}else if(_layout.pixelFlow){
				wheelDirection = (_layout.flowDirection==Direction.HORIZONTAL?Direction.VERTICAL:Direction.VERTICAL);
			}else{
				wheelDirection = _layout.flowDirection;
			}
			_mouseWheelScroller.scrollMetrics = getScrollMetrics(wheelDirection);
			_mouseWheelScroller.display = _interactiveObjectAsset;
		}
		protected function setScrollBarMetrics(scrollMetrics:IScrollMetrics):void{
			if(_scrollMetrics!=scrollMetrics){
				if(_scrollMetrics){
					_scrollMetrics.scrollMetricsChanged.removeHandler(onScrollMetricsChanged);
				}
				_scrollMetrics = scrollMetrics;
				if(_scrollMetrics){
					_scrollMetrics.scrollMetricsChanged.addHandler(onScrollMetricsChanged);
				}
				invalidateMeasurements();
				invalidateSize();
			}
		}
		protected function onScrollMetricsChanged(from:IScrollMetrics) : void{
			invalidateMeasurements();
			invalidateSize();
		}
		protected function assumedRendererAssetName() : String{
			return AssetNames.LIST_ITEM;
		}
		override protected function unbindFromAsset() : void{
			super.unbindFromAsset();
			if(_scrollBar && _scrollBar.asset){
				_containerAsset.returnAsset(_scrollBar.asset);
				_scrollBar.asset = null;
			}
			if(_assumedRendererAsset){
				_containerAsset.addAsset(_assumedRendererAsset);
				_containerAsset.returnAsset(_assumedRendererAsset);
				_assumedRendererAsset = null;
				
				if(_assumedAssetFactory){
					_assumedAssetFactory = null;
				}
				if(_assumedRendererFactory){
					_assumedRendererFactory.instanceProperties = null;
					_assumedRendererFactory = null;
					assessFactory();
				}
			}
			_containerAsset.removeAsset(_container);
			_containerAsset.factory.destroyAsset(_container);
			_container = null;
			
			_mouseWheelScroller.display = null;
		}
		protected function onLayoutMeasChange(from:ILayoutSubject, oldWidth:Number, oldHeight:Number) : void{
			invalidateMeasurements();
		}
		protected function onAddRenderer(layout:RendererGridLayout, renderer:ILayoutView) : void{
			_renderers.push(renderer.asset);
			if(_container){
				_container.addAsset(renderer.asset);
			}
		}
		protected function onRemoveRenderer(layout:RendererGridLayout, renderer:ILayoutView) : void{
			var index:int = _renderers.indexOf(renderer.asset);
			_renderers.splice(index,1);
			if(_container){
				_container.removeAsset(renderer.asset);
			}
			// TODO: this functionality should really be part of some factory.destory(item) method or something
			var view:DrawableView = (renderer as DrawableView);
			if(view)view.asset = null;
		}
		override protected function measure() : void{
			assessFactory();
			var layoutMeas:Point = _layout.measurements;
			
			_measurements.x = layoutMeas.x;
			_measurements.y = layoutMeas.y;
			if(_scrollBar){
				var metrics:IScrollMetrics = _scrollBar.scrollSubject.getScrollMetrics(_scrollBar.direction);
				var scrollBar:Boolean = (metrics.maximum>metrics.pageSize && metrics.pageSize) || (!_scrollBar.hideWhenUnusable);
				if(scrollBar){
					var meas:Point = _scrollBar.measurements;
					if(_scrollBar.direction==Direction.VERTICAL){
						_measurements.x += meas.x;
					}else{
						_measurements.y += meas.y;
					}
				}
			}else{
				_measurements.x = layoutMeas.x;
			}
		}
		override protected function validateSize() : void{
			super.validateSize();
			drawListAndScrollbar(size.x,size.y);
		}
		protected function drawListAndScrollbar(width:Number, height:Number) : void{
			var layoutWidth:Number = width;
			var layoutHeight:Number = height;
			if(_scrollBar){
				var meas:Point = _scrollBar.measurements;
				var metrics:IScrollMetrics = _scrollBar.scrollSubject.getScrollMetrics(_scrollBar.direction);
				_scrollBarShown = (metrics.maximum>metrics.pageSize || !_scrollBar.hideWhenUnusable);
				if(_scrollBar.direction==Direction.VERTICAL){
					_scrollBar.setPosition(width-meas.x-_layout.marginRight,_layout.marginTop);
					_scrollBar.setSize(meas.x,height-_layout.marginTop-_layout.marginBottom);
					if(_scrollBarShown){
						layoutWidth = width-meas.x;
					}
				}else{
					_scrollBar.setPosition(_layout.marginLeft,height-meas.y-_layout.marginBottom);
					_scrollBar.setSize(width-_layout.marginLeft-_layout.marginRight,meas.y);
					if(_scrollBarShown){
						layoutHeight = height-meas.y;
					}
				}
			}
			setLayoutDimensions(layoutWidth,layoutHeight);
			_scrollRect.x = _layout.marginLeft;
			_scrollRect.y = _layout.marginTop;
			_scrollRect.width = layoutWidth-_layout.marginLeft-_layout.marginRight;
			_scrollRect.height = height-_layout.marginTop-_layout.marginBottom;
			_container.scrollRect = _scrollRect;
			_container.setPosition(_layout.marginLeft,_layout.marginTop);
		}
		protected function setLayoutDimensions(width:Number, height:Number):void{
			_layout.setSize(width,height);
			if(_layout.flowDirection==Direction.VERTICAL){
				_layout.columnWidths = [width];
				_layout.rowHeights = null;
			}else{
				_layout.columnWidths = null;
				_layout.rowHeights = [height];
			}
		}
		protected function assessFactory():void{
			attemptInit();
			
			var factory:IInstanceFactory;
			var dataField:String;
			if(_rendererFactory){
				factory = _rendererFactory;
				dataField = _dataField || ASSUMED_DATA_FIELD;
				
				var castFactory:MultiInstanceFactory = (factory as MultiInstanceFactory);
				if(castFactory && !castFactory.hasProperty("asset") && castFactory.useChildFactories && _assumedRendererAsset){
					if(!_factoryAssumedAssetProps){
						_factoryAssumedAssetProps = new Dictionary();
					}
					checkAssetFactory();
					castFactory.addProperties(_factoryAssumedAssetProps);
					_factoryAssumedAssetSet = true;
				}
			}else if(_assumedRendererAsset){
				if(!_assumedRendererFactory){
					_assumedRendererFactory = createAssumedFactory();
				}
				factory = _assumedRendererFactory;
				dataField = ASSUMED_DATA_FIELD;
			}else{
				factory = null;
				dataField = null;
			}
			if(factory!=_layout.rendererFactory || dataField!=_layout.dataField){
				updateFactory(factory,dataField);
			}
		}
		protected function createAssumedFactory():SimpleInstanceFactory{
			var factory:SimpleInstanceFactory = new SimpleInstanceFactory(TextLabelButton);
			factory.useChildFactories = true;
			factory.instanceProperties = new Dictionary();
			factory.instanceProperties["togglable"] = true;
			checkAssetFactory();
			factory.instanceProperties["asset"] = _assumedAssetFactory;
			return factory;
		}
		protected function checkAssetFactory():void{
			if(!_assumedAssetFactory && _assumedRendererAsset){
				_assumedAssetFactory = createAssumedAssetFactory(_assumedRendererAsset);
				if(_factoryAssumedAssetProps){
					_factoryAssumedAssetProps["asset"] = _assumedAssetFactory;
				}
			}
		}
		protected function createAssumedAssetFactory(asset:IDisplayAsset):IInstanceFactory{
			return asset.getCloneFactory();
		}
		protected function updateFactory(factory:IInstanceFactory, dataField:String):void{
			_layout.rendererFactory = factory;
			_layout.dataField = dataField;
		}
		
		public function getScrollMetrics(direction:String):IScrollMetrics{
			if(direction==Direction.HORIZONTAL){
				if(!_horScrollMetrics)_horScrollMetrics = new ScrollMultiplier(scrollSpeed(direction),_layout.getScrollMetrics(direction));
				return _horScrollMetrics;
			}else{
				if(!_verScrollMetrics)_verScrollMetrics = new ScrollMultiplier(scrollSpeed(direction),_layout.getScrollMetrics(direction));
				return _verScrollMetrics;
			}
		}
		protected function scrollSpeed(direction:String):Number{
			return 30;
		}
	}
}