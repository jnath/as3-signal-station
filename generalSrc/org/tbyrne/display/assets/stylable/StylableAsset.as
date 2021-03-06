package org.tbyrne.display.assets.stylable
{
	import flash.display.Shape;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import org.tbyrne.display.assets.IAssetFactory;
	import org.tbyrne.display.assets.schema.AbstractDynamicAsset;
	import org.tbyrne.display.assets.schemaTypes.IAssetSchema;
	import org.tbyrne.display.assets.states.IStateDef;
	import org.tbyrne.display.assets.states.StateDef;
	import org.tbyrne.display.assets.stylable.styles.IRectangleStyle;
	import org.tbyrne.display.assets.stylable.styles.IStyle;
	import org.tbyrne.display.assets.stylable.styles.ITextStyle;
	
	public class StylableAsset extends AbstractDynamicAsset
	{
		override public function set schema(value:IAssetSchema):void{
			super.schema = value;
			checkRectStyles();
			checkTextStyles();
			findAvailableStates();
		}
		
		override public function set useParentStateLists(value:Boolean):void{
			if(_useParentStateLists!=value){
				super.useParentStateLists = value;
				if(value){
					removeStateList(_nullStateList);
				}else{
					addStateList(_nullStateList,false); // this allows stateless styles to be fallen back onto
				}
			}
		}
		public function get textStyles():Array{
			return _textStyles;
		}
		public function set textStyles(value:Array):void{
			if(_textStyles!=value){
				for each(var textStyle:ITextStyle in _matchingTextStyles){
					var styles:Array = _textStateMap[textStyle.stateName];
					var index:int = styles.indexOf(textStyle);
					styles.splice(index,1);
				}
				_textStyles = value;
				checkTextStyles();
				//_inDefaultMode = false;
				findAvailableStates();
			}
		}
		
		
		public function get rectangleStyles():Array{
			return _rectangleStyles;
		}
		public function set rectangleStyles(value:Array):void{
			if(_rectangleStyles!=value){
				for each(var rectStyle:IRectangleStyle in _matchingRectangleStyles){
					var styles:Array = _rectStateMap[rectStyle.stateName];
					var index:int = styles.indexOf(rectStyle);
					styles.splice(index,1);
				}
				_rectangleStyles = value;
				checkRectStyles();
				//_inDefaultMode = false;
				findAvailableStates();
			}
		}
		
		
		private var _nullStateList:Array;
		private var _rectangleStyles:Array;
		private var _textStyles:Array;
		// These lists are styles that match this asset (but not neccessarilty it's current state)
		protected var _matchingTextStyles:Array;
		protected var _matchingRectangleStyles:Array;
		// These lists are styles that match both the asset and it's current state (and have been applied)
		protected var _appliedTextStyles:Array = [];
		protected var _appliedRectStyles:Array = [];
		// These lists are styles are caches of the styles currently being applied
		protected var _applyingTextStyles:Array;
		protected var _applyingRectStyles:Array;
		// stateName -> [IStyle]
		protected var _textStateMap:Dictionary = new Dictionary();
		protected var _rectStateMap:Dictionary = new Dictionary();
		
		//protected var _inDefaultMode:Boolean;
		
		public function StylableAsset(factory:IAssetFactory=null, schema:IAssetSchema=null, textStyles:Array=null, rectangleStyles:Array=null){
			super(factory, schema);
			this.textStyles = textStyles;
			this.rectangleStyles = rectangleStyles;
			_nullStateList = [new StateDef([null],0)];
		}
		
		
		private function checkTextStyles():void{
			if(_textStyles && schema){
				_matchingTextStyles = findMatchingStyles(_textStyles);
				for each(var textStyle:ITextStyle in _matchingTextStyles){
					var styles:Array = getStyleArray(_textStateMap,textStyle.stateName);
					styles.push(textStyle);
				}
			}else{
				_matchingTextStyles = null;
			}
		}
		private function checkRectStyles():void{
			if(_rectangleStyles && schema){
				_matchingRectangleStyles = findMatchingStyles(_rectangleStyles);
				for each(var rectStyle:IRectangleStyle in _matchingRectangleStyles){
					var styles:Array = getStyleArray(_rectStateMap,rectStyle.stateName);
					styles.push(rectStyle);
				}
			}else{
				_matchingRectangleStyles = null;
			}
		}
		
		
		protected function findMatchingStyles(within:Array):*{
			var matchStyles:Array;
			for each(var testStyle:IStyle in within){
				if(testStyle.matchesSchema(schema,matchStyles)){
					if(!matchStyles)matchStyles = new Array();
					matchStyles.push(testStyle);
				}
			}
			return matchStyles;
		}
		protected function getStyleArray(within:Dictionary, stateName:String):Array{
			var array:Array = within[stateName];
			if(!array){
				array = [];
				within[stateName] = array;
			}
			return array;
		}
		override protected function sizeTextField(textField:TextField, width:Number, height:Number):void{
			super.sizeTextField(textField, width, height);
			if(_matchingTextStyles){
				applyAvailableStates();
			}
		}
		override protected function drawRect(rect:Shape, width:Number, height:Number, visible:Boolean):void{
			if(visible){
				if(!_matchingRectangleStyles){
					super.drawRect(rect, width, height, false);
				}else{
					applyAvailableStates();
				}
			}else{
				super.drawRect(rect, width, height, false);
			}
		}
		override protected function findAvailableStates():void{
			super.findAvailableStates();
		}
		override protected function applyAvailableStates():void{
			_applyingTextStyles = [];
			_applyingRectStyles = [];
			super.applyAvailableStates();
			_appliedTextStyles = _applyingTextStyles;
			_appliedRectStyles = _applyingRectStyles;
			_applyingTextStyles = null;
			_applyingRectStyles = null;
		}
		override protected function isStateNameAvailable(state:String):Boolean {
			var textStyle:Array = _textStateMap[state];
			if(_textField && textStyle && textStyle.length)return true;
			var rectStyle:Array = _rectStateMap[state];
			return (_rect && rectStyle && rectStyle.length);
		}
		override protected function unapplyState(state:IStateDef, stateName:String, nextStates:Array):Number {
			return unapplyStyles(stateName);
		}
		protected function unapplyStyles(stateName:String):Number {
			var ret:Number = 0;
			var thisRet:Number;
			var textStyles:Array = _textField?_textStateMap[stateName]:null;
			var rectStyles:Array = _rect?_rectStateMap[stateName]:null;
			
			for each(var textStyle:ITextStyle in textStyles){
				thisRet = textStyle.unstyleText(_textField);
				if(thisRet>ret)ret = thisRet;
			}
			for each(var rectStyle:IRectangleStyle in rectStyles){
				thisRet = rectStyle.unstyleRectangle(_rect);
				if(thisRet>ret)ret = thisRet;
			}
			return ret;
		}
		override protected function applyState(state:IStateDef, stateName:String, appliedStates:Array):Number {
			return applyStyles(stateName);
		}
		protected function applyStyles(stateName:String):Number {
			var ret:Number = 0;
			var thisRet:Number;
			var textStyles:Array = _textField?_textStateMap[stateName]:null;
			var rectStyles:Array = _rect?_rectStateMap[stateName]:null;
			var textStyle:ITextStyle;
			var rectStyle:IRectangleStyle;
			
			for each(textStyle in textStyles){
				if(textStyle.allowConcurrentWith(_applyingTextStyles)){
					if(_appliedTextStyles.indexOf(textStyle)==-1){
						thisRet = textStyle.styleText(_textField,_appliedTextStyles);
					}else{
						thisRet = textStyle.refreshTextStyle(_textField,_appliedTextStyles);
					}
					if(thisRet>ret)ret = thisRet;
					_applyingTextStyles.push(textStyle);
				}
			}
			for each(rectStyle in rectStyles){
				if(rectStyle.allowConcurrentWith(_applyingRectStyles)){
					if(_appliedRectStyles.indexOf(textStyle)==-1){
						thisRet = rectStyle.styleRectangle(_rect,_width,_height,_appliedRectStyles);
					}else{
						thisRet = rectStyle.refreshRectangleStyle(_rect,_width,_height,_appliedRectStyles);
					}
					if(thisRet>ret)ret = thisRet;
					_applyingRectStyles.push(rectStyle);
				}
			}
			return ret;
		}
	}
}