package org.tbyrne.display.assets.schema
{
	import org.tbyrne.display.assets.AbstractAsset;
	import org.tbyrne.display.assets.IAssetFactory;
	import org.tbyrne.display.assets.schemaTypes.IAssetSchema;
	import org.tbyrne.factories.IInstanceFactory;

	/**
	 * This serves as a super-class for all schema-based assets.
	 * If you're asset uses the native display heirarchy to draw
	 * itself you should instead use the AbstractDynamicAsset class.
	 */
	public class AbstractSchemaBasedAsset extends AbstractAsset
	{
		public function get schema():IAssetSchema{
			return _schema;
		}
		public function set schema(value:IAssetSchema):void{
			if(_schema!=value){
				if(_schema)removeSchema();
				_schema = value;
				if(_schema)addSchema();
			}
		}
		
		override public function set factory(value:IAssetFactory):void{
			_factory = value;
			var cast:AbstractSchemaAssetFactory = (value as AbstractSchemaAssetFactory);
			if(cast)_schemaFactory = cast;
		}
		
		protected var _schema:IAssetSchema;
		protected var _schemaFactory:AbstractSchemaAssetFactory;
		
		public function AbstractSchemaBasedAsset(factory:IAssetFactory=null, schema:IAssetSchema=null){
			super(factory);
			this.schema = schema;
		}
		override public function reset():void{
			schema = null;
			super.reset();
		}
		public function getCloneFactory():IInstanceFactory{
			return _schemaFactory.getCloneFactory(this);
		}
		
		
		protected function addSchema():void{
			Log.log(Log.SUSPICIOUS_IMPLEMENTATION, "AbstractSchemaBasedAsset.addSchema: Should be overriden");
		}
		protected function removeSchema():void{
			Log.log(Log.SUSPICIOUS_IMPLEMENTATION, "AbstractSchemaBasedAsset.removeSchema: Should be overriden");
		}
	}
}