package org.tbyrne.tbyrne.compose.traits
{
	import org.tbyrne.tbyrne.compose.concerns.ITraitConcern;
	import org.tbyrne.tbyrne.compose.core.ComposeGroup;
	import org.tbyrne.tbyrne.compose.core.ComposeItem;
	
	public class AbstractTrait implements ITrait
	{
		public function get item():ComposeItem{
			return _item;
		}
		public function set item(value:ComposeItem):void{
			if(_item!=value){
				if(_item)onItemRemove();
				_item = value;
				_group = (value as ComposeGroup);
				if(_item){
					if((!_groupOnly) || _group)onItemAdd();
					else{
						CONFIG::debug{
							Log.error("Group only Trait added to non-group");
						}
					}
				}
			}
		}
		
		public function get concerns():Vector.<ITraitConcern>{
			return _concerns;
		}
		
		
		protected var _item:ComposeItem;
		protected var _group:ComposeGroup;
		protected var _concerns:Vector.<ITraitConcern>;
		
		/**
		 * Set to true to force Trait to only be added for groups.
		 */
		protected var _groupOnly:Boolean = false;
		
		public function AbstractTrait(){
			_concerns = new Vector.<ITraitConcern>();
		}
		protected function onItemRemove():void{
			// override me
		}
		protected function onItemAdd():void{
			// override me
		}
		
		protected function addConcern(concern:ITraitConcern):void{
			CONFIG::debug{
				if(_concerns.indexOf(concern)!=-1){
					Log.error("Attempting to add concern twice");
				}
			}
			_concerns.push(concern);
			concern.traitAdded.addHandler(onConcernedTraitAdded);
			concern.traitRemoved.addHandler(onConcernedTraitRemoved);
		}
		protected function removeConcern(concern:ITraitConcern):void{
			var index:int = _concerns.indexOf(concern);
			CONFIG::debug{
				if(index==-1){
					Log.error("Attempting to remove non-added concern");
				}
			}
			_concerns.splice(index,1);
			concern.traitAdded.removeHandler(onConcernedTraitAdded);
			concern.traitRemoved.removeHandler(onConcernedTraitRemoved);
			
		}
		
		
		protected function onConcernedTraitAdded(from:ITraitConcern, trait:ITrait):void{
			// override
		}
		protected function onConcernedTraitRemoved(from:ITraitConcern, trait:ITrait):void{
			// override
		}
		
	}
}