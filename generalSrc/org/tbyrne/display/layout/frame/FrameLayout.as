package org.tbyrne.display.layout.frame
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.tbyrne.display.core.IView;
	import org.tbyrne.display.layout.AbstractSeperateLayout;
	import org.tbyrne.display.layout.ILayoutSubject;
	import org.tbyrne.display.layout.getMarginAffectedArea;
	import org.tbyrne.display.utils.DisplayFramer;

	
	public class FrameLayout extends AbstractSeperateLayout
	{
		protected var marginAffectedPosition:Rectangle = new Rectangle();
		protected var marginRect:Rectangle = new Rectangle();
		
		public function FrameLayout(scopeView:IView=null){
			super(scopeView);
		}
		override protected function onSubjectMeasChanged(from:ILayoutSubject, oldWidth:Number, oldHeight:Number): void{
			super.onSubjectMeasChanged(from, oldWidth, oldHeight);
			subjMeasurementsChanged(from);
		}
		override protected function layoutSubject(subject:ILayoutSubject, subjMeas:Point=null):void{
			var cast:IFrameLayoutInfo = (subject.layoutInfo as IFrameLayoutInfo);
			if(cast){
				
				getMarginAffectedArea(position.x,position.y,size.x,size.y, subject.layoutInfo, marginAffectedPosition, marginRect);
				
				var subMeas:Point = subject.measurements;
				var measW:Number = isNaN(subMeas.x)?0:subMeas.x;
				var measH:Number = isNaN(subMeas.y)?0:subMeas.y;
				var framed:Rectangle = DisplayFramer.frame(measW,measH,marginAffectedPosition,cast.anchor,cast.scaleXPolicy,cast.scaleYPolicy,cast.fitPolicy);
				subject.setPosition(framed.x,framed.y);
				subject.setSize(framed.width,framed.height);
				
				if(subMeas){
					measW = measW+marginRect.x+marginRect.width;
					measH = measH+marginRect.y+marginRect.height;
					if(subjMeas.x!=measW || subjMeas.y!=measH){
						subjMeas.x = measW;
						subjMeas.y = measH;
						invalidateMeasurements();
					}
				}
			}
		}
	}
}