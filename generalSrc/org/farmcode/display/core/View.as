package org.farmcode.display.core
{
	import org.farmcode.acting.actTypes.IAct;
	import org.farmcode.acting.acts.Act;
	import org.farmcode.display.assets.assetTypes.IDisplayAsset;
	
	public class View implements IView
	{
		/**
		 * @inheritDoc
		 */
		public function get assetChanged():IAct{
			if(!_assetChanged)_assetChanged = new Act();
			return _assetChanged;
		}
		public function get asset():IDisplayAsset{
			return _asset;
		}
		public function set asset(value:IDisplayAsset):void{
			if(_asset!=value){
				var oldAsset:IDisplayAsset = _asset;
				_asset = value;
				if(_assetChanged)_assetChanged.perform(this,oldAsset);
			}
		}
		
		protected var _asset:IDisplayAsset;
		protected var _assetChanged:Act;
		
		public function View(asset:IDisplayAsset=null){
			this.asset = asset;
		}
	}
}