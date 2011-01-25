package net.ericpetersen.media.videoPlayer {
	import flash.events.MouseEvent;
	import net.ericpetersen.media.videoPlayer.controls.VideoPlayerControls;

	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.geom.Point;

	/**
	 * <p>VideoPlayerWithControls is a video player with skinnable controls.
	 * The controls are a .swc asset exported from the .fla in the lib folder to the swc folder.
	 * Controls include a play/pause button (which can be a toggle or both together),
	 * a scrubber, and a full-screen button.</p>
	 * <p>Both progressive (downloaded file such as .flv) or streaming (such as rtmp:// links)
	 * are supported.</p>
	 * 
	 * @author ericpetersen
	 */
	public class VideoPlayerWithControls extends VideoPlayer {
		/**
		* Dispatched when fullScreen changes.
		*
		* @eventType FULL_SCREEN_CHANGED
		*/
		public static const FULL_SCREEN_CHANGED:String = "FULL_SCREEN_CHANGED";
		
		protected var _controls:VideoPlayerControls;
		protected var _isFullScreen:Boolean = false;
		protected var _origVideoPt:Point;
		protected var _origControlsPt:Point;
		protected var _origPlayerWidth:Number;
		protected var _origPlayerHeight:Number;
		
		/**
		 * @return Whether or not it is full-screen
		 */
		public function get isFullScreen():Boolean {
			return _isFullScreen;
		}
		
		/**
		 * Constructor
		 * @param controls The VideoPlayerControls that uses the swc asset
		 * @param width The width of the player
		 * @param height The height of the player
		 */
		public function VideoPlayerWithControls(controls:VideoPlayerControls, width:int = 320, height:int = 240) {
			super(width, height);
			_controls = controls;
			_origPlayerWidth = width;
			_origPlayerHeight = height;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		/**
		 * Sets the player to full screen
		 * @param val true or false
		 */
		public function setFullScreen(val:Boolean):void {
			trace("setFullScreen " + val);
			_isFullScreen = val;
			if (val == true) {
				_origVideoPt.x = this.x;
				_origVideoPt.y = this.y;
				stage.displayState = StageDisplayState.FULL_SCREEN;
			} else {
				stage.displayState = StageDisplayState.NORMAL;
			}
		}

		/**
		 * Remove listeners and clean up
		 */
		override public function destroy():void {
			super.destroy();
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			_controls.destroy();
		}
		
		override protected function onAddedToStage(event:Event):void {
			super.onAddedToStage(event);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			buildControls();
		}

		protected function buildControls():void {
			_controls.y = _playerHeight;
			_origVideoPt = new Point(0, 0);
			_origControlsPt = new Point(0, _playerHeight);
			_controls.addEventListener(VideoPlayerControls.PLAY_CLICK, onPlayClick);
			_controls.addEventListener(VideoPlayerControls.PAUSE_CLICK, onPauseClick);
			_controls.addEventListener(VideoPlayerControls.FULL_SCREEN_CLICK, onFullScreenClick);
			_controls.addEventListener(VideoPlayerControls.VIDEO_TIME_SCRUBBED, onVideoTimeScrubbed);
			addChild(_controls);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}

		protected function enterFrameHandler(event:Event):void {
			var pctLoaded:Number = getVideoBytesLoaded()/getVideoBytesTotal();
			_controls.updateVideoLoadBar(pctLoaded);
			if (!_controls.isScrubbing()) {
				var pctProgress:Number = getCurrentTime()/getDuration();
				_controls.updateVideoProgressBar(pctProgress);
			}
		}

		protected function onVideoTimeScrubbed(event:Event):void {
			var secondsToSeekTo:Number = _controls.getScrubPercent() * getDuration();
			if (secondsToSeekTo > 0 && secondsToSeekTo < getDuration()) {
				seekTo(secondsToSeekTo, true);
			}
		}

		protected function onPlayClick(event:Event):void {
			playVideo();
		}
		
		protected function onPauseClick(event:Event):void {
			pauseVideo();
		}

		protected function onFullScreenClick(event:Event):void {
			setFullScreen(!_isFullScreen);
		}
		
		protected function onFullScreen(event:FullScreenEvent):void {
			trace("onFullScreen");
			if (event.fullScreen) {
				// set up fullscreen
				_isFullScreen = true;
				stage.addEventListener(Event.RESIZE, resizeFullScreenDisplay);
				resizeFullScreenDisplay();
			} else {
				// go back from fullscreen
				_isFullScreen = false;
				stage.removeEventListener(Event.RESIZE, resizeFullScreenDisplay);
				resumeFromFullScreenDisplay();
			}
			dispatchEvent(new Event(FULL_SCREEN_CHANGED));
		}
		
		protected function resizeFullScreenDisplay(event:Event = null):void {
			trace("resizeFullScreenDisplay");
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			this.x = 0;
			this.y = 0;
			setSize(stage.stageWidth, stage.stageHeight - _controls.height);
			_controls.x = 0;
			_controls.y = stage.stageHeight - _controls.height;
			_controls.resize(true);
		}
		
		protected function resumeFromFullScreenDisplay():void {
			this.x = _origVideoPt.x;
			this.y = _origVideoPt.y;
			setSize(_origPlayerWidth, _origPlayerHeight);
			_controls.x = 0;
			_controls.y = _origPlayerHeight;
			_controls.resize(false);
		}
		
		override protected function onPlayerStateChange(event:Event):void {
			trace("onPlayerStateChange");
			var state:int = getPlayerState();
			switch (state) {
				case VideoConnection.UNSTARTED :
					trace("state: " + VideoConnection.UNSTARTED);
					_controls.updatePlayPause(VideoConnection.UNSTARTED);
					break;
				case VideoConnection.PLAYING :
					trace("state: " + VideoConnection.PLAYING);
					_controls.updatePlayPause(VideoConnection.PLAYING);
					break;
				case VideoConnection.PAUSED :
					trace("state: " + VideoConnection.PAUSED);
					_controls.updatePlayPause(VideoConnection.PAUSED);
					break;
				case VideoConnection.ENDED :
					trace("state: " + VideoConnection.ENDED);
					seekTo(0);
					pauseVideo();
					break;
				default :
					break;
			}
		}

	}
}
