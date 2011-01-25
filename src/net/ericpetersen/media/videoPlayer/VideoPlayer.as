package net.ericpetersen.media.videoPlayer {
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.media.Video;

	/**
	 * @author ericpetersen
	 */
	public class VideoPlayer extends Sprite {
		protected var _video:Video;
		protected var _connection:VideoConnection;
		protected var _autoPlay:Boolean;
		protected var _bg:Sprite;
		protected var _origWidth:Number;
		protected var _origHeight:Number;
		protected var _playerWidth:Number;
		protected var _playerHeight:Number;

		/**
		 * Constructor
		 * @param width
		 * @param height
		 */
		public function VideoPlayer(width:int = 320, height:int = 240) {
			init(width, height);
		}
		
		/**
		 * Get the video name
		 */
		public function getVideoName():String {
			return _connection.videoName;
		}

		/**
		 * @private
		 * To be compatible with YouTube Player only
		 */
		public function setPlaybackQuality(value:String):void {
			//
		}
		
		/**
		 * Get the bytes loaded of the video
		 */
		public function getVideoBytesLoaded():Number {
			return _connection.getVideoBytesLoaded();
		}
		
		/**
		 * Get the bytes total of the video
		 */
		public function getVideoBytesTotal():Number {
			return _connection.getVideoBytesTotal();
		}
		
		/**
		 * Get the current playback time of the video
		 */
		public function getCurrentTime():Number {
			return _connection.getCurrentTime();
		}
		
		/**
		 * Get the total duration time of the video
		 */
		public function getDuration():Number {
			return _connection.getDuration();
		}
		
		/**
		 * Get the state of the video player
		 * (UNSTARTED = -1, ENDED = 0, PLAYING = 1, PAUSED = 2)
		 */
		public function getPlayerState():Number {
			return _connection.getPlayerState();
		}
		
		/**
		 * <p>Load the video</p>
		 * <p>Progressive: loadVideo("video/video01.flv");</p>
		 * <p>Streaming from rtmp://appName/streamName.flv: loadVideo("streamName", "rtmp://appName"); // streamName does not include ".flv"</p>
		 */
		public function loadVideo(videoName:String, autoPlay:Boolean = true, connectURL:String = ""):void {
			trace("loadVideo, videoName = " + videoName + ", connectURL = " + connectURL);
			_video.clear();
			_autoPlay = autoPlay;
			_connection.loadVideo(videoName, connectURL);
		}
		
		/**
		 * Pause the video
		 */
		public function pauseVideo():void {
			_connection.pauseVideo();
		}
		
		/**
		 * Play the video
		 */
		public function playVideo():void {
			_connection.playVideo();
		}
		
		/**
		 * Seek to a time in the video
		 * @param seconds
		 * @param allowSeekAhead
		 */
		public function seekTo(seconds:Number, allowSeekAhead:Boolean = false):void {
			_connection.seekTo(seconds, allowSeekAhead);
		}
		
		/**
		 * Set the volume on the video
		 * @param value an integer from 0 to 100
		 */
		public function setVolume(value:int):void {
			_connection.setVolume(value);
		}
		
		/**
		 * Remove listeners and clean up
		 */
		public function destroy():void {
			_video.clear();
			_connection.removeEventListener(VideoConnection.CONNECTION_READY, onConnectionReady);
			_connection.removeEventListener(VideoConnection.METADATA_READY, onMetaDataReady);
			_connection.removeEventListener(VideoConnection.CUE_POINT, onCuePoint);
			_connection.removeEventListener(VideoConnection.PLAYER_STATE_CHANGED, onPlayerStateChange);
			_connection.destroy();
		}
		
		protected function init(width:int, height:int):void {
			_playerWidth = width;
			_playerHeight = height;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		protected function onAddedToStage(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			build();
			setSize(_playerWidth, _playerHeight);
		}
		
		protected function build():void {
			_bg = new Sprite();
			_bg.mouseEnabled = false;
			_bg.graphics.beginFill(0x000000, 1);
			_bg.graphics.drawRect(0, 0, _playerWidth, _playerHeight);
			_bg.graphics.endFill();
			addChild(_bg);
			_video = new Video(_playerWidth, _playerHeight);
			_video.smoothing = true;
			addChild(_video);
			_connection = new VideoConnection();
			_connection.addEventListener(VideoConnection.CONNECTION_READY, onConnectionReady, false, 0, true);
			_connection.addEventListener(VideoConnection.METADATA_READY, onMetaDataReady, false, 0, true);
			_connection.addEventListener(VideoConnection.CUE_POINT, onCuePoint, false, 0, true);
			_connection.addEventListener(VideoConnection.PLAYER_STATE_CHANGED, onPlayerStateChange, false, 0, true);
		}
		
		protected function setSize(width:int, height:int):void {
			trace("setSize,  width: " + width + ", height: " + height);
			_playerWidth = width;
			_playerHeight = height;
			setScale();
		}
		
		protected function setScale():void {
			_bg.width = _playerWidth;
			_bg.height = _playerHeight;
			if (!isNaN(_origWidth) && !isNaN(_origHeight)) {
				var _scaleX:Number = _playerWidth / _origWidth;
				trace("_scaleX = " + _scaleX);
				var _scaleY:Number = _playerHeight / _origHeight;
				trace("_scaleY = " + _scaleY);
	   			var scaleFactor:Number = Math.min(_scaleY, _scaleX);
	   			/*
	   			trace("scaleFactor = " + scaleFactor);
				trace("_playerWidth = " + _playerWidth);
				trace("_playerHeight = " + _playerHeight);
				trace("_origWidth = " + _origWidth);
				trace("_origHeight = " + _origHeight);
				 * 
				 */
	   			_video.width = scaleFactor * _origWidth;
	   			_video.height = scaleFactor * _origHeight;
				_video.x = Math.round((_playerWidth - _video.width)/2);
				_video.y = Math.round((_playerHeight - _video.height)/2);
			} else {
				trace("origWidth and origHeight not available")
				_video.width = _playerWidth;
				_video.height = _playerHeight;
			}
		}

		protected function onConnectionReady(event:Event):void {
			trace("onConnectionReady");
			_video.attachNetStream(_connection.ns);
		}
		
		protected function onMetaDataReady(event:Event):void {
			trace("onMetaDataReady");
			if (!_autoPlay) {
				pauseVideo();
			}
			if (_connection.metaDataInfo.width > 0) {
				_origWidth = _connection.metaDataInfo.width;
			} else {
				_origWidth = NaN;
			}
			if (_connection.metaDataInfo.height > 0) {
				_origHeight = _connection.metaDataInfo.height;
			} else {
				_origHeight = NaN;
			}
			trace("_origWidth = " + _origWidth);
			trace("_origHeight = " + _origHeight);
			setScale();
			dispatchEvent(event);
		}

		protected function onCuePoint(event:Event):void {
			trace("onCuePoint");
		}
		
		protected function onPlayerStateChange(event:Event):void {
			trace("onPlayerStateChange");
			var state:int = _connection.getPlayerState();
			switch (state) {
				case VideoConnection.UNSTARTED :
					trace("state: " + VideoConnection.UNSTARTED);
					break;
				case VideoConnection.PLAYING :
					trace("state: " + VideoConnection.PLAYING);
					break;
				case VideoConnection.PAUSED :
					trace("state: " + VideoConnection.PAUSED);
					break;
				case VideoConnection.ENDED :
					trace("state: " + VideoConnection.ENDED);
					break;
				default :
					break;
			}
		}

	}
}
