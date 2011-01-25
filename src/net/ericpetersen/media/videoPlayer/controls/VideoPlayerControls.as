package net.ericpetersen.media.videoPlayer.controls {
	import net.ericpetersen.media.videoPlayer.VideoConnection;

	import com.greensock.TweenMax;
	import com.greensock.easing.Sine;

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * @author ericpetersen
	 */
	public class VideoPlayerControls extends Sprite {
		/**
		* Dispatched when Pause button is clicked
		*
		* @eventType PAUSE_CLICK
		*/
		public static const PAUSE_CLICK:String = "PAUSE_CLICK";
		
		/**
		* Dispatched when Play button is clicked
		*
		* @eventType PLAY_CLICK
		*/
		public static const PLAY_CLICK:String = "PLAY_CLICK";
		
		/**
		* Dispatched when full-screen button is clicked
		*
		* @eventType FULL_SCREEN_CLICK
		*/
		public static const FULL_SCREEN_CLICK:String = "FULL_SCREEN_CLICK";
		
		/**
		* Dispatched when video time is scrubbed
		*
		* @eventType VIDEO_TIME_SCRUBBED
		*/
		public static const VIDEO_TIME_SCRUBBED:String = "VIDEO_TIME_SCRUBBED";
		
		protected var _asset:MovieClip;
		protected var _usePlayPauseToggle:Boolean;
		protected var _isScrubbing:Boolean = false;
		protected var _scrubPercent:Number = 0;
		protected var _origWidth:Number;
		
		/**
		 * Constructor
		 * @param asset The MovieClip asset from the asset swc
		 * @param origWidth The original width of the video player to size the controls. Scrubber will stretch to fit and buttons will be repositioned.
		 * @param usePlayPauseToggle Whether the play and pause should look like one toggle button or be placed next to each other.
		 */
		public function VideoPlayerControls(asset:MovieClip, origWidth:Number, usePlayPauseToggle:Boolean = true) {
			_asset = asset;
			_origWidth = origWidth;
			_usePlayPauseToggle = usePlayPauseToggle;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			addChild(_asset);
		}
		
		/**
		 * @return The percent that has been scrubbed (0 is far left, 1 is far right)
		 */
		public function getScrubPercent():Number {
			return _scrubPercent;
		}
		
		/**
		 * @return true for if the scrubber is being scrubbed by user.
		 */
		public function isScrubbing():Boolean {
			return _isScrubbing;
		}
		
		/**
		 * Update the load bar by the percent loaded.
		 * @param pctLoaded 
		 */
		public function updateVideoLoadBar(pctLoaded:Number):void {
			if (pctLoaded > 0) {
				_asset.scrubber.videoLoadBar.scaleX = pctLoaded;
			} else {
				_asset.scrubber.videoLoadBar.scaleX = 0;
			}
			if (pctLoaded > 1) {
				_asset.scrubber.videoLoadBar.scaleX = 1;
			}
		}
		
		/**
		 * Update the progress bar measuring the time of the video
		 * @param pctProgress
		 */
		public function updateVideoProgressBar(pctProgress:Number):void {
			if (pctProgress < 0) {
				_asset.scrubber.videoProgressBar.scaleX = 0;
			} else if (pctProgress > 1) {
				_asset.scrubber.videoProgressBar.scaleX = 1;
			} else {
				_asset.scrubber.videoProgressBar.scaleX = pctProgress;
			}
		}
		
		/**
		 * Update the play and pause buttons
		 * @param state
		 */
		public function updatePlayPause(state:int):void {
			if (_usePlayPauseToggle) {
				switch (state) {
					case VideoConnection.UNSTARTED :
						_asset.playPause.playBtn.visible = true;
						_asset.playPause.pauseBtn.visible = false;
						break;
					case VideoConnection.PLAYING :
						_asset.playPause.playBtn.visible = false;
						_asset.playPause.pauseBtn.visible = true;
						break;
					case VideoConnection.PAUSED :
						_asset.playPause.playBtn.visible = true;
						_asset.playPause.pauseBtn.visible = false;
						break;
					case VideoConnection.ENDED :
						_asset.playPause.playBtn.visible = true;
						_asset.playPause.pauseBtn.visible = false;
						break;
					default :
						break;
				}
			}
		}
		
		/**
		 * Resize the controls
		 * @param isFullScreen If true, it will resize for full-screen.
		 */
		public function resize(isFullScreen:Boolean = false):void {
			if (_usePlayPauseToggle) {
				_asset.playPause.playBtn.x = 0;
				_asset.playPause.pauseBtn.x = 0;
			} else {
				_asset.playPause.playBtn.x = 0;
				_asset.playPause.pauseBtn.x = _asset.playPause.playBtn.x + _asset.playPause.playBtn.width;
			}
			_asset.scrubber.x = _asset.playPause.x + _asset.playPause.width;
			if (isFullScreen) {
				_asset.scrubber.width = stage.stageWidth - _asset.playPause.width - _asset.fullScreenBtn.width;
			} else {
				_asset.scrubber.width = _origWidth - _asset.playPause.width - _asset.fullScreenBtn.width;
			}
			_asset.fullScreenBtn.x = _asset.scrubber.x + _asset.scrubber.width;
		}
		
		/**
		 * Remove listeners and clean up
		 */
		public function destroy():void {
			_asset.scrubber.videoProgressHit.removeEventListener(MouseEvent.MOUSE_DOWN, onProgressBarMouseDown);
			_asset.playPause.playBtn.removeEventListener(MouseEvent.CLICK, onPlayBtnClick);
			_asset.playPause.playBtn.removeEventListener(MouseEvent.ROLL_OVER, onPlayBtnRollOver);
			_asset.playPause.playBtn.removeEventListener(MouseEvent.ROLL_OUT, onPlayBtnRollOut);
			_asset.playPause.pauseBtn.removeEventListener(MouseEvent.CLICK, onPauseBtnClick);
			_asset.playPause.pauseBtn.removeEventListener(MouseEvent.ROLL_OVER, onPauseBtnRollOver);
			_asset.playPause.pauseBtn.removeEventListener(MouseEvent.ROLL_OUT, onPauseBtnRollOut);
			_asset.fullScreenBtn.removeEventListener(MouseEvent.CLICK, onFullScreenBtnClick);
			_asset.fullScreenBtn.removeEventListener(MouseEvent.ROLL_OVER, onFullScreenBtnRollOver);
			_asset.fullScreenBtn.removeEventListener(MouseEvent.ROLL_OUT, onFullScreenBtnRollOut);
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
		}

		protected function build():void {
			_asset.scrubber.videoLoadBar.scaleX = 0;
			_asset.scrubber.videoLoadBar.mouseEnabled = false;
			_asset.scrubber.videoProgressBar.scaleX = 0;
			_asset.scrubber.videoProgressBar.mouseEnabled = false;
			_asset.scrubber.videoProgressHit.buttonMode = true;
			_asset.scrubber.videoProgressHit.addEventListener(MouseEvent.MOUSE_DOWN, onProgressBarMouseDown, false, 0, true);
			_asset.playPause.playBtn.buttonMode = true;
			_asset.playPause.playBtn.mouseChildren = false;
			_asset.playPause.playBtn.addEventListener(MouseEvent.CLICK, onPlayBtnClick, false, 0, true);
			_asset.playPause.playBtn.addEventListener(MouseEvent.ROLL_OVER, onPlayBtnRollOver, false, 0, true);
			_asset.playPause.playBtn.addEventListener(MouseEvent.ROLL_OUT, onPlayBtnRollOut, false, 0, true);
			_asset.playPause.pauseBtn.buttonMode = true;
			_asset.playPause.pauseBtn.mouseChildren = false;
			_asset.playPause.pauseBtn.addEventListener(MouseEvent.CLICK, onPauseBtnClick, false, 0, true);
			_asset.playPause.pauseBtn.addEventListener(MouseEvent.ROLL_OVER, onPauseBtnRollOver, false, 0, true);
			_asset.playPause.pauseBtn.addEventListener(MouseEvent.ROLL_OUT, onPauseBtnRollOut, false, 0, true);
			_asset.fullScreenBtn.buttonMode = true;
			_asset.fullScreenBtn.mouseChildren = false;
			_asset.fullScreenBtn.addEventListener(MouseEvent.CLICK, onFullScreenBtnClick, false, 0, true);
			_asset.fullScreenBtn.addEventListener(MouseEvent.ROLL_OVER, onFullScreenBtnRollOver, false, 0, true);
			_asset.fullScreenBtn.addEventListener(MouseEvent.ROLL_OUT, onFullScreenBtnRollOut, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, 0, true);
			resize();
		}

		protected function onAddedToStage(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			build();
		}

		protected function enterFrameHandler(event:Event):void {
			if (_isScrubbing) {
				if (_asset.scrubber.videoProgressHit.hitTestPoint(stage.mouseX, stage.mouseY)) {
					_scrubPercent = _asset.scrubber.videoProgressHit.mouseX/_asset.scrubber.videoProgressHit.width;
					updateVideoProgressBar(_scrubPercent);
					dispatchEvent(new Event(VIDEO_TIME_SCRUBBED));
				}					
			}
		}
		
		protected function onProgressBarMouseDown(event:MouseEvent):void {
			_isScrubbing = true;
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}
		
		protected function onStageMouseUp(event:MouseEvent):void {
			if (_isScrubbing) {
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				dispatchEvent(new Event(VIDEO_TIME_SCRUBBED));
				_isScrubbing = false;
			}
		}
		
		protected function onPlayBtnRollOver(event:MouseEvent):void {
			var clip:MovieClip = MovieClip(event.currentTarget);
			TweenMax.to(clip, 0.25, {colorMatrixFilter:{amount:1, brightness:1.3}, ease:Sine.easeOut});
		}

		protected function onPlayBtnRollOut(event:MouseEvent):void {
			var clip:MovieClip = MovieClip(event.currentTarget);
			TweenMax.to(clip, 0.25, {colorMatrixFilter:{amount:1, brightness:1}, ease:Sine.easeOut});
		}
		
		protected function onPlayBtnClick(event:MouseEvent):void {
			dispatchEvent(new Event(PLAY_CLICK));
		}
		
		protected function onPauseBtnRollOver(event:MouseEvent):void {
			var clip:MovieClip = MovieClip(event.currentTarget);
			TweenMax.to(clip, 0.25, {colorMatrixFilter:{amount:1, brightness:1.3}, ease:Sine.easeOut});
		}
		
		protected function onPauseBtnRollOut(event:MouseEvent):void {
			var clip:MovieClip = MovieClip(event.currentTarget);
			TweenMax.to(clip, 0.25, {colorMatrixFilter:{amount:1, brightness:1}, ease:Sine.easeOut});
		}

		protected function onPauseBtnClick(event:MouseEvent):void {
			dispatchEvent(new Event(PAUSE_CLICK));
		}
		
		protected function onFullScreenBtnRollOver(event:MouseEvent):void {
			var clip:MovieClip = MovieClip(event.currentTarget);
			TweenMax.to(clip, 0.25, {colorMatrixFilter:{amount:1, brightness:1.3}, ease:Sine.easeOut});
		}
		
		protected function onFullScreenBtnRollOut(event:MouseEvent):void {
			var clip:MovieClip = MovieClip(event.currentTarget);
			TweenMax.to(clip, 0.25, {colorMatrixFilter:{amount:1, brightness:1}, ease:Sine.easeOut});
		}
		
		protected function onFullScreenBtnClick(event:MouseEvent):void {
			dispatchEvent(new Event(FULL_SCREEN_CLICK));
		}

	}
}
