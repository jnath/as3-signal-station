package org.tbyrne.display.core
{
	import flash.utils.Dictionary;
	
	import org.tbyrne.display.DisplayNamespace;
	import org.tbyrne.display.assets.assetTypes.IDisplayAsset;
	
	use namespace DisplayNamespace;

	/**
	 * ScopedObjectAssigner assigns IScopedObjects to IScopedObjectRoot
	 * objects based on which IScopedObjectRoot is the closest ascendant of each
	 * IScopedObject, this is used for many situations where application scope
	 * should be automatically determined to provide Singleton-like behaviour
	 * (without resorting to strict static members, which can result in
	 * application clashes).
	 */
	// TODO: make this respond to addedToStage and removedFromStage
	public class ScopedObjectAssigner
	{
		// IScopedObjectRoot -> true
		private static var managers:Dictionary = new Dictionary();
		// IScopedObject -> ScopedObjectBundle
		private static var scopedObjects:Dictionary = new Dictionary();
		// IDisplayAsset -> IScopedObjectRoot
		private static var managerScopeMap:Dictionary = new Dictionary();
		// IScopedObject -> IScopedObjectRoot
		private static var scopedObjectMap:Dictionary = new Dictionary();
		// IScopedObjectRoot -> [IScopedObject]
		private static var managerLists:Dictionary = new Dictionary();
		
		public function addManager(manager:IScopedObjectRoot):void{
			CONFIG::debug{
				if(managers[manager]){
					throw new Error("Manager already added");
				}
			}
			
			managers[manager] = true;
			manager.scopeChanged.addHandler(onManagerScopeChanged);
			if(manager.scope){
				addManagerScope(manager);
			}
		}
		public function removeManager(manager:IScopedObjectRoot):void{
			CONFIG::debug{
				if(!managers[manager]){
					throw new Error("Manager hasn't been added");
				}
			}
			
			delete managers[manager];
			manager.scopeChanged.addHandler(onManagerScopeChanged);
			if(manager.scope){
				removeManagerScope(manager);
			}
		}
		public function addScopedObject(scopedObject:IScopedObject):void{
			CONFIG::debug{
				if(scopedObjectMap[scopedObject]){
					throw new Error("scopedObject already added");
				}
			}
			
			scopedObjects[scopedObject] = new ScopedObjectBundle(scopedObject, this);
			scopedObject.scopeChanged.addHandler(onScopeDisplayChange);
			if(scopedObject.scope){
				addObjectScope(scopedObject);
			}
		}
		public function removeScopedObject(scopedObject:IScopedObject):void{
			var bundle:ScopedObjectBundle = scopedObjects[scopedObject];
			CONFIG::debug{
				if(!bundle){
					throw new Error("scopedObject has not been added");
				}
			}
			bundle.release();
			delete scopedObjects[scopedObject];
			scopedObject.scopeChanged.removeHandler(onScopeDisplayChange);
			if(scopedObject.scope){
				removeObjectScope(scopedObject);
			}
		}
		
		
		
		
		private function findManagerFor(asset:IDisplayAsset):IScopedObjectRoot{
			var subject:IDisplayAsset = asset;
			while(subject){
				var manager:IScopedObjectRoot = managerScopeMap[subject];
				if(manager)return manager;
				subject = subject.parent;
			}
			return null;
		}
		private function onManagerScopeChanged(manager:IScopedObjectRoot, oldScope:IDisplayAsset):void{
			if(oldScope)removeManagerScope(manager,oldScope);
			if(manager.scope)addManager(manager);
		}
		protected function addManagerScope(manager:IScopedObjectRoot):void{
			var parent:IScopedObjectRoot = findManagerFor(manager.scope);
			managerScopeMap[manager.scope] = manager;
			var list:Array = [];
			managerLists[manager] = list;
			
			var scopedDisplay:IScopedObject;
			
			if(parent){
				var parentList:Array = managerLists[parent];
				for(var i:int=parentList.length-1; i>=0; --i){
					scopedDisplay = parentList[i];
					if(findManagerFor(scopedDisplay.scope)==manager){
						parent.removeDescendant(scopedDisplay);
						parentList.splice(i,1);
						
						addToManager(scopedDisplay, manager, list);
					}
				}
			}else{
				for(var j:* in scopedObjects){
					scopedDisplay = (j as IScopedObject);
					if(scopedDisplay.scope && !scopedObjectMap[scopedDisplay] &&
							findManagerFor(scopedDisplay.scope)==manager){
						
						addToManager(scopedDisplay, manager, list);
					}
				}
			}
		}
		protected function removeManagerScope(manager:IScopedObjectRoot, fromScope:IDisplayAsset=null):void{
			if(!fromScope)fromScope = manager.scope;
			delete managerScopeMap[manager.scope];
			
			var list:Array = managerLists[manager];
			delete managerLists[manager];
			
			var parent:IScopedObjectRoot = findManagerFor(fromScope);
			var scopedDisplay:IScopedObject;
			if(parent){
				var parentList:Array = managerLists[parent];
				for each(scopedDisplay in list){
					manager.removeDescendant(scopedDisplay);
					addToManager(scopedDisplay, parent, parentList);
				}
			}else{
				for each(scopedDisplay in list){
					manager.removeDescendant(scopedDisplay);
					delete scopedObjectMap[scopedDisplay];
				}
			}
		}
		private function addToManager(scopedDisplay:IScopedObject, manager:IScopedObjectRoot, managerList:Array):void{
			manager.addDescendant(scopedDisplay);
			scopedObjectMap[scopedDisplay] = manager;
			managerList.push(scopedDisplay);
		}
		private function onScopeDisplayChange(scopedDisplay:IScopedObject, oldScope:IDisplayAsset):void{
			if(oldScope){
				removeObjectScope(scopedDisplay,oldScope);
			}
			if(scopedDisplay.scope){
				addObjectScope(scopedDisplay);
			}
		}
		protected function addObjectScope(scopedObject:IScopedObject):void{
			var newScope:IDisplayAsset = scopedObject.scope;
			
			var bundle:ScopedObjectBundle = scopedObjects[scopedObject];
			newScope.addedToStage.addHandler(bundle.onScopeAdded);
			newScope.addedToStage.addHandler(bundle.onScopeRemoved);
			
			var manager:IScopedObjectRoot = findManagerFor(newScope);
			if(manager){
				var list:Array = managerLists[manager];
				addToManager(scopedObject,manager,list);
			}
		}
		protected function removeObjectScope(scopedObject:IScopedObject, fromScope:IDisplayAsset=null):void{
			if(!fromScope)fromScope = scopedObject.scope;
			
			var bundle:ScopedObjectBundle = scopedObjects[scopedObject];
			fromScope.addedToStage.removeHandler(bundle.onScopeAdded);
			fromScope.addedToStage.removeHandler(bundle.onScopeRemoved);
			
			var manager:IScopedObjectRoot = scopedObjectMap[scopedObject];
			if(manager){
				removeFromManager(scopedObject,manager);
			}
		}
		DisplayNamespace function onScopeAdded(scope:IDisplayAsset, scopedObject:IScopedObject):void{
			if(!scopedObjectMap[scopedObject]){
				var manager:IScopedObjectRoot = findManagerFor(scope);
				if(manager){
					var list:Array = managerLists[manager];
					addToManager(scopedObject,manager,list);
				}
			}
		}
		DisplayNamespace function onScopeRemoved(scope:IDisplayAsset, scopedObject:IScopedObject):void{
			var manager:IScopedObjectRoot = scopedObjectMap[scopedObject];
			if(manager && manager!=findManagerFor(scope)){
				removeFromManager(scopedObject, manager);
			}
		}
		protected function removeFromManager(scopedObject:IScopedObject, manager:IScopedObjectRoot):void{
			manager.removeDescendant(scopedObject);
			var list:Array = managerLists[manager];
			delete scopedObjectMap[scopedObject];
			var index:int = list.indexOf(scopedObject);
			list.splice(index,1);
		}
	}
}
import org.tbyrne.display.DisplayNamespace;
import org.tbyrne.display.assets.assetTypes.IDisplayAsset;
import org.tbyrne.display.core.IScopedObject;
import org.tbyrne.display.core.ScopedObjectAssigner;

use namespace DisplayNamespace;

class ScopedObjectBundle{
	private var scopedObject:IScopedObject;
	private var assigner:ScopedObjectAssigner;
	
	public function ScopedObjectBundle(scopedObject:IScopedObject, assigner:ScopedObjectAssigner){
		this.scopedObject = scopedObject;
		this.assigner = assigner;
	}
	public function onScopeAdded(scope:IDisplayAsset):void{
		assigner.onScopeAdded(scope, scopedObject);
	}
	public function onScopeRemoved(scope:IDisplayAsset):void{
		assigner.onScopeRemoved(scope, scopedObject);
	}
	public function release():void{
		scopedObject = null;
		assigner = null;
	}
}