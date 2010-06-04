package au.com.thefarmdigital.sound
{
	import au.com.thefarmdigital.sound.soundControls.IQueueableSoundControl;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import org.farmcode.hoborg.IPoolable;
	
	[Event(name="playbackFinished",type="au.com.thefarmdigital.sound.SoundEvent")]
	[Event(name="soundRemoved",type="au.com.thefarmdigital.sound.SoundEvent")]
	public class SoundQueue extends EventDispatcher implements IPoolable
	{
		public function get leader():IQueueableSoundControl{
			return sounds[0];
		}
		public function get soundCount():int{
			return sounds.length;
		}
		
		
		public function get playingSound():IQueueableSoundControl{
			return _playingSound;
		}
		public function set playingSound(value:IQueueableSoundControl):void{
			if(_playingSound != value){
				if(_playingSound){
					_playingSound.removeEventListener(SoundEvent.PLAYBACK_FINISHED, onPlayingFinished);
				}
				_playingSound = value;
				if(_playingSound){
					_playingSound.addEventListener(SoundEvent.PLAYBACK_FINISHED, onPlayingFinished);
				}
				
			}
		}
		
		public var queueName:String;
		
		private var _playingSound:IQueueableSoundControl;
		private var sounds:Array;
		
		public function SoundQueue(){
			reset();
		}
		/**
		 * @return Boolean returns false if the sound wasn't added to the queue.
		 */
		public function addSound(sound:IQueueableSoundControl, doingPostpone:Boolean):Boolean{
			if(playingSound && !playingSound.allowQueueInterrupt && !sound.allowQueuePostpone){
				return false;
			}
			
			var i:int=(doingPostpone?1:0);
			while(i<sounds.length){
				var compare:IQueueableSoundControl = (sounds[i] as IQueueableSoundControl);
				if(compare==sound){
					return false;
				}else if(compare.queuePriority<sound.queuePriority && (i!=0 || compare.allowQueueInterrupt) || 
					(compare.queuePriority==sound.queuePriority && compare.allowQueueInterrupt)){
					break;
				}
				i++;
			}
			var added: Boolean = false;
			var first:Boolean = (i==0);
			
			// Resolve conflict of wanting to be head sound while there already is one
			if (first && leader && !leader.allowQueuePostpone){
				var oldLeader:IQueueableSoundControl = leader;
				sounds.splice(0, 1)
				dispatchEvent(new SoundEvent(oldLeader,SoundEvent.SOUND_REMOVED));
			}
			if(first || sound.allowQueuePostpone){
				sounds.splice(i,0,sound);
				return true;
			}
			return false;
		}
		public function removeSound(sound:IQueueableSoundControl):void{
			var index:int = sounds.indexOf(sound);
			if(index!=-1){
				sounds.splice(index,1);
			}
		}
		public function removeLeader():void{
			sounds.splice(0,1);
		}
		public function hasSound(sound: IQueueableSoundControl): Boolean
		{
			return this.sounds.indexOf(sound) >= 0;
		}
		
		protected function onPlayingFinished(e:Event):void{
			this.notifySoundFinished(playingSound);
		}
		
		protected function notifySoundFinished(sound: IQueueableSoundControl): void
		{
			this.dispatchEvent(new SoundEvent(sound, SoundEvent.PLAYBACK_FINISHED));
		}
		
		protected function notifySoundRemoved(sound: IQueueableSoundControl): void
		{
			this.dispatchEvent(new SoundEvent(sound, SoundEvent.SOUND_REMOVED));
		}
		
		public function reset():void{
			queueName = null;
			sounds = [];
			_playingSound = null;
		}
	}
}