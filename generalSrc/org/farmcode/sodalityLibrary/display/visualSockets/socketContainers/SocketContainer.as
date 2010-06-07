package org.farmcode.sodalityLibrary.display.visualSockets.socketContainers
{
	import au.com.thefarmdigital.delayedDraw.IDrawable;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import org.farmcode.display.assets.IContainerAsset;
	import org.farmcode.display.assets.IDisplayAsset;
	import org.farmcode.display.core.IOutroView;
	import org.farmcode.display.layout.ILayout;
	import org.farmcode.display.layout.ILayoutSubject;
	import org.farmcode.sodality.advice.IAdvice;
	import org.farmcode.sodality.advisors.DynamicAdvisor;
	import org.farmcode.sodalityLibrary.display.visualSockets.plugs.PlugDisplay;
	import org.farmcode.sodalityLibrary.display.visualSockets.sockets.IDisplaySocket;
	
	public class SocketContainer extends PlugDisplay implements ISocketContainer
	{
		override public function set displaySocket(value:IDisplaySocket):void{
			super.displaySocket = value;
			checkHelper();
		}
		override public function set asset(value:IDisplayAsset):void{
			super.asset = value;
			_advisor.advisorDisplay = value.drawDisplay;
			checkHelper();
		}
		
		public function get layout():ILayout{
			return _layout;
		}
		public function set layout(value:ILayout):void{
			if(_layout!=value){
				var socket:IDisplaySocket;
				var layoutSocket:ILayoutSubject;
				if(_layout){
					for each(socket in socketContHelper.childSockets){
						layoutSocket = (socket as ILayoutSubject);
						if(layoutSocket)_layout.removeSubject(layoutSocket);
					}
				}
				_layout = value;
				_layoutView = (_layout as IDrawable);
				if(_layout){
					for each(socket in socketContHelper.childSockets){
						layoutSocket = (socket as ILayoutSubject);
						if(layoutSocket)_layout.addSubject(layoutSocket);
					}
					invalidate();
				}
			}
		}
		override public function get display():IDisplayAsset{
			var ret:IDisplayAsset = super.display;
			if(!ret){
				// TODO: fix this
				//ret = asset = new Sprite();
				throw new Error();
			}
			return ret;
		}
		
		private var _layout:ILayout;
		private var _layoutView:IDrawable;
		protected var _socketContHelper:SocketContainerHelper;
		protected var _advisor:DynamicAdvisor = new DynamicAdvisor();
		protected var _childContainer:IContainerAsset;
		
		public function SocketContainer(asset:IDisplayAsset=null){
			super(asset);
		}
		override protected function bindToAsset() : void{
			super.bindToAsset();
			_childContainer = _asset.createAsset("childContainer",IContainerAsset);
			_containerAsset.addAsset(_childContainer);
		}
		override protected function unbindFromAsset() : void{
			_containerAsset.removeAsset(_childContainer);
			_asset.destroyAsset(_childContainer);
			super.unbindFromAsset();
		}
		override public function setDataProvider(value:*, cause:IAdvice=null):void{
			super.setDataProvider(value,cause);
			socketContHelper.setDataProvider(value,cause);
		}
		public function get childSockets(): Array{
			return socketContHelper.childSockets;
		}
		public function set childSockets(value: Array):void{
			if(_layout){
				var old:Array = socketContHelper.childSockets;
				var socket:IDisplaySocket;
				var layoutSocket:ILayoutSubject;
				for (var i:int=0; i<old.length; i++){
					socket = old[i];
					if(!value || value.indexOf(socket)==-1){
						layoutSocket = (socket as ILayoutSubject);
						if(layoutSocket)_layout.removeSubject(layoutSocket);
						else i++;
					}else{
						i++;
					}
				}
				if(value){
					for each(socket in value){
						if(old.indexOf(socket)==-1){
							layoutSocket = (socket as ILayoutSubject);
							if(layoutSocket)_layout.addSubject(layoutSocket);
						}
					}
				}
			}
			socketContHelper.childSockets = value;
		}
		public function get dataPropertyBindings(): Dictionary{
			return socketContHelper.dataPropertyBindings;
		}
		public function set dataPropertyBindings(value: Dictionary):void{
			socketContHelper.dataPropertyBindings = value;
		}
		protected function get socketContHelper(): SocketContainerHelper{
			if(!_socketContHelper){
				_socketContHelper = new SocketContainerHelper(this,_advisor);
				_socketContHelper.defaultContainer = _childContainer;
				_socketContHelper.childDataAssessed.addHandler(onChildDataAssessed);
			}
			return _socketContHelper;
		}
		protected function onChildDataAssessed(from:SocketContainerHelper):void{
			// this is so that when child sockets are filled they have the correct position.
			if(_layoutView){
				_layoutView.validate();
			}
		}
		override protected function doShowIntro():void{
			checkHelper();
			super.doShowIntro();
		}
		override protected function doShowOutro():Number{
			checkHelper();
			var ret:Number = super.doShowOutro();
			for each(var socket:IDisplaySocket in childSockets){
				if(socket.plugDisplay){
					var cast:IOutroView = (socket.plugDisplay as IOutroView);
					ret = Math.max(ret,cast.showOutro());
				}
			}
			return ret;
		}
		protected function checkHelper():void{
			if(!_outroShown && displaySocket){
				socketContHelper.display = asset;
			}else{
				socketContHelper.display = null;
			}
		}
		override protected function draw():void{
			super.draw();
			drawLayout();
			if(_containerAsset){
				if(_containerAsset.scaleX!=0 && _containerAsset.scaleX!=Infinity){
					_containerAsset.scaleX = 1/_containerAsset.scaleX;
				}
				if(_containerAsset.scaleY!=0 && _containerAsset.scaleY!=Infinity){
					_containerAsset.scaleY = 1/_containerAsset.scaleY;
				}
			}
		}
		protected function drawLayout():void{
			if(_layout){
				_layout.setLayoutSize(displayPosition.x-_containerAsset.x,displayPosition.y-_containerAsset.y,displayPosition.width,displayPosition.height);
			}
		}
	}
}