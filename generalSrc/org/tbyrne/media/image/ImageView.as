package org.tbyrne.media.image
{
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.tbyrne.display.assets.assetTypes.IBitmapAsset;
	import org.tbyrne.display.assets.assetTypes.ILoaderAsset;
	import org.tbyrne.media.MediaView;
	
	public class ImageView extends MediaView
	{
		
		public function get smoothing():Boolean{
			return _smoothing;
		}
		public function set smoothing(value:Boolean):void{
			if(_smoothing!=value){
				_smoothing = value;
				applySmoothing();
			}
		}
		
		private var _smoothing:Boolean;
		
		public function ImageView(asset:ILoaderAsset, measurements:Point, smoothing:Boolean){
			super(asset, measurements);
			asset.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
			this.smoothing = smoothing;
		}
		protected function onLoaderComplete(e:Event):void{
			invalidateSize();
			applySmoothing();
		}
		protected function applySmoothing():void{
			var loader:ILoaderAsset = (asset as ILoaderAsset);
			var bitmap:IBitmapAsset = (loader.content as IBitmapAsset);
			if(bitmap){
				bitmap.smoothing = smoothing;
			}
		}
	}
}