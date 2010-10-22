package org.tbyrne.display.progress
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import org.tbyrne.core.IApplication;
	import org.tbyrne.debug.DebugManager;
	import org.tbyrne.display.assets.nativeAssets.DisplayObjectContainerAsset;
	import org.tbyrne.display.assets.nativeAssets.NativeAssetFactory;
	import org.tbyrne.display.core.IOutroView;
	
	public class SWFPreloaderFrame extends Sprite
	{
		private static const CLASS_FILENAME_PATTERN:RegExp = /^.*\/(.*)\..*$/;
		private static const TEST_TIME:Number = 5;
		
		public function get progressDisplay():IProgressDisplay{
			return _progressDisplay;
		}
		public function set progressDisplay(value:IProgressDisplay):void{
			if(_progressDisplay!=value){
				if(_progressDisplay){
					_nativeAsset.removeAsset(_progressDisplay.display);
				}
				_progressDisplay = value;
				if(_progressDisplay){
					if(_progressDisplay.layoutView){
						_nativeAsset.addAsset(_progressDisplay.display);
						applySizeToProgressDisplay();
					}
					_progressDisplayAnim = (_progressDisplay.layoutView as IOutroView);
				}
			}
		}
		protected function get nativeFactory():NativeAssetFactory{
			if(!_nativeFactory)_nativeFactory = new NativeAssetFactory();
			return _nativeFactory;
		}
		public var mainClasspath:String;
		
		private var _progressDisplay:IProgressDisplay;
		private var _progressDisplayAnim:IOutroView;
		private var _totalFound:Boolean = false;
		private var _measureFactor:Number;
		private var _application:IApplication;
		private var _total:Number;
		private var _nativeFactory:NativeAssetFactory;
		private var _nativeAsset:DisplayObjectContainerAsset;
		
		public function SWFPreloaderFrame(mainClasspath: String=null, progressDisplay:IProgressDisplay=null, runTest:Boolean=false){
			super();
			_nativeAsset = nativeFactory.getNew(this);
			
			this.mainClasspath = mainClasspath;
			this.progressDisplay = progressDisplay;
			init(runTest);
		}
		protected function init(runTest:Boolean): void{
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, onStageResize);
			
			if(runTest){
				_progressDisplay.message = "Testing";
				_progressDisplay.units = "s";
				_progressDisplay.measurable = true;
				_total = TEST_TIME;
				_progressDisplay.total = _total;
				addEventListener(Event.ENTER_FRAME, doTest);
			}else if(root.loaderInfo.bytesTotal > 0 && root.loaderInfo.bytesLoaded >= root.loaderInfo.bytesTotal){
				_total = root.loaderInfo.bytesTotal;
				loadCompleted();
			}else{
				_progressDisplay.message = "Loading";
				_progressDisplay.measurable = false;
				root.loaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
				root.loaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				root.loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
				onLoadProgress();
			}
		}
		private function doTest(event: Event): void{
			var progress:Number = getTimer()/1000;
			if(progress<TEST_TIME){
				_progressDisplay.progress = progress;
			}else{
				removeEventListener(Event.ENTER_FRAME, doTest);
				loadCompleted();
			}
		}
		private function onLoadProgress(event: Event=null): void{
			if(!_totalFound && root.loaderInfo.bytesTotal>0){
				_progressDisplay.measurable = true;
				_total = root.loaderInfo.bytesTotal;
				if(_total<1024){
					_progressDisplay.units = "b";
					_measureFactor = 1;
				}else{
					_total /= 1024;
					if(_total<1024){
						_progressDisplay.units = "kb";
						_measureFactor = 1024;
					}else{
						_total /= 1024;
						_progressDisplay.units = "mb";
						_measureFactor = 1024*1024;
					}
				}
				_progressDisplay.total = _total;
				_totalFound = true;
			}
			if(_totalFound){
				_progressDisplay.progress = root.loaderInfo.bytesLoaded/_measureFactor;
			}
		}
		private function onLoadComplete(event: Event): void{
			root.loaderInfo.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			root.loaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
			root.loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loadCompleted();
		}
		private function onLoadError(event: Event): void{
			_progressDisplay.message = "Error";
			_progressDisplay.measurable = false;
		}
		private function onStageResize(event: Event): void{
			if(_progressDisplay.layoutView)applySizeToProgressDisplay();
			if(_application)applySizeToApplication();
		}
		private function applySizeToProgressDisplay(): void{
			_progressDisplay.layoutView.setSize(stage.stageWidth,stage.stageHeight);
		}
		private function applySizeToApplication(): void{
			_application.setSize(stage.stageWidth,stage.stageHeight);
		}
		protected function loadCompleted():void{
			_progressDisplay.progress = _total;
			addEventListener(Event.ENTER_FRAME, instantiateApp);
		}
		protected function instantiateApp(e:Event):void{
			removeEventListener(Event.ENTER_FRAME, instantiateApp);
			
			var className:String = (mainClasspath?mainClasspath:guessClassName());
			var mainClass:Class = getDefinitionByName(className) as Class;
			_application = new mainClass();
			
			CONFIG::debug{
				_application = DebugManager.addApplication(_application);
			}
			applySizeToApplication();
			
			if(_progressDisplayAnim){
				var timer:Timer = new Timer(_progressDisplayAnim.showOutro()*1000,1);
				timer.addEventListener(TimerEvent.TIMER, onOutroFinished);
				timer.start();
			}else{
				addAppToStage();
			}
		}
		protected function onOutroFinished(e:Event):void{
			var timer:Timer = (e.target as Timer);
			timer.removeEventListener(TimerEvent.TIMER, onOutroFinished);
			addAppToStage();
		}
		protected function addAppToStage():void{
			_nativeAsset.removeAsset(_progressDisplay.display);
			_application.container = _nativeAsset;
		}
		private function guessClassName():String{
			var results:Object = CLASS_FILENAME_PATTERN.exec(unescape(stage.loaderInfo.url));
			return results[1];
		}
	}
}