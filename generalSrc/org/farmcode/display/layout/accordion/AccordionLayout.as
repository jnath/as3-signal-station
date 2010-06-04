package org.farmcode.display.layout.accordion
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.farmcode.display.constants.Direction;
	import org.farmcode.display.core.ILayoutView;
	import org.farmcode.display.layout.AbstractLayout;
	import org.farmcode.display.layout.ILayoutSubject;
	import org.farmcode.display.layout.IMinimisableLayoutSubject;
	import org.farmcode.display.layout.grid.RendererGridLayout;

	public class AccordionLayout extends RendererGridLayout
	{
		
		public function get accordionDirection():String{
			return _accordionDirection;
		}
		public function set accordionDirection(value:String):void{
			if(_accordionDirection!=value){
				_accordionDirection = value;
				_cellPosFlag.invalidate();
				invalidate();
			}
		}
		
		private var _accordionDirection:String = Direction.VERTICAL;
		
		private var _minSubjectsMeas:Dictionary = new Dictionary();
		private var _realMeas:Dictionary = new Dictionary();
		
		public function AccordionLayout(){
			flowDirection = Direction.VERTICAL;
			addRendererAct.addHandler(onRendererAdded);
			removeRendererAct.addHandler(onRendererRemoved);
		}
		protected function onRendererAdded(from:AccordionLayout, renderer:IMinimisableLayoutSubject):void{
			renderer.openFractChanged.addHandler(onOpenFractChanged);
		}
		protected function onRendererRemoved(from:AccordionLayout, renderer:IMinimisableLayoutSubject):void{
			renderer.openFractChanged.removeHandler(onOpenFractChanged);
		}
		protected function onOpenFractChanged(from:IMinimisableLayoutSubject) : void{
			invalidateAll();
		}
		override protected function rendererAdded(renderer:ILayoutSubject):void{
			super.rendererAdded(renderer);
			(renderer as IMinimisableLayoutSubject).minMeasurementsChanged.addHandler(onMinChanged);
		}
		override protected function rendererRemoved(renderer:ILayoutSubject):void{
			super.rendererRemoved(renderer);
			(renderer as IMinimisableLayoutSubject).minMeasurementsChanged.removeHandler(onMinChanged);
		}
		
		protected function onMinChanged(from:IMinimisableLayoutSubject) : void{
			var data:* = from[_dataField];
			delete _cellMeasCache[data];
			invalidateAll();
		}
		override protected function getChildMeasurement(key:*) : Rectangle{
			if(key>=_dataCount){
				return null;
			}
			var data:* = _dataMap[key];
			var renderer:ILayoutSubject = _dataToRenderers[data];
			if(!renderer){
				if(!_protoRenderer){
					_protoRenderer = _rendererFactory.createInstance();
				}
				_protoRenderer[_dataField] = data;
				if(_setRendererDataAct)_setRendererDataAct.perform(this,_protoRenderer,data,_dataField);
				renderer = _protoRenderer;
			}
			var minRenderer:IMinimisableLayoutSubject = (renderer as IMinimisableLayoutSubject);
			
			var ret:Rectangle = new Rectangle();
			var min:Point = minRenderer.minMeasurements;
			var fullMeas:Rectangle = renderer.displayMeasurements;
			_realMeas[key] = fullMeas;
			
			ret.width = min.x+(fullMeas.width-min.x)*minRenderer.openFract;
			ret.height = min.y+(fullMeas.height-min.y)*minRenderer.openFract;
			
			ret.x = fullMeas.x;
			ret.y = fullMeas.y;
			if(renderer==_protoRenderer){
				_protoRenderer[_dataField] = null;
				if(_setRendererDataAct)_setRendererDataAct.perform(this,_protoRenderer,null,_dataField);
			}
			return ret;
		}
		
		override protected function positionRenderer(key:*, length:int, breadth:int, x:Number, y:Number, width:Number, height:Number):void{
			var renderer:IMinimisableLayoutSubject = getChildRenderer(key,length,breadth) as IMinimisableLayoutSubject;
			
			var posIndex:int = (key as int)*int(4);
			_positionCache[posIndex] = x;
			_positionCache[posIndex+1] = y;
			_positionCache[posIndex+2] = width;
			_positionCache[posIndex+3] = height;
			var coIndex:int = (key as int)*int(2);
			_coordCache[coIndex] = length;
			_coordCache[coIndex+1] = breadth;
			
			if(renderer){
				var fullMeas:Rectangle = _realMeas[key];
				if(_accordionDirection==Direction.VERTICAL){
					renderer.setDisplayPosition(x,y,width,fullMeas.height>height?fullMeas.height:height);
					renderer.setOpenArea(width,height);
				}else{
					renderer.setDisplayPosition(x,y,fullMeas.width>width?fullMeas.width:width,height);
					renderer.setOpenArea(width,height);
				}
			}
		}
	}
}