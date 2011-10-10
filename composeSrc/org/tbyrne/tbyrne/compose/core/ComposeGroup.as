package org.tbyrne.tbyrne.compose.core
{
	import org.tbyrne.tbyrne.compose.ComposeNamespace;
	import org.tbyrne.tbyrne.compose.traits.ITrait;
	import org.tbyrne.tbyrne.compose.concerns.ITraitConcern;
	import org.tbyrne.collections.IndexedList;
	import org.tbyrne.tbyrne.compose.traits.TraitCollection;
	
	use namespace ComposeNamespace;
	
	public class ComposeGroup extends ComposeItem
	{
		
		private var _descendantTraits:TraitCollection = new TraitCollection();
		private var _children:IndexedList = new IndexedList();
		private var _descConcerns:IndexedList = new IndexedList();
		private var _parentDescConcerns:IndexedList = new IndexedList();
		
		public function ComposeGroup(initTraits:Array=null){
			super(initTraits);
		}
		override ComposeNamespace function setRoot(game:ComposeRoot):void{
			super.setRoot(game);
			for each(var child:ComposeItem in _children.list){
				child.setRoot(game);
			}
		}
		public function addItem(item:ComposeItem):void{
			CONFIG::debug{
				if(!item)Log.error("ComposeGroup.addItem must have child ComposeItem supplied");
				if(_children.containsItem(item))Log.error("ComposeGroup.addItem already contains child item.");
			}
			
			_children.push(item);
			item.parentItem = this;
			
			var traitConcern:ITraitConcern;
			for each(traitConcern in _descConcerns.list){
				item.addParentConcern(traitConcern);
			}
			for each(traitConcern in _parentDescConcerns.list){
				item.addParentConcern(traitConcern);
			}
			
			item.setRoot(_root);
		}
		public function removeItem(item:ComposeItem):void{
			CONFIG::debug{
				if(!item)Log.error("ComposeGroup.removeItem must have child ComposeItem supplied");
				if(!_children.containsItem(item))Log.error("ComposeGroup.removeItem doesn't contain child item.");
			}
			
			_children.remove(item);
			item.parentItem = null;
			
			var traitConcern:ITraitConcern;
			for each(traitConcern in _descConcerns.list){
				item.removeParentConcern(traitConcern);
			}
			for each(traitConcern in _parentDescConcerns.list){
				item.removeParentConcern(traitConcern);
			}
			
			item.setRoot(null);
		}
		ComposeNamespace function addChildTrait(trait:ITrait):void{
			_descendantTraits.addTrait(trait);
			if(_parentItem)_parentItem.addChildTrait(trait);
		}
		ComposeNamespace function removeChildTrait(trait:ITrait):void{
			_descendantTraits.removeTrait(trait);
			if(_parentItem)_parentItem.removeChildTrait(trait);
		}
		override protected function addTraitConcern(concern:ITraitConcern):void{
			super.addTraitConcern(concern);
			if(concern.descendants){
				_descConcerns.push(concern);
				for each(var child:ComposeItem in _children.list){
					child.addParentConcern(concern);
				}
			}
		}
		override protected function removeTraitConcern(concern:ITraitConcern):void{
			super.removeTraitConcern(concern);
			if(_descConcerns.containsItem(concern)){
				_descConcerns.remove(concern);
				for each(var child:ComposeItem in _children.list){
					child.removeParentConcern(concern);
				}
			}
		}
		public function getDescTrait(matchType:Class):*{
			return _descendantTraits.getTrait(matchType);
		}
		public function getDescTraits(ifMatches:Class=null):Array{
			return _descendantTraits.getTraits(ifMatches);
		}
		public function callForDescTraits(func:Function, ifMatches:Class=null, params:Array=null):void{
			_descendantTraits.callForTraits(func, ifMatches, this, params);
		}
		override protected function onParentAdd():void{
			super.onParentAdd();
			for each(var trait:ITrait in _descendantTraits.traits){
				_parentItem.addChildTrait(trait);
			}
		}
		override protected function onParentRemove():void{
			super.onParentRemove();
			for each(var trait:ITrait in _descendantTraits.traits){
				_parentItem.removeChildTrait(trait);
			}
		}
		
		
		override ComposeNamespace function addParentConcern(concern:ITraitConcern):void{
			super.addParentConcern(concern);
			if(concern.shouldDescend(this)){
				_parentDescConcerns.push(concern);
				for each(var child:ComposeItem in _children.list){
					child.addParentConcern(concern);
				}
			}
		}
		override ComposeNamespace function removeParentConcern(concern:ITraitConcern):void{
			super.removeParentConcern(concern);
			if(_parentDescConcerns.containsItem(concern)){
				_parentDescConcerns.remove(concern);
				for each(var child:ComposeItem in _children.list){
					child.removeParentConcern(concern);
				}
			}
		}
	}
}