package org.tbyrne.display.layout.relative
{
	import org.tbyrne.display.assets.assetTypes.IAsset;
	import org.tbyrne.display.assets.nativeTypes.IDisplayObject;
	import org.tbyrne.display.layout.core.ConstrainedLayoutInfo;
	
	public class RelativeLayoutInfo extends ConstrainedLayoutInfo implements IRelativeLayoutInfo
	{
		
		public function get relativeTo():IDisplayObject{
			return _relativeTo;
		}
		public function set relativeTo(value:IDisplayObject):void{
			_relativeTo = value;
		}
		
		public function get relativeOffsetX():Number{
			return _relativeOffsetX;
		}
		public function set relativeOffsetX(value:Number):void{
			_relativeOffsetX = value;
		}
		
		public function get relativeOffsetY():Number{
			return _relativeOffsetY;
		}
		public function set relativeOffsetY(value:Number):void{
			_relativeOffsetY = value;
		}
		
		public function get keepWithinStageBounds():Boolean{
			return _keepWithinStageBounds;
		}
		public function set keepWithinStageBounds(value:Boolean):void{
			_keepWithinStageBounds = value;
		}
		
		private var _keepWithinStageBounds:Boolean;
		private var _relativeOffsetY:Number;
		private var _relativeOffsetX:Number;
		private var _relativeTo:IDisplayObject;
		
		public function RelativeLayoutInfo(relativeTo:IDisplayObject=null, keepWithinStageBounds:Boolean=true, relativeOffsetX:Number=NaN, relativeOffsetY:Number=NaN){
			this.relativeTo = relativeTo;
			this.relativeOffsetX = relativeOffsetX;
			this.relativeOffsetY = relativeOffsetY;
		}
	}
}