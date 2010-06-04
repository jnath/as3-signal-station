package au.com.thefarmdigital.utils
{
	import flash.display.*;
	import flash.geom.*;
	
	public class DisplayObjectSnapshot
	{
		/**
		 * Creates a Bitmap copy of the supplied DisplayObject, with coordinates that match the actual visual
		 * placement of the DisplayObject (in the coordinate space of the supplied nextParent parameter).
		 * 
		 * @param displayObject The DisplayObject to take a snapshot of.
		 * @param nextParent The DisplayObjectContainer which the x and y values should be adjusted for (to keep visual continuity), this defaults
		 * to the supplied DisplayObject's parent.
		 * @param ignoreColorTrans Set to true to avoid taking a snapshot with the DisplayObject's colorTransform applied.
		 */
		public static function snapshot(displayObject:DisplayObject, nextParent:DisplayObjectContainer=null, ignoreColorTrans:Boolean=false, cropToStage:Boolean=true):Bitmap{
			var stage:Stage = displayObject.stage;
			var stageBounds:Rectangle = displayObject.getBounds(stage);
			
			if(cropToStage){
				stageBounds = new Rectangle(0,0,stage.stageWidth,stage.stageHeight).intersection(stageBounds);
			}
			var width:Number = Math.max(Math.min(stageBounds.width,2880),1);
			var height:Number = Math.max(Math.min(stageBounds.height,2880),1);
			
			var bitmapData:BitmapData = new BitmapData(width, height,true,0);
			
			var selfTopLeft:Point = displayObject.globalToLocal(new Point(stageBounds.x,stageBounds.y));
			
			var matrix:Matrix = displayObject.transform.matrix.clone();
			matrix.tx = -selfTopLeft.x;
			matrix.ty = -selfTopLeft.y;
			bitmapData.draw(displayObject,matrix,displayObject.transform.colorTransform,displayObject.blendMode);
			
			var ret:Bitmap = new Bitmap(bitmapData);
			var point:Point = new Point(stageBounds.x,stageBounds.y);
			
			if(!nextParent)nextParent = displayObject.parent;
			if(nextParent){
				point = nextParent.globalToLocal(point);
			}
			ret.x = point.x;
			ret.y = point.y;
			
			return ret;
		}

	}
}