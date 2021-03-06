package org.tbyrne.display.containers.accordionGrid
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.tbyrne.display.assets.nativeTypes.IDisplayObjectContainer;
	import org.tbyrne.display.assets.nativeTypes.IDisplayObject;
	import org.tbyrne.display.constants.Anchor;
	import org.tbyrne.display.containers.accordion.AccordionRenderer;
	import org.tbyrne.display.core.ILayoutView;
	import org.tbyrne.display.validation.ValidationFlag;
	
	public class AccordionGridRenderer extends AccordionRenderer implements IAccordionGridRenderer
	{
		public function get wipeFromTop():Boolean{
			return _wipeFromTop;
		}
		public function set wipeFromTop(value:Boolean):void{
			if(_wipeFromTop!=value){
				_wipeFromTop = value;
				invalidateSize();
			}
		}
		
		private var _wipeFromTop:Boolean = true;
		
		private var _headerContainer:IDisplayObjectContainer;
		private var _cellContainer:IDisplayObjectContainer;
		private var _cellRenderers:Dictionary = new Dictionary();
		private var _headerRenderers:Dictionary = new Dictionary();
		
		private var _headerX:Number;
		private var _headerY:Number;
		private var _headerHeight:Number;
		private var _headerWidth:Number;
		
		private var _containerX:Number;
		private var _containerY:Number;
		private var _containerMeas:Rectangle = new Rectangle();
		private var _containerMeasFlag:ValidationFlag = new ValidationFlag(checkCells,false);
		
		public function AccordionGridRenderer(asset:IDisplayObject=null){
			super(asset);
		}
		
		override protected function bindToAsset() : void{
			super.bindToAsset();
			_headerContainer = _containerAsset.factory.createContainer();
			_containerAsset.addAsset(_headerContainer);
			
			var i:*;
			var renderer:ILayoutView;
			for(i in _headerRenderers){
				renderer = (i as ILayoutView);
				_headerContainer.addAsset(renderer.asset);
			}
			
			_cellContainer = _containerAsset.factory.createContainer();
			_containerAsset.addAsset(_cellContainer);
			
			for(i in _cellRenderers){
				renderer = (i as ILayoutView);
				_cellContainer.addAsset(renderer.asset);
			}
		}
		override protected function unbindFromAsset() : void{
			super.unbindFromAsset();
			var i:*;
			var renderer:ILayoutView;
			for(i in _headerRenderers){
				renderer = (i as ILayoutView);
				_headerContainer.removeAsset(renderer.asset);
			}
			_containerAsset.removeAsset(_headerContainer);
			_containerAsset.factory.destroyAsset(_headerContainer);
			_headerContainer = null;
			
			for(i in _cellRenderers){
				renderer = (i as ILayoutView);
				_cellContainer.removeAsset(renderer.asset);
			}
			_containerAsset.removeAsset(_cellContainer);
			_containerAsset.factory.destroyAsset(_cellContainer);
			_cellContainer = null;
		}
		override protected function getContainerMeasurements() : Rectangle{
			_containerMeasFlag.validate();
			return _containerMeas;
		}
		override protected function setContainerSize(x:Number, y:Number, width:Number, height:Number) : void{
			_headerContainer.setPosition(x-_headerX-(_minMeasurements.x-_labelMeas.x),
										y-_headerY-(_minMeasurements.y-_labelMeas.y));
			
			_cellContainer.setPosition(x,y);
			if(wipeFromTop){
				_cellContainer.scrollRect = new Rectangle(_containerX+Math.max(_containerMeas.width-width,0),_containerY+Math.max(_containerMeas.height-height,0),width,height);
			}else{
				_cellContainer.scrollRect = new Rectangle(_containerX,_containerY,width,height);
			}
		}
		
		public function addCellRenderer(cellRenderer:ILayoutView, headerCell:Boolean):void{
			invalidateSize();
			invalidateMeasurements();
			if(headerCell){
				_headerRenderers[cellRenderer] = true;
				cellRenderer.sizeChanged.addHandler(onHeaderPosChanged);
				cellRenderer.positionChanged.addHandler(onHeaderPosChanged);
				if(_headerContainer){
					_headerContainer.addAsset(cellRenderer.asset);
				}
				_minMeasurementsFlag.invalidate();
				if(_minMeasurementsChanged)_minMeasurementsChanged.perform(this);
			}else{
				_cellRenderers[cellRenderer] = true;
				cellRenderer.sizeChanged.addHandler(onCellPosChanged);
				cellRenderer.positionChanged.addHandler(onCellPosChanged);
				if(_cellContainer){
					_cellContainer.addAsset(cellRenderer.asset);
				}
				_containerMeasFlag.invalidate();
			}
		}
		public function removeCellRenderer(cellRenderer:ILayoutView):void{
			invalidateSize();
			invalidateMeasurements();
			if(_headerRenderers[cellRenderer]){
				delete _headerRenderers[cellRenderer];
				cellRenderer.sizeChanged.removeHandler(onHeaderPosChanged);
				cellRenderer.positionChanged.removeHandler(onHeaderPosChanged);
				if(_headerContainer){
					_headerContainer.removeAsset(cellRenderer.asset);
				}
				_minMeasurementsFlag.invalidate();
				if(_minMeasurementsChanged)_minMeasurementsChanged.perform(this);
			}else{
				cellRenderer.sizeChanged.removeHandler(onCellPosChanged);
				cellRenderer.positionChanged.removeHandler(onCellPosChanged);
				if(_cellContainer){
					_cellContainer.removeAsset(cellRenderer.asset);
				}
				delete _cellRenderers[cellRenderer];
				_containerMeasFlag.invalidate();
			}
		}
		protected function checkHeaderCells():void{
			var newX:Number;
			var newY:Number;
			var newWidth:Number = 0;
			var newHeight:Number = 0;
			for(var i:* in _headerRenderers){
				var renderer:ILayoutView = (i as ILayoutView);
				var pos:Point = renderer.position;
				var size:Point = renderer.size;
				if(isNaN(newX) || newX>pos.x){
					newX = pos.x;
				}
				if(isNaN(newY) || newY>pos.y){
					newY = pos.y;
				}
				if(newWidth<pos.x+size.x){
					newWidth = pos.x+size.x;
				}
				if(newHeight<pos.y+size.y){
					newHeight = pos.y+size.y;
				}
			}
			if(isNaN(newX)){
				newX = 0;
			}else{
				newWidth -= newX;
			}
			if(isNaN(newY)){
				newY = 0;
			}else{
				newHeight -= newY;
			}
			
			_headerX = newX;
			_headerY = newY;
			_headerWidth = newWidth;
			_headerHeight = newHeight;
				
		}
		protected function checkCells():void{
			var newX:Number;
			var newY:Number;
			var newWidth:Number = 0;
			var newHeight:Number = 0;
			for(var i:* in _cellRenderers){
				var renderer:ILayoutView = (i as ILayoutView);
				var pos:Point = renderer.position;
				var size:Point = renderer.size;
				if(isNaN(newX) || newX>pos.x){
					newX = pos.x;
				}
				if(isNaN(newY) || newY>pos.y){
					newY = pos.y;
				}
				if(newWidth<pos.x+size.x){
					newWidth = pos.x+size.x;
				}
				if(newHeight<pos.y+size.y){
					newHeight = pos.y+size.y;
				}
			}
			if(isNaN(newX)){
				newX = 0;
			}else{
				newWidth -= newX;
			}
			if(isNaN(newY)){
				newY = 0;
			}else{
				newHeight -= newY;
			}
			
			_containerX = newX;
			_containerY = newY;
			_containerMeas.width = newWidth;
			_containerMeas.height = newHeight;
		}
		protected function onHeaderPosChanged(... params):void{
			invalidateSize();
			invalidateMeasurements();
			_minMeasurementsFlag.invalidate();
			if(_minMeasurementsChanged)_minMeasurementsChanged.perform(this);
		}
		protected function onCellPosChanged(... params):void{
			invalidateSize();
			invalidateMeasurements();
			_containerMeasFlag.invalidate();
		}
		override protected function checkMinMeas():void{
			super.checkMinMeas();
			checkHeaderCells();
			if(!isNaN(_headerHeight)){
				switch(_labelPosition){
					case Anchor.TOP:
					case Anchor.TOP_LEFT:
					case Anchor.TOP_RIGHT:
					case Anchor.BOTTOM:
					case Anchor.BOTTOM_LEFT:
					case Anchor.BOTTOM_RIGHT:
						_minMeasurements.y += _headerHeight;
						break;
					
				}
			}
			if(!isNaN(_headerWidth)){
				switch(_labelPosition){
					case Anchor.LEFT:
					case Anchor.TOP_LEFT:
					case Anchor.BOTTOM_LEFT:
					case Anchor.RIGHT:
					case Anchor.TOP_RIGHT:
					case Anchor.BOTTOM_RIGHT:
						_minMeasurements.x += _headerWidth;
						break;
				}
			}
		}
	}
}