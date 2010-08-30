package org.farmcode.display.controls
{
	
	import org.farmcode.acting.actTypes.IAct;
	import org.farmcode.acting.acts.Act;
	import org.farmcode.core.DelayedCall;
	import org.farmcode.display.DisplayNamespace;
	import org.farmcode.display.assets.assetTypes.IDisplayAsset;
	import org.farmcode.display.assets.assetTypes.IInteractiveObjectAsset;
	import org.farmcode.display.constants.Direction;
	
	use namespace DisplayNamespace;
	
	public class Slider extends Control
	{
		private static const TRACK:String = "track";
		private static const THUMB:String = "thumb";
		
		
		public function get direction():String{
			return _direction?_direction:_assumedDirection;
		}
		public function set direction(value:String):void{
			if(_direction!=value){
				_direction = value;
				invalidate();
			}
		}
		
		public function get maximum():Number{
			return _maximum;
		}
		public function set maximum(value:Number):void{
			if(_maximum!=value){
				_maximum = value;
				invalidate();
			}
		}
		
		public function get minimum():Number{
			return _minimum;
		}
		public function set minimum(value:Number):void{
			if(_minimum!=value){
				_minimum = value;
				invalidate();
			}
		}
		
		public function get updateDuringDrag():Boolean{
			return _updateDuringDrag;
		}
		public function set updateDuringDrag(value:Boolean):void{
			if(_updateDuringDrag!=value){
				_updateDuringDrag = value;
			}
		}
		
		public function get value():Number{
			if(_value<_minimum){
				return minimum;
			}else if(_value>maximum){
				return maximum;
			}else{
				return _value;
			}
		}
		public function set value(value:Number):void{
			if(_value!=value && !_dragDelay.running){
				_value = value;
				if(_valueChange)_valueChange.perform(this,this.value);
				invalidate();
			}
		}
		
		
		/**
		 * handler(from:Slider, value:Number)
		 */
		public function get valueChange():IAct{
			if(!_valueChange)_valueChange = new Act();
			return _valueChange;
		}
		/**
		 * handler(from:Slider, value:Number)
		 */
		public function get valueChangeByUser():IAct{
			if(!_valueChangeByUser)_valueChangeByUser = new Act();
			return _valueChangeByUser;
		}
		
		private var _valueChangeByUser:Act;
		private var _valueChange:Act;
		
		private var _value:Number = 0;
		private var _minimum:Number = 0;
		private var _maximum:Number = 1;
		private var _direction:String;
		private var _updateDuringDrag:Boolean = false;
		
		private var _trackButton:Button = new Button();
		private var _thumb:Button = new Button();
		private var _track:IDisplayAsset;
		private var _ignoreThumb:Boolean;
		
		private var _assumedDirection:String;
		private var _assumedThumbX:Number;
		private var _assumedThumbY:Number;
		
		private var _dragOffset:Number;
		private var _dragStartValue:Number;
		private var _dragDelay:DelayedCall = new DelayedCall(doDrag,1,false,null,0);
		
		public function Slider(){
			super();
		}
		override protected function init():void{
			super.init();
			_trackButton.scaleAsset = true;
			_trackButton.clicked.addHandler(onTrackClick);
			_thumb.mousePressed.addHandler(onThumbMouseDown);
			_thumb.mouseReleased.addHandler(onThumbMouseUp);
		}
		override protected function bindToAsset() : void{
			super.bindToAsset();
			
			_track = _containerAsset.takeAssetByName(TRACK,IInteractiveObjectAsset);
			_trackButton.asset = _track;
			
			_assumedDirection = (_track.width>_track.height?Direction.HORIZONTAL:Direction.VERTICAL);
			
			_thumb.asset = _containerAsset.takeAssetByName(THUMB,IInteractiveObjectAsset);
			
			_assumedThumbX = _thumb.asset.x;
			_assumedThumbY = _thumb.asset.y;
		}
		override protected function unbindFromAsset() : void{
			super.unbindFromAsset();
			_containerAsset.returnAsset(_trackButton.asset);
			_trackButton.asset = null;
			_containerAsset.returnAsset(_thumb.asset);
			_thumb.asset = null;
			_track = null;
		}
		override protected function draw() : void{
			var dir:String = direction;
			
			positionAsset();
			_asset.scaleX = 1;
			_asset.scaleY = 1;
			
			var fract:Number = (value-_minimum)/(_maximum-_minimum);
			_track.rotation = _thumb.asset.rotation = (dir!=_assumedDirection?90:0);
			
			var thumbX:Number;
			var thumbY:Number;
			var trackX:Number;
			var trackY:Number;
			var trackWidth:Number;
			var trackHeight:Number;
			if(dir==Direction.VERTICAL){
				var natWidth:Number = _track.width/_track.scaleX;
				if(natWidth<displayPosition.width){
					trackWidth = natWidth;
					trackX = (displayPosition.width-_track.width)/2;
				}else{
					trackWidth = displayPosition.width;
					trackX = 0;
				}
				trackHeight = displayPosition.height;
				trackY = 0;
				thumbX = _assumedThumbX;
				thumbY = _track.y+(_track.height-_thumb.asset.height)*fract;
			}else{
				var natHeight:Number = _track.height/_track.scaleY;
				if(natHeight<displayPosition.height){
					trackHeight = natHeight;
					trackY = (displayPosition.height-_track.height)/2;
				}else{
					trackHeight = displayPosition.height;
					trackY = 0;
				}
				trackWidth = displayPosition.width;
				trackX = 0;
				thumbY = _assumedThumbY;
				thumbX = trackX+(trackWidth-_thumb.asset.width)*fract;
			}
			_thumb.setDisplayPosition(thumbX,thumbY,_thumb.asset.width,_thumb.asset.height);
			_trackButton.setDisplayPosition(trackX,trackY,trackWidth,trackHeight);
		}
		override public function setAssetAndPosition(asset:IDisplayAsset) : void{
			super.setAssetAndPosition(asset);
			checkIsBound();
		}
		protected function onTrackClick(from:Button):void{
			_dragOffset = 0;
			setValueToMouse();
		}
		protected function onThumbMouseDown(from:Button):void{
			if(_ignoreThumb)return;
			if(direction==Direction.VERTICAL){
				_dragOffset = _thumb.asset.mouseY-_thumb.asset.height/2;
			}else{
				_dragOffset = _thumb.asset.mouseX-_thumb.asset.width/2;
			}
			_dragStartValue = _value;
			_dragDelay.begin();
		}
		protected function doDrag():void{
			setValueToMouse();
		}
		protected function onThumbMouseUp(from:Button):void{
			if(_ignoreThumb || !_dragDelay.running)return;
			_dragDelay.clear();
			setValueToMouse();
			_dragOffset = 0;
			if(!_updateDuringDrag && _dragStartValue!=_value){
				if(_valueChange)_valueChange.perform(this,_value);
				if(_valueChangeByUser)_valueChangeByUser.perform(this,_value);
			}
		}
		protected function setValueToMouse():void{
			var newVal:Number;
			if(direction==Direction.VERTICAL){
				newVal = (asset.mouseY-_dragOffset-_thumb.asset.height/2)/(_track.height-_thumb.asset.height)
			}else{
				newVal = (asset.mouseX-_dragOffset-_thumb.asset.width/2)/(_track.width-_thumb.asset.width)
			}
			newVal = (newVal*(maximum-minimum))+minimum;
			if(_value!=newVal){
				_value = newVal;
				_ignoreThumb = true;
				validate(true);
				_ignoreThumb = false;
				if(_updateDuringDrag || !_dragDelay.running){
					if(_valueChange)_valueChange.perform(this,_value);
					if(_valueChangeByUser)_valueChangeByUser.perform(this,_value);
				}
			}
		}
	}
}