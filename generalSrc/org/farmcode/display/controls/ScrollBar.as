package org.farmcode.display.controls
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import org.farmcode.acting.actTypes.IAct;
	import org.farmcode.acting.acts.Act;
	import org.farmcode.display.DisplayNamespace;
	import org.farmcode.display.actInfo.IMouseActInfo;
	import org.farmcode.display.assets.assetTypes.IDisplayAsset;
	import org.farmcode.display.assets.assetTypes.IInteractiveObjectAsset;
	import org.farmcode.display.assets.assetTypes.ISpriteAsset;
	import org.farmcode.display.constants.Direction;
	import org.farmcode.display.core.LayoutView;
	import org.farmcode.display.scrolling.IScrollable;
	import org.farmcode.display.scrolling.ScrollMetrics;
	
	use namespace DisplayNamespace;
	
	public class ScrollBar extends LayoutView
	{
		// amount of second between clicking the foreButton/aftButton and the scrolling beginning
		// i.e. it moves once due to the click, but then waits before scrolling further.
		private static const SCROLL_DELAY:Number = 0.4;
		private static const SCROLL_DURATION:Number = 0.05;
		
		private static const TRACK_CHILD:String = "track";
		private static const SCROLL_THUMB_CHILD:String = "scrollThumb";
		private static const FORE_BUTTON_CHILD:String = "foreButton";
		private static const AFT_BUTTON_CHILD:String = "aftButton";
		
		protected static const EMPTY_POINT:Point = new Point();
		
		public function set scrollSubject(to:IScrollable):void{
			if(_scrollSubject != to){
				if(_scrollSubject){
					_scrollSubject.mouseWheel.removeHandler(onSubjectMouseWheel);
					_scrollSubject.scrollMetricsChanged.removeHandler(getSubjectMetrics);
				}
				_scrollSubject = to;
				if (_scrollSubject) {
					_scrollSubject.scrollMetricsChanged.addHandler(getSubjectMetrics);
					if(_scrollSubject.addScrollWheelListener(_direction)){
						_scrollSubject.mouseWheel.addHandler(onSubjectMouseWheel);
					}
					scrollMetrics = _scrollSubject.getScrollMetrics(_direction);
				}
			}
		}
		public function get scrollSubject():IScrollable{
			return _scrollSubject;
		}
		public function set scrollMetrics(value:ScrollMetrics):void{
			if((_scrollMetrics == null && value != null) ||
				(_scrollMetrics != null && value == null) ||
				!_scrollMetrics.equals(value)
			)
			{
				if(value){
					_scrollMetrics.maximum = value.maximum;
					_scrollMetrics.minimum = value.minimum;
					_scrollMetrics.pageSize = value.pageSize;
					_scrollMetrics.value = value.value;
				}else{
					_scrollMetrics.value = NaN;
				}
				invalidate();
			}
		}
		public function get scrollMetrics():ScrollMetrics{
			return _scrollMetrics;
		}
		public function set scrollLines(to:Number):void{
			_scrollLines = to;
		}
		public function get scrollLines():Number{
			return _scrollLines;
		}
		public function set direction(to:String):void{
			if(_direction != to){
				_direction = to;
				if(_scrollSubject)_scrollMetrics = _scrollSubject.getScrollMetrics(_direction);
				performMeasChanged();
				invalidate();
			}
		}
		public function get direction():String{
			return _direction;
		}
		
		[Inspectable(defaultValue=true, type="Boolean")]
		/**
		 * sizeThumbToContent determines whether to alter the scroll thumb/handle height 
		 * proportionately to the scroll content size
		 */
		public function set sizeThumbToContent(to:Boolean):void{
			if(_sizeThumbToContent != to){
				_sizeThumbToContent = to;
				invalidate();
			}
		}
		public function get sizeThumbToContent():Boolean{
			return _sizeThumbToContent;
		}
		/**
		 * rotateForHorizontal determines whether the inner buttons will be rotated
		 * when the direction is changed to horizontal.
		 */
		public function set rotateForHorizontal(to:Boolean):void{
			if(_rotateForHorizontal != to){
				_rotateForHorizontal = to;
				invalidate();
			}
		}
		public function get rotateForHorizontal():Boolean{
			return _rotateForHorizontal;
		}
		public function set useHandCursor(value:Boolean):void{
			if(_useHandCursor != value){
				_useHandCursor = value;
				_track.useHandCursor = _useHandCursor;
				_aftButton.useHandCursor = _useHandCursor;
				_foreButton.useHandCursor = _useHandCursor;
				_scrollThumb.useHandCursor = _useHandCursor;
			}
		}
		public function get useHandCursor():Boolean{
			return _useHandCursor;
		}
		
		[Inspectable(defaultValue=true, type="Boolean")]
		public function set hideWhenUnusable(to:Boolean):void{
			if(_hideWhenUnusable != to){
				this._hideWhenUnusable = to;
				invalidate();
			}
		}
		public function get hideWhenUnusable():Boolean{
			return _hideWhenUnusable;
		}
		public function get isUsable():Boolean{
			validate();
			return _isUsable;
		}
		
		/**
		 * Setting groupButtons to true makes the fore and aft buttons
		 * to sit next to each other at the end of the track (as opposed
		 * to sitting either side of the track).
		 */
		public function get groupButtons():Boolean{
			return _groupButtons;
		}
		public function set groupButtons(value:Boolean):void{
			if(_groupButtons!=value){
				_groupButtons = value;
			}
		}
		
		
		/**
		 * handler(from:ScrollBar, scrollMetrics:ScrollMetrics)
		 */
		public function get scroll():IAct{
			if(!_scroll)_scroll = new Act();
			return _scroll;
		}
		
		protected var _scroll:Act;
		
		private var _groupButtons:Boolean;
		protected var _hideWhenUnusable:Boolean = true;
		protected var _isUsable:Boolean = true;
		protected var _sizeThumbToContent:Boolean = true;
		protected var _scrollMetrics:ScrollMetrics = new ScrollMetrics(0,0,0);
		protected var _scrollSubject:IScrollable;
		protected var _dragOffset:Number;
		protected var _scrollLines:Number = 1;
		protected var _scrollIncrement:Number;
		protected var _scrollInterval:Number;
		protected var _useHandCursor:Boolean = false;
		protected var _direction:String = Direction.VERTICAL;
		protected var _rotateForHorizontal:Boolean = true;
		protected var _scrollTimer:Timer;
		
		protected var _track:Button = new Button();
		protected var _scrollThumb:Button = new Button();
		protected var _foreButton:Button = new Button();
		protected var _aftButton:Button = new Button();
		
		public function ScrollBar(asset:IDisplayAsset=null){
			super(asset);
		}
		override protected function init(): void{
			super.init();
			_scrollMetrics = new ScrollMetrics(0,1,1);
			_scrollMetrics.value = 0;
			
			_track.clicked.addHandler(scrollToMouse);
			_scrollThumb.mousePressed.addHandler(beginDrag);
			_foreButton.mousePressed.addHandler(beginScroll);
			_aftButton.mousePressed.addHandler(beginScroll);
			
			_track.scaleAsset = true;
			_scrollThumb.scaleAsset = true;
			_foreButton.scaleAsset = true;
			_aftButton.scaleAsset = true;
		}
		
		override protected function bindToAsset(): void{
			_interactiveObjectAsset.mouseWheel.addHandler(onMouseWheel);
			
			_track.setAssetAndPosition(_containerAsset.takeAssetByName(TRACK_CHILD,ISpriteAsset));
			_scrollThumb.setAssetAndPosition(_containerAsset.takeAssetByName(SCROLL_THUMB_CHILD,ISpriteAsset));
			_foreButton.setAssetAndPosition(_containerAsset.takeAssetByName(FORE_BUTTON_CHILD,ISpriteAsset,true));
			_aftButton.setAssetAndPosition(_containerAsset.takeAssetByName(AFT_BUTTON_CHILD,ISpriteAsset,true));
		}
		override protected function unbindFromAsset(): void{
			_interactiveObjectAsset.mouseWheel.removeHandler(onMouseWheel);
			
			var asset:IDisplayAsset = _track.asset;
			_track.asset = null;
			_containerAsset.returnAsset(asset);
			
			asset = _scrollThumb.asset;
			_scrollThumb.asset = null;
			_containerAsset.returnAsset(asset);
			
			asset = _foreButton.asset;
			_foreButton.asset = null;
			_containerAsset.returnAsset(asset);
			
			asset = _aftButton.asset;
			_aftButton.asset = null;
			_containerAsset.returnAsset(asset);
		}
		override protected function measure(): void{
			var trackMeas:Point = _track.measurements;
			var thumbMeas:Point = _scrollThumb.measurements;
			var foreMeas:Point = _foreButton.asset?_foreButton.measurements:EMPTY_POINT;
			var aftMeas:Point = _aftButton.asset?_foreButton.measurements:EMPTY_POINT;
			
			if(_direction==Direction.VERTICAL){
				_measurements.x = Math.max(thumbMeas.x,trackMeas.x, foreMeas.x, aftMeas.x);
				_measurements.y = foreMeas.y+aftMeas.y;
			}else if(_rotateForHorizontal){
				_measurements.y = Math.max(thumbMeas.x,trackMeas.x, foreMeas.x, aftMeas.x);
				_measurements.x = foreMeas.y+aftMeas.y;
			}else{
				_measurements.y = Math.max(thumbMeas.y, trackMeas.y, foreMeas.y, aftMeas.y);
				_measurements.x = foreMeas.x+aftMeas.x;
			}
		}
		
		public function setToMinimum(): void {
			if (this._scrollMetrics != null) {
				this._scrollMetrics.value = this._scrollMetrics.minimum;
				this.commitScrollMetrics(true);
			}
		}
		override protected function positionAsset():void{
			if(_direction==Direction.VERTICAL || !_rotateForHorizontal){
				super.positionAsset();
				asset.rotation = 0;
			}else{
				asset.rotation = -90;
				asset.setPosition(displayPosition.x,displayPosition.y+displayPosition.height);
			}
		}
		override protected function draw():void{
			positionAsset();
			var scope:Number = (_scrollMetrics.maximum-_scrollMetrics.pageSize-_scrollMetrics.minimum);
			var rawRatio:Number;
			var ratio:Number;
			_isUsable = (_scrollMetrics.pageSize<_scrollMetrics.maximum-_scrollMetrics.minimum);
			if(!_isUsable){
				rawRatio = ratio = 0;
				// Only change the visibility if the user has asked us to manage the visibility
				if(this.hideWhenUnusable){
					asset.visible = false
				}
			}else{
				rawRatio = (_scrollMetrics.value-_scrollMetrics.minimum)/scope;
				ratio = (scope?Math.min(Math.max(rawRatio,0),1):0);
				// Only change the visibility if the user has asked us to manage the visibility
				if (this.hideWhenUnusable)
				{
					asset.visible = true;
				}
			}
			var sizeFraction:Number = (_scrollMetrics.maximum>_scrollMetrics.minimum?_scrollMetrics.pageSize/(_scrollMetrics.maximum-_scrollMetrics.minimum):1);
			
			_track.active = _isUsable;
			_scrollThumb.active = _isUsable;
			_foreButton.active = _isUsable;
			_aftButton.active = _isUsable;
			
			var trackMeas:Point = _track.measurements;
			var thumbMeas:Point = _scrollThumb.measurements;
			var foreMeas:Point = _foreButton.asset?_foreButton.measurements:EMPTY_POINT;
			var aftMeas:Point = _aftButton.asset?_foreButton.measurements:EMPTY_POINT;
			
			var trackX:Number;
			var trackY:Number;
			var trackWidth:Number;
			var trackHeight:Number;
			
			var thumbX:Number;
			var thumbY:Number;
			var thumbWidth:Number;
			var thumbHeight:Number;
			
			var foreX:Number;
			var foreY:Number;
			var foreWidth:Number;
			var foreHeight:Number;
			
			var aftX:Number;
			var aftY:Number;
			var aftWidth:Number;
			var aftHeight:Number;
			
			var isVert:Boolean = _direction==Direction.VERTICAL;
				
			if(isVert || _rotateForHorizontal){
				var height:Number;
				var width:Number;
				if(isVert){
					height = displayPosition.height;
					width = displayPosition.width;
				}else{
					height = displayPosition.width;
					width = displayPosition.height;
				}
				
				var buttonHeight:Number = foreMeas.y+aftMeas.y;
				if(height<buttonHeight){
					aftHeight = height*(aftMeas.y/buttonHeight);
					foreHeight = height*(foreMeas.y/buttonHeight);
				}else{
					aftHeight = aftMeas.y;
					foreHeight = foreMeas.y;
				}
				if(_groupButtons){
					trackHeight = height-foreHeight-aftHeight;
					trackY = 0;
					foreY = trackHeight;
					aftY = foreY+foreHeight;
				}else{
					foreY = 0;
					trackHeight = height-foreHeight-aftHeight;
					trackY = foreHeight;
					aftY = trackY+trackHeight;
				}
				
				if(_scrollThumb && _track){
					if (_sizeThumbToContent) {
						thumbHeight = Math.min(trackHeight*sizeFraction,trackHeight);
					}else{
						thumbHeight = thumbMeas.y;
					}
					thumbY = ((trackHeight-thumbHeight)*ratio)+trackY;
				}
				
				if(trackMeas.x<width){
					trackWidth = trackMeas.x;
					trackX = (width-trackWidth)/2;
				}else{
					trackWidth = width;
					trackX = 0;
				}
				if(thumbMeas.x<width){
					thumbWidth = thumbMeas.x;
					thumbX = (width-thumbWidth)/2;
				}else{
					thumbWidth = width;
					thumbX = 0;
				}
				if(foreMeas.x<width){
					foreWidth = foreMeas.x;
					foreX = (width-foreWidth)/2;
				}else{
					foreWidth = width;
					foreX = 0;
				}
				if(aftMeas.x<width){
					aftWidth = aftMeas.x;
					aftX = (width-aftWidth)/2;
				}else{
					aftWidth = width;
					aftX = 0;
				}
			}else{
				var buttonWidth:Number = foreMeas.x+aftMeas.x;
				if(displayPosition.width<buttonWidth){
					aftWidth = displayPosition.width*(aftMeas.x/buttonWidth);
					foreWidth = displayPosition.width*(foreMeas.x/buttonWidth);
				}else{
					aftWidth = aftMeas.x;
					foreWidth = foreMeas.x;
				}
				
				if(_groupButtons){
					trackWidth = displayPosition.width-foreHeight-aftWidth;
					trackX = 0;
					foreX = trackWidth;
					aftX = foreX+foreWidth;
				}else{
					foreX = 0;
					trackWidth = displayPosition.width-foreHeight-aftWidth;
					trackX = foreWidth;
					aftX = trackX+trackWidth;
				}
				
				if(_scrollThumb && _track){
					if (sizeThumbToContent){
						thumbWidth = Math.min(trackWidth*sizeFraction,trackWidth);
					}else{
						thumbWidth = thumbMeas.x;
					}
					thumbX = ((trackWidth-thumbWidth)*ratio)+trackX;
				}
				
				
				if(trackMeas.y<displayPosition.height){
					trackHeight = trackMeas.y;
					trackY = (displayPosition.height-trackHeight)/2;
				}else{
					trackHeight = displayPosition.height;
					trackY = 0;
				}
				if(thumbMeas.y<displayPosition.height){
					thumbHeight = thumbMeas.y;
					thumbY = (displayPosition.height-thumbHeight)/2;
				}else{
					thumbHeight = displayPosition.height;
					thumbY = 0;
				}
				if(foreMeas.y<displayPosition.height){
					foreHeight = foreMeas.y;
					foreY = (displayPosition.height-foreHeight)/2;
				}else{
					foreHeight = displayPosition.height;
					foreY = 0;
				}
				if(aftMeas.y<displayPosition.height){
					aftHeight = aftMeas.y;
					aftY = (displayPosition.height-aftHeight)/2;
				}else{
					aftHeight = displayPosition.height;
					aftY = 0;
				}
			}
			_track.setDisplayPosition(trackX,trackY,trackWidth,trackHeight);
			_scrollThumb.setDisplayPosition(thumbX,thumbY,thumbWidth,thumbHeight);
			_foreButton.setDisplayPosition(foreX,foreY,foreWidth,foreHeight);
			_aftButton.setDisplayPosition(aftX,aftY,aftWidth,aftHeight);
		}
		protected function scrollToMouse(... params):void{
			var offset:Number;
			var ratio:Number;
			if(_direction==Direction.VERTICAL || _rotateForHorizontal){
				offset = (!isNaN(_dragOffset)?_dragOffset:(_scrollThumb?_scrollThumb.displayPosition.height/2:0));
				ratio = Math.max(Math.min((asset.mouseY-offset-_track.displayPosition.y)/(_track.displayPosition.height-_scrollThumb.displayPosition.height),1),0);
			}else{
				offset = (!isNaN(_dragOffset)?_dragOffset:(_scrollThumb?_scrollThumb.displayPosition.width/2:0));
				ratio = Math.max(Math.min((asset.mouseX-offset-_track.displayPosition.x)/(_track.displayPosition.width-_scrollThumb.displayPosition.width),1),0);
			}
			_scrollMetrics.value = Math.round((ratio*(_scrollMetrics.maximum-_scrollMetrics.pageSize-_scrollMetrics.minimum))+_scrollMetrics.minimum);
			this.commitScrollMetrics(true);
		}
		
		protected function beginDrag(... params):void{
			if(_scrollThumb){
				if(_direction==Direction.VERTICAL || _rotateForHorizontal){
					_dragOffset = asset.mouseY-_scrollThumb.displayPosition.y;
				}else{
					_dragOffset = asset.mouseX-_scrollThumb.displayPosition.x;
				}
			}else{
				_dragOffset = NaN;
			}
			scrollToMouse();
			asset.stage.mouseMoved.addHandler(scrollToMouse);
			asset.stage.mousePressed.addHandler(endDrag);
		}
		protected function endDrag(... params):void{
			scrollToMouse();
			asset.stage.mouseMoved.removeHandler(scrollToMouse);
			asset.stage.mousePressed.removeHandler(endDrag);
			_dragOffset = NaN;
		}
		
		protected function beginScroll(from:Button):void{
			_scrollIncrement = (from==_foreButton?-scrollLines:(from==_aftButton?scrollLines:NaN));
			if(!isNaN(_scrollIncrement)){
				if(_scrollSubject){
					var subjMultiplier:Number = _scrollSubject.getScrollMultiplier(_direction);
					if(!isNaN(subjMultiplier))_scrollIncrement *= subjMultiplier;
				}
				doScroll();
				_scrollTimer = new Timer(SCROLL_DELAY*1000,1);
				_scrollTimer.addEventListener(TimerEvent.TIMER_COMPLETE,beginFrameScroll);
				_scrollTimer.start();
				
				asset.stage.mousePressed.addHandler(endScroll);
			}
		}
		protected function beginFrameScroll(e:Event):void{
			_scrollTimer = new Timer(SCROLL_DURATION*1000);
			_scrollTimer.addEventListener(TimerEvent.TIMER,doScroll);
			_scrollTimer.start();
		}
		protected function doScroll(e:Event=null):void{
			_scrollMetrics.value = Math.min(Math.max(_scrollMetrics.value+_scrollIncrement,_scrollMetrics.minimum),_scrollMetrics.maximum-_scrollMetrics.pageSize);
			this.commitScrollMetrics(true);
		}
		
		private function commitScrollMetrics(validateNow: Boolean = false): void
		{
			if(_scrollSubject)
			{
				_scrollSubject.setScrollMetrics(_direction,_scrollMetrics);
			}
			if(_scroll)_scroll.perform(this,_scrollMetrics);
			if (validateNow)
			{
				this.validate(true);
			}
		}
		
		protected function endScroll(from:IInteractiveObjectAsset, info:IMouseActInfo):void{
			if(_scrollTimer){
				_scrollTimer.stop();
				_scrollTimer = null;
			}
			asset.stage.mousePressed.removeHandler(endScroll);
		}
		protected function onSubjectMouseWheel(from:IScrollable, delta:int):void{
			doMouseWheel(delta);
		}
		protected function onMouseWheel(from:IInteractiveObjectAsset, mouseActInfo:IMouseActInfo, delta:int):void{
			doMouseWheel(delta);
		}
		protected function doMouseWheel(delta:int):void{
			if(_scrollMetrics.pageSize>_scrollMetrics.maximum-_scrollMetrics.minimum){
				_scrollMetrics.value = 0;
			}else{
				var dist:Number = delta;
				if(_scrollSubject){
					var subjMultiplier:Number = _scrollSubject.getScrollMultiplier(_direction);
					if(!isNaN(subjMultiplier))dist *= subjMultiplier;
				}
				_scrollMetrics.value = Math.min(Math.max(_scrollMetrics.value-dist*scrollLines,_scrollMetrics.minimum),_scrollMetrics.maximum-_scrollMetrics.pageSize);
			}
			this.commitScrollMetrics(true);
		}
		protected function getSubjectMetrics(from:IScrollable, direction:String, metrics:ScrollMetrics):void{
			if(direction==_direction){
				scrollMetrics = _scrollSubject.getScrollMetrics(_direction);
			}
		}
	}
}