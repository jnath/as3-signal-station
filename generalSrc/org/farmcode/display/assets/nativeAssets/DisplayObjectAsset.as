package org.farmcode.display.assets.nativeAssets {
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.farmcode.acting.actTypes.IAct;
	import org.farmcode.acting.acts.NativeAct;
	import org.farmcode.display.assets.IAsset;
	import org.farmcode.display.assets.IContainerAsset;
	import org.farmcode.display.assets.IDisplayAsset;
	import org.farmcode.display.assets.IStageAsset;
	import org.farmcode.instanceFactory.*;
	
	
	public class DisplayObjectAsset extends Asset implements IDisplayAsset {
		/**
		 * @inheritDoc
		 */
		public function get addedToStage():IAct {
			if(!_addedToStage)
				_addedToStage = new NativeAct(_displayObject, Event.ADDED_TO_STAGE, [this]);
			return _addedToStage;
		}
		/**
		 * @inheritDoc
		 */
		public function get removedFromStage():IAct {
			if(!_removedFromStage)
				_removedFromStage = new NativeAct(_displayObject, Event.REMOVED_FROM_STAGE, [this]);
			return _removedFromStage;
		}
		/**
		 * @inheritDoc
		 */
		public function get added():IAct {
			if(!_added)
				_added = new NativeAct(_displayObject, Event.ADDED, [this]);
			return _added;
		}
		/**
		 * @inheritDoc
		 */
		public function get removed():IAct {
			if(!_removed)
				_removed = new NativeAct(_displayObject, Event.REMOVED, [this]);
			return _removed;
		}
		/**
		 * @inheritDoc
		 */
		public function get enterFrame():IAct {
			if(!_enterFrame)
				_enterFrame = new NativeAct(_displayObject, Event.ENTER_FRAME, [this]);
			return _enterFrame;
		}
		
		
		public function get displayObject():DisplayObject {
			return _displayObject;
		}
		
		
		public function set displayObject(value:DisplayObject):void {
			if(_displayObject!=value) {
				if(_displayObject) {
					_innerBounds = null;
				}
				_displayObject = value;
				if(_displayObject) {
					_innerBounds = value.getBounds(value);
					takePosition();
				}
				if(_addedToStage)
					_addedToStage.eventDispatcher = value;
				
				if(_removedFromStage)
					_removedFromStage.eventDispatcher = value;
				
				if(_added)
					_added.eventDispatcher = value;
				
				if(_removed)
					_removed.eventDispatcher = value;
				
				if(_enterFrame)
					_enterFrame.eventDispatcher = value;
			}
		}
		
		
		private var _addedToStage:NativeAct;
		private var _removedFromStage:NativeAct;
		private var _added:NativeAct;
		private var _removed:NativeAct;
		private var _enterFrame:NativeAct;
		
		private var _displayObject:DisplayObject;
		
		protected var _innerBounds:Rectangle;
		private var _x:Number;
		private var _y:Number;
		private var _forceTopLeft:Boolean = true;
		
		
		public function DisplayObjectAsset() {
		}
		
		
		// we'll get rid of this soon, please don't use it (it's for DelayedDrawer only)
		public function get drawDisplay():DisplayObject {
			return _displayObject;
		}
		
		
		public function get forceTopLeft():Boolean {
			return _forceTopLeft;
		}
		public function set forceTopLeft(value:Boolean):void{
			if(_forceTopLeft!=value){
				_forceTopLeft = value;
				applyPosition();
			}
		}
		public function get naturalWidth():Number {
			return _innerBounds.width;
		}
		public function get naturalHeight():Number {
			return _innerBounds.height;
		}
		public function get mouseX():Number {
			return(_displayObject.mouseX-_innerBounds.x)/_displayObject.scaleX;
		}
		public function get mouseY():Number {
			return(_displayObject.mouseY-_innerBounds.y)/_displayObject.scaleY;
		}
		public function set visible(value:Boolean):void {
			_displayObject.visible = value;
		}
		public function get visible():Boolean {
			return _displayObject.visible;
		}
		public function set name(value:String):void {
			_displayObject.name = value;
		}
		public function get name():String {
			return _displayObject.name;
		}
		public function set alpha(value:Number):void {
			_displayObject.alpha = value;
		}
		public function get alpha():Number {
			return _displayObject.alpha;
		}
		public function set blendMode(value:String):void {
			_displayObject.blendMode = value;
		}
		public function get blendMode():String {
			return _displayObject.blendMode;
		}
		public function set x(value:Number):void {
			_x = value;
			applyX();
		}
		public function get x():Number {
			takePosition();
			return _x;
		}
		public function set y(value:Number):void {
			_y = value;
			applyY();
		}
		public function get y():Number {
			takePosition();
			return _y;
		}
		public function set scrollRect(value:Rectangle):void {
			_displayObject.scrollRect = value;
			applyX();
			applyY();
		}
		public function get scrollRect():Rectangle {
			return _displayObject.scrollRect;
		}
		public function set width(value:Number):void {
			if(value && _innerBounds.width) {
				_displayObject.width = value;
			} else {
				_displayObject.scaleX = 1;
			}
			applyX();
		}
		public function get width():Number {
			return _displayObject.width;
		}
		public function set scaleX(value:Number):void {
			_displayObject.scaleX = value;
			applyX();
		}
		public function get scaleX():Number {
			return _displayObject.scaleX;
		}
		public function set scaleY(value:Number):void {
			_displayObject.scaleY = value;
			applyX();
		}
		public function get scaleY():Number {
			return _displayObject.scaleY;
		}
		public function set rotation(value:Number):void {
			_displayObject.rotation = value;
		}
		public function get rotation():Number {
			return _displayObject.rotation;
		}
		
		
		public function set height(value:Number):void {
			if(value && _innerBounds.height) {
				_displayObject.height = value;
			} else {
				_displayObject.scaleY = 1;
			}
			applyY();
		}
		
		
		public function get height():Number {
			return _displayObject.height;
		}
		
		
		public function get stage():IStageAsset {
			return _displayObject && _displayObject.stage?NativeAssetFactory.getNew(_displayObject.stage):null;
		}
		
		
		public function get parent():IContainerAsset {
			return _displayObject && _displayObject.parent?NativeAssetFactory.getNew(_displayObject.parent):null;
		}
		
		
		protected function takePosition():void {
			takeX();
			takeY();
		}
		
		
		protected function takeX():void {
			_x = _displayObject.x+_innerBounds.x*_displayObject.scaleX;
		}
		
		
		protected function takeY():void {
			_y = _displayObject.y+_innerBounds.y*_displayObject.scaleY;
		}
		
		
		protected function applyPosition():void {
			applyX();
			applyY();
		}
		
		
		protected function applyX():void {
			if(_displayObject.scrollRect || !_forceTopLeft){
				_displayObject.x = _x;
			}else{
				_displayObject.x = _x-_innerBounds.x*_displayObject.scaleX;
			}
		}
		
		
		protected function applyY():void {
			if(_displayObject.scrollRect || !_forceTopLeft){
				_displayObject.y = _y;
			}else{
				_displayObject.y = _y-_innerBounds.y*_displayObject.scaleY;
			}
		}
		
		
		public function position(x:Number, y:Number, width:Number, height:Number):void {
			this.x = x;
			this.y = y;
			this.width = width;
			this.height = height;
		}
		
		
		public function globalToLocal(point:Point):Point {
			return _displayObject.globalToLocal(point);
		}
		
		
		public function localToGlobal(point:Point):Point {
			return _displayObject.localToGlobal(point);
		}
		
		public function getCloneFactory():IInstanceFactory{
			return NativeAssetFactory.getCloneFactory(this);
		}
		override public function release():void {
			_forceTopLeft = true;
			super.release();
		}
	}
}