package org.farmcode.display.behaviour.controls.popoutList {
	import au.com.thefarmdigital.validation.ValidationEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.farmcode.acting.actTypes.IAct;
	import org.farmcode.acting.acts.Act;
	import org.farmcode.display.behaviour.containers.ListBox;
	import org.farmcode.display.behaviour.controls.TextLabelButton;
	import org.farmcode.display.behaviour.misc.PopoutDisplay;
	import org.farmcode.display.layout.ILayoutSubject;
	
	[Event(name="select",type="flash.events.Event")]
	public class DropDownList extends PopoutList {
		public function set selectedIndex(value: int):void{
			if(_selectedIndex!=value){
				if(value==-1){
					_listBox.selectedIndices = [];
				}else{
					_listBox.selectedIndices = [value];
				}
				assessSelected();
			}
		}
		public function get selectedIndex() : int{
			return _selectedIndex;
		}
		public function get selectedData() : *{
			return _selectedData;
		}
		
		public function get dataProvider():*{
			return _listBox.dataProvider;
		}
		public function set dataProvider(value:*):void{
			if(_listBox.dataProvider != value){
				_selectedIndex = -1;
				_selectedData = null;
				_listBox.dataProvider = value;
				assessSelected();
			}
		}
		
		public function get prompt():String{
			return _prompt;
		}
		public function set prompt(value:String):void{
			if(_prompt!=value){
				_prompt = value;
				assessSelected();
			}
		}
		
		/**
		 * handler(dropDownList:DropDownList, selectedIndex:int, selectedData:*)
		 */
		public function get selectionChangeAct() : IAct{
			return _selectionChangeAct;
		}
		
		private var _prompt:String;
		private var _selectedIndex:int=-2; // -1 is unselected (initially -2 so that -1 is seen as a change)
		private var _selectedData:*;
		private var textLabelButton:TextLabelButton;
		private var _listAlignArea:Rectangle = new Rectangle();
		private var _listAlignMeas:Rectangle = new Rectangle();
		
		private var _selectionChangeAct:Act = new Act(); 
		
		public function DropDownList(asset:DisplayObject=null) {
			super(asset);
			textLabelButton=new TextLabelButton();
			textLabelButton.useDataForSelected = false;
			textLabelButton.measurementsChanged.addHandler(onTextMeasureChange);
			textLabelButton.addEventListener(ValidationEvent.VALIDATION_VALUE_CHANGED, onButtonClicked);
			_listBox.selectionChangeAct.addHandler(onListSelect);
		}
		protected function onListSelect(list:ListBox, selectedIndices:Array, selectedData:Dictionary):void {
			assessSelected();
			_popoutDisplay.popoutShown = false;
		}
		override protected function onPopoutOpen(popoutDisplay:PopoutDisplay, popout:ListBox):void {
			super.onPopoutOpen(popoutDisplay, popout);
			textLabelButton.selected = true;
		}
		override protected function onPopoutClose(popoutDisplay:PopoutDisplay, popout:ListBox):void {
			super.onPopoutClose(popoutDisplay, popout);
			textLabelButton.selected = false;
		}
		
		override protected function bindToAsset():void {
			super.bindToAsset();
			textLabelButton.asset=asset;
		}
		
		override protected function unbindFromAsset():void {
			super.unbindFromAsset();
			textLabelButton.asset=null;
		}
		override public function setDisplayPosition(x:Number, y:Number, width:Number, height:Number) : void{
			super.setDisplayPosition(x,y,width,height);
			textLabelButton.setDisplayPosition(x,y,width,height);
		}
		protected function onButtonClicked(e:Event):void {
			_popoutDisplay.popoutShown = textLabelButton.selected;
		}
		protected function onTextMeasureChange(from:ILayoutSubject, oldX:Number, oldY:Number, oldWidth:Number, oldHeight:Number):void{
			dispatchMeasurementChange();
		}
		override protected function getListAlignArea():Rectangle{
			_listAlignArea.width = displayPosition.width;
			_listAlignArea.height = displayPosition.height;
			return _listAlignArea;
		}
		override protected function getListAlignMeas():Rectangle{
			_listAlignMeas.width = textLabelButton.displayMeasurements.width;
			_listAlignMeas.height = textLabelButton.displayMeasurements.height;
			return _listAlignMeas;
		}
		override protected function closeOnClickOutside():Boolean{
			return true;
		}
		protected function assessSelected():void{
			var newIndex:int = (_listBox.selectedIndices.length?_listBox.selectedIndices[0]:-1);
			if(newIndex!=_selectedIndex){
				_selectedIndex = newIndex;
				if(_selectedIndex==-1){
					_selectedData = null;
					textLabelButton.data = prompt;
				}else{
					_selectedData = _listBox.selectedData[_selectedIndex];
					textLabelButton.data = _selectedData;
				}
				_selectionChangeAct.perform(this,_selectedIndex,_selectedData);
			}
		}
	}
}