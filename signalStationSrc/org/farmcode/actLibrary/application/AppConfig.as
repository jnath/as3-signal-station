package org.farmcode.actLibrary.application
{
	import org.farmcode.display.assets.IAssetFactory;

	public class AppConfig implements IAppConfig
	{
		[Property(toString="true",clonable="true")]
		public function get initActs():Array{
			return _initActs;
		}
		public function set initActs(value:Array):void{
			_initActs = value;
		}
		
		// this is here to allow content to be added in SiteStream XML
		public function get data():Array{
			return null;
		}
		public function set data(value:Array):void{
		}
		
		public function get assetFactory():IAssetFactory{
			return _assetFactory;
		}
		public function set assetFactory(value:IAssetFactory):void{
			_assetFactory = value;
		}
		
		public function get applicationScale():Number{
			return _applicationScale;
		}
		public function set applicationScale(value:Number):void{
			_applicationScale = value;
		}
		
		private var _applicationScale:Number;
		private var _assetFactory:IAssetFactory;
		private var _initActs:Array;
	}
}