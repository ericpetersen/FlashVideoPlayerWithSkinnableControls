package net.ericpetersen.media.videoPlayer {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.SoundTransform;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	/**
	 * @author ericpetersen
	 */
	public class VideoConnection extends EventDispatcher {
		/**
		* Dispatched when it is ready to play the video
		*
		* @eventType CONNECTION_READY
		*/
		public static const CONNECTION_READY:String = "CONNECTION_READY";
		
		/**
		* Dispatched when the MetaData is ready
		*
		* @eventType METADATA_READY
		*/
		public static const METADATA_READY:String = "METADATA_READY";
		
		/**
		* Dispatched when the cue point occurs.
		*
		* @eventType CUE_POINT
		*/
		public static const CUE_POINT:String = "CUE_POINT";
		
		/**
		* Dispatched when the player state changes. (UNSTARTED = -1, ENDED = 0, PLAYING = 1, PAUSED = 2)
		*
		* @eventType PLAYER_STATE_CHANGED
		*/
		public static const PLAYER_STATE_CHANGED:String = "PLAYER_STATE_CHANGED";
		
		public static const UNSTARTED:int = -1;
		public static const ENDED:int = 0;
		public static const PLAYING:int = 1;
		public static const PAUSED:int = 2;
		
		protected var _state:int;
		protected var _duration:Number;
		protected var _metaDataInfo:Object;
		protected var _cuePointInfo:Object;
		protected var _nc:NetConnection;
		protected var _ns:NetStream;
		protected var _st:SoundTransform;
		protected var _videoName : String;
		protected var _connectURL : String;
		
		/**
		 * @return the netStream
		 */
		public function get ns():NetStream {
			return _ns;
		}
		
		/**
		 * @return the metaDataInfo object
		 */
		public function get metaDataInfo():Object {
			return _metaDataInfo;
		}

		/**
		 * @return the cuePointInfo object
		 */
		public function get cuePointInfo():Object {
			return _cuePointInfo;
		}

		/**
		 * @return the videoName of the current video file if progressive
		 * or the stream name if using rtmp.
		 */
		public function get videoName():String {
			return _videoName;
		}
		
		/**
		 * @return the connectURL of the current video if using rtmp.
		 * Otherwise the value will be "".
		 */
		public function get connectURL():String {
			return _connectURL;
		}

		/**
		 * Constructor
		 * @param target IEventDispatcher
		 */
		public function VideoConnection(target:IEventDispatcher = null) {
			super(target);
			init();
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
			var bytesLoaded:Number = 0;
			if (ns) {
				bytesLoaded = ns.bytesLoaded;
			}
			return bytesLoaded;
		}
		
		/**
		 * Get the bytes total of the video
		 */
		public function getVideoBytesTotal():Number {
			var bytesTotal:Number = 0;
			if (ns) {
				bytesTotal = ns.bytesTotal;
			}
			return bytesTotal;
		}
		
		/**
		 * Get the current playback time of the video
		 */
		public function getCurrentTime():Number {
			var time:Number = 0;
			if (ns) {
				time = ns.time;
			}
			return time;
		}
		
		/**
		 * Get the total duration time of the video
		 */
		public function getDuration():Number {
			var duration:Number = 0;
			if (_duration > 0) {
				duration = _duration;
			}
			return duration;
		}
		
		/**
		 * Get the state of the video player
		 * (UNSTARTED = -1, ENDED = 0, PLAYING = 1, PAUSED = 2)
		 */
		public function getPlayerState():Number {
			// Returns the state of the player. Possible values are unstarted (-1), ended (0), playing (1), paused (2).
			return _state;
		}

		/**
		 * <p>Load the video</p>
		 * <p>Progressive: loadVideo("video/video01.flv");</p>
		 * <p>Streaming from rtmp://appName/streamName.flv: loadVideo("streamName", "rtmp://appName"); // streamName does not include ".flv"</p>
		 */
		public function loadVideo(videoName:String, connectURL:String = ""):void {
			setPlayerState(UNSTARTED);
			_videoName = videoName;
			_connectURL = connectURL;
			if (_nc) {
				_nc.close();
				_nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				_nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			}
			_nc = new NetConnection();
			var clientObj:Object = new Object();
			clientObj.onBWDone = onBWDone;
			_nc.client = clientObj;
			_nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
			_nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler, false, 0, true);
			if (connectURL == "") {
				_nc.connect(null);
			} else {
				_nc.connect(connectURL);
			}
		}
		
		/**
		 * Pause the video
		 */
		public function pauseVideo():void {
			if (ns) {
				trace("pauseVideo");
				ns.pause();
				setPlayerState(PAUSED);
			}
		}
		
		/**
		 * Play the video
		 */
		public function playVideo():void {
			trace("playVideo");
			if (_state == UNSTARTED) {
				trace("ns was null, loading video");
				ns.play(_videoName);
			} else {
				trace("resume");
				ns.resume();
			}
			setPlayerState(PLAYING);
		}
		
		/**
		 * Seek to a time in the video
		 * @param seconds
		 * @param allowSeekAhead
		 */
		public function seekTo(seconds:Number, allowSeekAhead:Boolean = false):void {
			if (ns) {
				ns.seek(seconds);
			}
		}
		
		/**
		 * Set the volume on the video
		 * @param value an integer from 0 to 100
		 */
		public function setVolume(value:int):void {
			if (_st && ns) {
				trace("setVolume : " + value);
				var pct:Number = value/100;
				_st.volume = pct; // 0 to 1
				ns.soundTransform = _st;
			}
		}
		
		/**
		 * Remove listeners and clean up
		 */
		public function destroy():void {
			if (_ns) {
				_ns.close();
				_ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			}
			if (_nc) {
				_nc.close();
				_nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				_nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			}
		}

		protected function init():void {
			setPlayerState(UNSTARTED);
		}
		
		protected function setPlayerState(value:int):void {
			// Possible values are unstarted (-1), ended (0), playing (1), paused (2).
			_state = value;
			dispatchEvent(new Event(PLAYER_STATE_CHANGED));
		}

		protected function netStatusHandler(event:NetStatusEvent):void {
			switch (event.info.code) {
				case "NetConnection.Connect.Success":
					connectStream();
					break;
				case "NetStream.Play.Stop":
					if (_ns.time > 0 && _ns.time >= (_duration - 0.5)) {
						setPlayerState(ENDED);
						dispatchEvent(new Event(PLAYER_STATE_CHANGED));
					}
					break;
				case "NetStream.Play.StreamNotFound":
					trace("Stream not found: " + _videoName);
					break;
				default :
					break;
			}
		}

		protected function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("securityErrorHandler: " + event);
		}

		protected function connectStream():void {
			trace("connectStream");
			if (_ns) {
				_ns.close();
				_ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			}
			_ns = new NetStream(_nc);
			_ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
			var clientObj:Object = new Object();
			clientObj.onMetaData = onMetaData;
			clientObj.onCuePoint = onCuePoint;
			_ns.client = clientObj;
			_st = new SoundTransform();
			_st.volume = 1;
			_ns.soundTransform = _st;
			playVideo();
			dispatchEvent(new Event(CONNECTION_READY));
		}

		protected function onMetaData(info:Object):void {
			trace("metadata: duration=" + info.duration + " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate);
			_metaDataInfo = info;
			_duration = info.duration;
			dispatchEvent(new Event(METADATA_READY));
		}

		protected function onCuePoint(info:Object):void {
			trace("cuepoint: time=" + info.time + " name=" + info.name + " type=" + info.type);
			_cuePointInfo = info;
			dispatchEvent(new Event(CUE_POINT));
		}

		protected function onBWDone(info:Object = null):void {
			trace("onBWDone");
		}
	}
}
