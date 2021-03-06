package org.tbyrne.display.layout.grid
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.tbyrne.acting.actTypes.IAct;
	import org.tbyrne.acting.acts.Act;
	import org.tbyrne.collections.ICollection;
	import org.tbyrne.collections.ICollection2D;
	import org.tbyrne.collections.IIterator;
	import org.tbyrne.collections.IIterator2D;
	import org.tbyrne.collections.linkedList.LinkedListConverter;
	import org.tbyrne.display.DisplayNamespace;
	import org.tbyrne.display.core.IView;
	import org.tbyrne.display.layout.ILayoutSubject;
	import org.tbyrne.display.layout.core.ILayoutInfo;
	import org.tbyrne.display.layout.list.ListLayoutInfo;
	import org.tbyrne.display.scrolling.ScrollMetrics;
	import org.tbyrne.display.validation.ValidationFlag;
	import org.tbyrne.factories.IInstanceFactory;

	public class RendererGridLayout extends AbstractGridLayout
	{
		public function get pixelFlow():Boolean{
			return super._pixelFlow;
		}
		public function set pixelFlow(value:Boolean):void{
			super._pixelFlow = value;
		}
		public function get renderersSameSize():Boolean{
			return _renderersSameSize;
		}
		public function set renderersSameSize(value:Boolean):void{
			_renderersSameSize = value;
		}
		public function get columnWidths():Array{
			return super._columnWidths;
		}
		public function set columnWidths(value:Array):void{
			super._columnWidths = value;
		}
		public function get rowHeights():Array{
			return super._rowHeights;
		}
		public function set rowHeights(value:Array):void{
			super._rowHeights = value;
		}
		public function get equaliseCellHeights():Boolean{
			return super._equaliseCellHeights;
		}
		public function set equaliseCellHeights(value:Boolean):void{
			super._equaliseCellHeights = value;
		}
		public function get equaliseCellWidths():Boolean{
			return super._equaliseCellWidths;
		}
		public function set equaliseCellWidths(value:Boolean):void{
			super._equaliseCellWidths = value;
		}
		public function get fillFlow():Boolean{
			return super._fillFlow;
		}
		public function set fillFlow(value:Boolean):void{
			super._fillFlow = value;
		}
		public function get horizontalGap():Number{
			return super._horizontalGap;
		}
		public function set horizontalGap(value:Number):void{
			super._horizontalGap = value;
		}
		public function get verticalGap():Number{
			return super._verticalGap;
		}
		public function set verticalGap(value:Number):void{
			super._verticalGap = value;
		}
		public function get gap():Number{
			return (verticalGap==horizontalGap?verticalGap:NaN);
		}
		public function set gap(value:Number):void{
			verticalGap = value;
			horizontalGap = value;
		}
		public function get flowDirection():String{
			return super._flowDirection;
		}
		public function set flowDirection(value:String):void{
			super._flowDirection = value;
		}
		
		public function get rendererFactory():IInstanceFactory{
			return _rendererFactory;
		}
		public function set rendererFactory(value:IInstanceFactory):void{
			if(_rendererFactory!=value){
				_rendererFactory = value;
				_protoRenderer = null;
				removeAllRenderers();
			}
		}
		
		public function get dataProvider():*{
			return _dataProvider;
		}
		public function set dataProvider(value:*):void{
			if(_dataProvider!=value){
				if(_dataProviderCollection2D){
					_dataProviderCollection2D.collection2DChanged.removeHandler(onCollection2DChanged);
				}else if(_dataProviderCollection){
					_dataProviderCollection.collectionChanged.removeHandler(onCollectionChanged);
				}
				_dataProvider = value;
				_dataToRenderers = new Dictionary();
				if(value){
					_dataProviderCollection2D = (value as ICollection2D);
					if(_dataProviderCollection2D){
						_dataProviderCollection = _dataProviderCollection2D;
						_dataProviderCollection2D.collection2DChanged.addHandler(onCollection2DChanged);
					}else{
						_dataProviderCollection = (value as ICollection);
						if(!_dataProviderCollection){
							_dataProviderCollection = LinkedListConverter.fromNativeCollection(value);
						}
						if(_dataProviderCollection){
							_dataProviderCollection.collectionChanged.addHandler(onCollectionChanged);
						}
					}
				}else{
					_dataProviderCollection = null;
					_dataProviderCollection2D = null;
				}
				_cellKeys = _cellLayouts = null;
				
				clearDataChecks();
				
				clearMeasurements();
			}
		}
		
		public function get dataField():String{
			return _dataField;
		}
		public function set dataField(value:String):void{
			if(_dataField!=value){
				_dataField = value;
				clearMeasurements();
			}
		}
		public function get renderEmptyCells():Boolean{
			return _renderEmptyCells;
		}
		public function set renderEmptyCells(value:Boolean):void{
			if(_renderEmptyCells!=value){
				_renderEmptyCells = value;
				_cellPosFlag.invalidate();
				invalidateSize();
			}
		}
		public function get horizontalScrollByLine():Boolean{
			return super._horizontalScrollByLine;
		}
		public function set horizontalScrollByLine(value:Boolean):void{
			super._horizontalScrollByLine = value
		}
		public function get verticalScrollByLine():Boolean{
			return super._verticalScrollByLine;
		}
		public function set verticalScrollByLine(value:Boolean):void{
			super._verticalScrollByLine = value
		}
		public function get fitRenderers():int{
			validate();
			return _fitRenderers;
		}
		public function get scrollRectMode():Boolean{
			return _scrollRectMode;
		}
		public function set scrollRectMode(value:Boolean):void{
			_scrollRectMode = value;
		}
		public function get collectDataPositions():Boolean{
			return _collectDataPositions;
		}
		public function set collectDataPositions(value:Boolean):void{
			if(_collectDataPositions!=value){
				_collectDataPositions = value;
				invalidatePos();
			}
		}
		
		/**
		 * handler(layout:RendererGridLayout, fitRenderers:int)
		 */
		public function get fitRenderersAct():IAct{
			if(!_fitRenderersAct)_fitRenderersAct = new Act();
			return _fitRenderersAct;
		}
		/**
		 * handler(layout:RendererGridLayout, renderer:ILayoutSubject)
		 */
		public function get removeRendererAct():IAct{
			if(!_removeRendererAct)_removeRendererAct = new Act();
			return _removeRendererAct;
		}
		/**
		 * handler(layout:RendererGridLayout, renderer:ILayoutSubject)
		 */
		public function get addRendererAct():IAct{
			if(!_addRendererAct)_addRendererAct = new Act();
			return _addRendererAct;
		}
		/**
		 * handler(layout:RendererGridLayout, renderer:ILayoutSubject, data:*, dataField:String)
		 */
		public function get setRendererDataAct():IAct{
			if(!_setRendererDataAct)_setRendererDataAct = new Act();
			return _setRendererDataAct;
		}
		protected var _addRendererAct:Act;
		protected var _removeRendererAct:Act;
		protected var _fitRenderersAct:Act;
		protected var _setRendererDataAct:Act;
		
		
		private var _collectDataPositions:Boolean;
		private var _renderEmptyCells:Boolean;
		protected var _dataField:String;
		private var _dataProvider:*;
		private var _dataProviderCollection:ICollection;
		private var _dataProviderCollection2D:ICollection2D;
		protected var _rendererFactory:IInstanceFactory;
		protected var _protoRenderer:ILayoutSubject;
		protected var _cullRenderersFlag:ValidationFlag = new ValidationFlag(cullRenderers,true);
		
		private var _dataChecked:Boolean;
		protected var _dataCount:int;
		private var _dataLayouts:Dictionary = new Dictionary();
		protected var _dataMap:Dictionary = new Dictionary();
		private var _dataIndices:Dictionary = new Dictionary();
		protected var _dataToRenderers:Dictionary = new Dictionary();
		private var _renderers:Array = [];
		protected var _positionCache:Array = [];
		protected var _coordCache:Array = [];
		
		private var _cellKeys:Dictionary;
		private var _cellLayouts:Dictionary;
		private var _cellKeyCount:int;
		
		private var _fitRenderers:int;
		
		protected var _verticalRendAxis:RendererGridAxis;
		protected var _horizontalRendAxis:RendererGridAxis;
		
		protected var _flowRendAxis:RendererGridAxis;
		protected var _acrossRendAxis:RendererGridAxis;
		
		public function RendererGridLayout(scopeView:IView=null){
			super(scopeView);
		}
		override protected function createAxes():void{
			_horizontalAxis = _horizontalRendAxis = new RendererGridAxis("x"/*,"width"*/,"columnIndex");
			_verticalAxis = _verticalRendAxis = new RendererGridAxis("y"/*,"height"*/,"rowIndex");
		}
		override protected function validateProps():void{
			super.validateProps();
			if(_isVertical){
				_flowRendAxis = _verticalRendAxis;
				_acrossRendAxis = _horizontalRendAxis;
			}else{
				_flowRendAxis = _horizontalRendAxis;
				_acrossRendAxis = _verticalRendAxis;
			}
		}
		public function onCollection2DChanged(from:ICollection2D, fromX:Number, toX:Number, fromY:Number, toY:Number):void{
			clearDataChecks();
			//TODO: use parameters to limit invalidation (would require refactor of data checking logic)
			clearMeasurements();
		}
		public function onCollectionChanged(from:ICollection, fromX:Number, toX:Number):void{
			clearDataChecks();
			//TODO: use parameters to limit invalidation (would require refactor of data checking logic)
			clearMeasurements();
		}
		public function getDataLayout(data:*) : ILayoutInfo{
			validate();
			var index:int = _dataIndices[data];
			return _dataLayouts[index];
		}
		public function getDataCount() : int{
			if(!_dataChecked)getChildKeys();
			return _dataCount;
		}
		public function getDataAt(index:int):*{
			getChildKeys();
			return _dataMap[index];
		}
		public function getDataPosition(index:int, fillRect:Rectangle=null):Rectangle{
			if(!_collectDataPositions){
				Log.error("RendererGridLayout.collectDataPositions must be set to true to use getDataPosition");
			}
			
			validate();
			index *= int(4);
			if(!fillRect){
				fillRect = new Rectangle();
			}
			fillRect.x = _positionCache[index];
			fillRect.y = _positionCache[index+1];
			fillRect.width = _positionCache[index+2];
			fillRect.height = _positionCache[index+3];
			return fillRect;
		}
		
		public function getDataCoords(index:int, fillPoint:Point=null):Point{
			validate();
			index *= int(2);
			if(!fillPoint){
				fillPoint = new Point();
			}
			if(_isVertical){
				fillPoint.x = _coordCache[index];
				fillPoint.y = _coordCache[index+1];
			}else{
				fillPoint.x = _coordCache[index+1];
				fillPoint.y = _coordCache[index];
			}
			return fillPoint;
		}
		public function getIndexAtGridCoords(x:int, y:int):int{
			validate();
			if(_cellPosCache){
				x += _horizontalRendAxis.dimIndex;
				y += _verticalRendAxis.dimIndex;
				if(_isVertical){
					if(x<_cellPosCache.length)return _cellPosCache[x][y];
				}else{
					if(y<_cellPosCache.length)return _cellPosCache[y][x];
				}
			}
			return -1;
		}
		override protected function doLayout(): void{
			if(_rendererFactory){
				super.doLayout();
				_cullRenderersFlag.validate();
			}else{
				invalidateSize();
			}
		}
		override protected function getChildKeyCount():int{
			getChildKeys();
			return _cellKeyCount;
		}
		override protected function getChildKeys() : Dictionary{
			if(!_dataChecked && _dataProviderCollection){
				_dataChecked = true;
				var iterator:IIterator = _dataProviderCollection.getIterator();
				var iterator2D:IIterator2D = (iterator as IIterator2D);
				var i:int=0;
				var data:*;
				if(iterator2D){
					_anyGridInfos = true;
					while(data = iterator2D.next()){
						_dataIndices[data] = i;
						_dataMap[i] = data;
						_dataLayouts[i] = new GridLayoutInfo(iterator2D.x,iterator2D.y);
						++i;
					}
					iterator.release();
				}else if(iterator){
					_anyGridInfos = false;
					while((data = iterator.next())!=null){
						_dataIndices[data] = i;
						_dataMap[i] = data;
						_dataLayouts[i] = new ListLayoutInfo(i);
						++i;
					}
					iterator.release();
				}
				_dataCount = i;
			}
			var keyCount:int = (_fitRenderers>_dataCount?_fitRenderers:_dataCount);
			if(!_cellKeys || _cellKeyCount!=keyCount){
				_cellKeys = new Dictionary();
				_cellLayouts = new Dictionary();
				for(i=0; i<keyCount; i++){
					_cellKeys[i] = true;
					if(!_dataLayouts[i]){
						_cellLayouts[i] = new ListLayoutInfo(i);
					}
				}
				_cellKeyCount = keyCount;
			}
			return _cellKeys;
		}
		public function clearDataChecks():void{
			_dataChecked = false;
			_dataLayouts = new Dictionary();
			_dataMap = new Dictionary();
			_dataIndices = new Dictionary();
			_cullRenderersFlag.invalidate();
		}
		protected function onRendMeasChanged(from:ILayoutSubject, oldWidth:Number, oldHeight:Number):void{
			var data:* = from[_dataField];
			if(data){
				for(var key:* in _dataMap){
					if(_dataMap[key]==data){
						delete _cellMeasCache[key];
						break;
					}
				}
				_cellMeasFlag.invalidate();
				invalidateSize();
			}else{
				Log.error("RendererGridLayout.onRendMeasChanged() data couldn't be found");
			}
		}
		override protected function remeasureChild(key:*) : Boolean{
			return (!_cellMeasCache[key]);
		}
		override protected function getChildMeasurement(key:*) : Point{
			if(key>=_dataCount && !_renderersSameSize){
				return null;
			}
			var ret:Point = _cellMeasCache[key];
			if(!ret){
				ret = new Point();
				_cellMeasCache[key] = ret;
			}
			
			var data:* = _dataMap[key];
			var renderer:ILayoutSubject = _dataToRenderers[data];
			var meas:Point;
			if(!renderer){
				if(!_protoRenderer){
					_protoRenderer = _rendererFactory.createInstance();
				}
				_protoRenderer[_dataField] = data;
				if(_setRendererDataAct)_setRendererDataAct.perform(this,_protoRenderer,data,_dataField);
				renderer = _protoRenderer;
				
				meas = renderer.measurements;
				
				_protoRenderer[_dataField] = null;
				if(_setRendererDataAct)_setRendererDataAct.perform(this,_protoRenderer,null,_dataField);
			}else{
				meas = renderer.measurements;
			}
			
			ret.x = meas.x;
			ret.y = meas.y;
			return ret;
		}
		override protected function getChildLayoutInfo(key:*) : ILayoutInfo{
			return _dataLayouts[key] || _cellLayouts[key];
		}
		private var _getRendererPoint:Point;
		DisplayNamespace function getRenderer(dataIndex:int):ILayoutSubject{
			if(!_getRendererPoint)_getRendererPoint = new Point();
			getDataCoords(dataIndex,_getRendererPoint);
			return getChildRenderer(dataIndex,_getRendererPoint[_acrossFlowAxis.coordRef],_getRendererPoint[_flowDirectionAxis.coordRef]);
		}
		protected function rendererAdded(renderer:ILayoutSubject):void{
			renderer.measurementsChanged.addHandler(onRendMeasChanged);
			if(_addRendererAct)_addRendererAct.perform(this,renderer);
		}
		// TODO: avoid casting all the time
		protected function rendererRemoved(renderer:ILayoutSubject):void{
			var cast:IGridLayoutSubject = (renderer as IGridLayoutSubject);
			if(cast){
				cast.columnIndex = -1;
				cast.rowIndex = -1;
			}
			delete _dataToRenderers[renderer[_dataField]];
			renderer.measurementsChanged.removeHandler(onRendMeasChanged);
			if(_removeRendererAct)_removeRendererAct.perform(this,renderer);
		}
		protected function cullRenderers():void{
			/*
			Remove renderers which fall within the visible area but do not relate
			to any data any more.
			*/
			
			var minAcrossSize:int = _acrossRendAxis.dimIndex;
			var maxAcrossSize:int = _acrossRendAxis.dimIndexMax;
			var minFlowSize:int = _flowRendAxis.dimIndex;
			var maxFlowSize:int = _flowRendAxis.dimIndexMax;
			var flowRange:int = (maxFlowSize-minFlowSize);
			
			var totRend:int = _renderers.length;
			for(var i:int=0; i<totRend; ++i){
				var renderer:ILayoutSubject = _renderers[i];
				if(renderer){
					var flowIndex:int = i%flowRange;
					var acrossIndex:int = ((i-flowIndex)/flowRange)+minAcrossSize;
					flowIndex += minFlowSize;
					if(acrossIndex<minAcrossSize || 
						acrossIndex>maxAcrossSize ||
						(!_renderEmptyCells && (_cellPosCache[acrossIndex]==null || _cellPosCache[acrossIndex][flowIndex]==null))){
						
						delete _renderers[i];
						/* must remove before setting data to null to avoid the layout responding to
						the resulting measurement and throwing an error for not finding the renderers data.*/
						rendererRemoved(renderer); 
						renderer[_dataField] = null;
					}
				}
			}
		}
		protected function calcRange(index:int, indexMax:int):int{
			return indexMax-index;
		}
		override protected function validateAllScrolling():void{
			if(!_flowScrollFlag.valid || !_acrossScrollFlag.valid){
				
				var oldFlowIndex:int = _flowRendAxis.dimIndex;
				var oldAcrossIndex:int = _acrossRendAxis.dimIndex;
				
				var oldFlowIndexMax:int = _flowRendAxis.dimIndexMax;
				var oldAcrossIndexMax:int = _acrossRendAxis.dimIndexMax;
				
				var oldFlowRange:int = calcRange(oldFlowIndex,oldFlowIndexMax);
				var oldAcrossRange:int = calcRange(oldAcrossIndex,oldAcrossIndexMax);
				
				super.validateAllScrolling();
				
				
				var flowIndex:int = _flowRendAxis.dimIndex;
				var acrossIndex:int = _acrossRendAxis.dimIndex;
				
				var flowIndexMax:int = _flowRendAxis.dimIndexMax;
				var acrossIndexMax:int = _acrossRendAxis.dimIndexMax;
				
				var flowRange:int = calcRange(flowIndex,flowIndexMax);
				var acrossRange:int = calcRange(acrossIndex,acrossIndexMax);
				
				var shiftFlow:int = oldFlowIndex-flowIndex;
				var shiftAcross:int = oldAcrossIndex-acrossIndex;
				
				var oldTotal:Number = (oldFlowRange)*(oldAcrossRange);
				_fitRenderers = (flowRange)*(acrossRange);
				if(oldTotal!=_fitRenderers && _fitRenderersAct){
					_fitRenderersAct.perform(this,_fitRenderers);
					_cullRenderersFlag.invalidate();
				}
				if(oldTotal!=_fitRenderers && _renderEmptyCells && _fitRenderers>_dataCount){
					validateCellMeas();
					_cellMappingFlag.validate();
					invalidateSize();
				}
				
				if(shiftFlow || shiftAcross || oldFlowRange!=flowRange || oldAcrossRange!=acrossRange){
					var newRenderers:Array = [];
					var rangeDif:int;
					if(_pixelFlow){
						rangeDif = (oldFlowRange-flowRange);
					}
					for(var across:int=0; across<oldAcrossRange; across++){
						for(var flow:int=0; flow<oldFlowRange; flow++){
							var oldRenderIndex:int = ((oldFlowRange)*across)+flow;
							var renderer:ILayoutSubject = _renderers[oldRenderIndex];
							if(renderer){
								var newAcross:int = across;
								var newFlow:int = flow;
								if(_pixelFlow && rangeDif){
									// adjust indices to reflect changes in flowRange
									var renderIndex:int = ((flowRange)*newAcross)+newFlow;
									renderIndex += rangeDif*across;
									newAcross = Math.floor(renderIndex/(flowRange));
									newFlow = renderIndex%(flowRange);
								}
								// shift cells if scrolling has occured (so that dataProviders stay the same)
								
								var dataChanged:Boolean = false;
								
								if(shiftAcross){
									newAcross = (across+shiftAcross);
									while(newAcross>=acrossRange){
										dataChanged = true;
										newAcross -= acrossRange;
									}
									while(newAcross<0){
										dataChanged = true;
										newAcross += acrossRange;
									}
								}
								
								if(shiftFlow){
									newFlow = (flow+shiftFlow);
									while(newFlow>=flowRange){
										dataChanged = true;
										newFlow -= flowRange;
									}
									while(newFlow<0){
										dataChanged = true;
										newFlow += flowRange;
									}
								}
								
								// test whether the renderer is still needed
								renderIndex = (flowRange*newAcross)+newFlow;
								if(renderIndex<_fitRenderers && !newRenderers[renderIndex]){
									if(dataChanged)delete _dataToRenderers[renderer[_dataField]];
									newRenderers[renderIndex] = renderer;
								}else{
									rendererRemoved(renderer);
								}
							}
						}
					}
					_renderers = newRenderers;
				}
			}
		}
		override protected function validateScroll(scrollMetrics:ScrollMetrics, axis:GridAxis) : void{
			var realDim:Number = _size[axis.coordRef];
			var realMeas:Number = _measurements[axis.coordRef];
			
			var pixScroll:Number;
			var pixScrollMax:Number;
			var newIndex:int;
			var newIndexMax:int;
			
			if(_renderersSameSize){
				if(_sameCellMeas){
					scrollMetrics.maximum = 0;
					scrollMetrics.pageSize = 0;
					
					var meas:Number = _sameCellMeas[axis.coordRef];
					
					if(axis.scrollByLine){
						scrollMetrics.pageSize = int(realDim/meas);
						scrollMetrics.maximum = axis.maxCellSizes.length;
						
						pixScroll = scrollMetrics.scrollValue*meas;
					}else{
						scrollMetrics.maximum = realMeas;
						scrollMetrics.pageSize = realDim;
						
						pixScroll = scrollMetrics.scrollValue;
					}
					
					newIndex = int(pixScroll/meas);
					var bottom:Number = pixScroll+realDim;
					if(bottom%meas){
						newIndexMax = int(bottom/meas)+1;
					}else{
						newIndexMax = int(bottom/meas);
					}
				}else{
					pixScroll = 0;
					
					if(axis.scrollByLine){
						scrollMetrics.pageSize = 0;
						scrollMetrics.maximum = 0;
					}else{
						scrollMetrics.maximum = realMeas;
						scrollMetrics.pageSize = realDim;
					}
				}
			}else if(realMeas>realDim){
				pixScrollMax = realMeas-realDim;
				newIndexMax = -1;
				var stack:Number = axis.foreMargin;
				var total:Number = 0;
				var foundPixMax:Boolean;
				
				var scrollByPxValue:int = scrollMetrics.scrollValue;
				if(isNaN(scrollByPxValue)){
					scrollByPxValue = 0;
				}else{
					if(scrollByPxValue<scrollMetrics.minimum || isNaN(scrollByPxValue))scrollByPxValue = scrollMetrics.minimum;
					else if(scrollByPxValue>scrollMetrics.maximum-scrollMetrics.pageSize)scrollByPxValue = scrollMetrics.maximum-scrollMetrics.pageSize;
				}
				var scrollByLineValue:int = Math.round(scrollByPxValue);
				
				
				/*
				when we're scrolling with pixel values, it's better to act as if we're scrolled right to the bottom/right
				of the first visible renderer, this means that (when cells are about the same) we avoid removing and
				re-adding the last renderer everytime a renderer scrolls out of view.
				*/
				var comparePixScroll:Number;
				var tot:int = axis.maxCellSizes.length;
				for(var i:int=0; i<tot; i++){
					var measurement:Number = axis.maxCellSizes[i];
					if(axis.scrollByLine){
						if(i==scrollByLineValue){
							pixScroll = stack;
							comparePixScroll = stack;
							newIndex = i;
						}
					}else if(stack+measurement>scrollByPxValue && isNaN(pixScroll)){
						pixScroll = scrollByPxValue;
						comparePixScroll = stack+measurement;
						newIndex = i;
					}
					if(!isNaN(pixScroll) && newIndexMax==-1 && stack>realDim+comparePixScroll){
						// find the first row after all visible rows
						newIndexMax = i;
						if(foundPixMax)break;
					}
					stack += measurement;
					if(!foundPixMax && (stack>pixScrollMax || i==axis.maxCellSizes.length-1)){
						// find the first visible row
						foundPixMax = true;
						if(axis.scrollByLine){
							scrollMetrics.pageSize = axis.maxCellSizes.length-i;
							scrollMetrics.maximum = axis.maxCellSizes.length;
						}else{
							scrollMetrics.maximum = realMeas;
							scrollMetrics.pageSize = realDim;
						}
						if(isNaN(pixScroll)){
							pixScroll = pixScrollMax;
							comparePixScroll = pixScrollMax;
						}
						if(newIndexMax!=-1)break;
					}
					if(i<axis.maxCellSizes.length-1)stack += axis.gap;
				}
				if(newIndexMax==-1){
					newIndexMax = axis.maxCellSizes.length;
				}
			}else{
				var max:int = axis.maxCellSizes.length;
				newIndex = 0;
				pixScroll = 0;
				pixScrollMax = 0;
				for(i=0; i<axis.maxCellSizes.length; i++){
					measurement = axis.maxCellSizes[i];
					pixScrollMax += measurement;
					if(i<axis.maxCellSizes.length-1)pixScrollMax += axis.gap;
				}
				if(_protoRenderer){
					var defaultDim:Number = _protoRenderer.measurements[axis.coordRef];
					var leftOver:Number = (realDim-axis.foreMargin-axis.aftMargin-pixScrollMax);
					
					if(leftOver>0){
						var defMax:int = max+int(leftOver/(defaultDim+axis.gap));
						if(max<defMax){
							max = defMax;
							pixScrollMax += ((max-axis.maxCellSizes.length)*(defaultDim+axis.gap))-axis.gap;
						}
					}
				}
				newIndexMax = max;
				
				if(axis.scrollByLine){
					scrollMetrics.pageSize = axis.maxCellSizes.length;
					scrollMetrics.maximum = axis.maxCellSizes.length;
				}else{
					scrollMetrics.maximum = realDim;
					scrollMetrics.pageSize = realDim;
				}
			}
			var castAxis:RendererGridAxis = (axis as RendererGridAxis);
			castAxis.dimIndex = newIndex;
			castAxis.dimIndexMax = newIndexMax;
			
			if(axis.pixScrollMetrics.maximum != realMeas || axis.pixScrollMetrics.pageSize != realDim || axis.pixScrollMetrics.scrollValue != pixScroll){
				axis.pixScrollMetrics.maximum = realMeas;
				axis.pixScrollMetrics.pageSize = realDim;
				axis.pixScrollMetrics.scrollValue = pixScroll;
			}
		}
		protected function removeAllRenderers():void{
			for each(var renderer:ILayoutSubject in _renderers){
				rendererRemoved(renderer);
			}
			_renderers = [];
			clearMeasurements();
		}
		protected function clearMeasurements():void{
			_cellMeasCache = new Dictionary();
			_cellMeasFlag.invalidate();
			invalidateSize();
		}
		override protected function positionRenderer(key:*, acrossIndex:int, flowIndex:int, x:Number, y:Number, width:Number, height:Number):void{
			super.positionRenderer(key, acrossIndex, flowIndex, x, y, width, height);
			if(_collectDataPositions){
				var posIndex:int = (key as int)*int(4);
				_positionCache[posIndex] = x;
				_positionCache[posIndex+1] = y;
				_positionCache[posIndex+2] = width;
				_positionCache[posIndex+3] = height;
			}
			var coIndex:int = (key as int)*int(2);
			_coordCache[coIndex] = acrossIndex;
			_coordCache[coIndex+1] = flowIndex;
		}
		// TODO: use _dataToRenderers to optimise the lookup in this method
		override protected function getChildRenderer(key:*,acrossIndex:int,flowIndex:int):ILayoutSubject{
			var minAcross:int = _acrossRendAxis.dimIndex;
			var maxAcross:int = _acrossRendAxis.dimIndexMax;
			var minFlow:int = _flowRendAxis.dimIndex;
			var maxFlow:int = _flowRendAxis.dimIndexMax;
			
			var renderIndex:int = ((maxFlow-minFlow)*(acrossIndex-minAcross))+(flowIndex-minFlow);
			var renderer:ILayoutSubject = _renderers[renderIndex];
			
			if(acrossIndex>=minAcross && acrossIndex<maxAcross && flowIndex>=minFlow && flowIndex<maxFlow && (key<_dataCount || _renderEmptyCells)){
				
				var data:* = _dataMap[key];
				var addRenderer:Boolean = (renderer==null);
				if(addRenderer){
					renderer = _rendererFactory.createInstance();
					_renderers[renderIndex] = renderer;
					_cullRenderersFlag.invalidate();
				}
				if(renderer[_dataField] != data){
					renderer[_dataField] = data;
					if(addRenderer)rendererAdded(renderer);
					if(_setRendererDataAct)_setRendererDataAct.perform(this,renderer,data,_dataField);
				}
				_dataToRenderers[data] = renderer;
				return renderer;
			}else{
				if(renderer){
					delete _renderers[renderIndex];
					rendererRemoved(renderer);
				}
				return null;
			}
		}
	}
}