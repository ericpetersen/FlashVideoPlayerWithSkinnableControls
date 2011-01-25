package net.ericpetersen {
	import net.ericpetersen.media.videoPlayer.VideoPlayerWithControls;
	import net.ericpetersen.media.videoPlayer.controls.VideoPlayerControls;

	import flash.display.MovieClip;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	/**
	 * @author ericpetersen
	 */
	public class VideoPlayerWithControlsExample extends MovieClip {
		private var _videoPlayerWithControls:VideoPlayerWithControls;
		private var _videoWidth:Number = 480;
		private var _videoHeight:Number = 270;

		/**
		 * VideoPlayerWithControls example 
		 */
		public function VideoPlayerWithControlsExample() {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			var controlsAsset:MovieClip = new VideoPlayerControlsAsset();
			var videoPlayerControls:VideoPlayerControls = new VideoPlayerControls(controlsAsset, _videoWidth, true);
			_videoPlayerWithControls = new VideoPlayerWithControls(videoPlayerControls, _videoWidth, _videoHeight);
			_videoPlayerWithControls.x = 50;
			_videoPlayerWithControls.y = 50;
			addChild(_videoPlayerWithControls);
			
			/*
			 * Load the video
			 * Progressive: loadVideo("video/video01.flv");
			 * Streaming from rtmp://appName/streamName.flv: loadVideo("streamName", true, "rtmp://appName"); // streamName does not include ".flv"
			 */
			_videoPlayerWithControls.loadVideo("video/video01.flv");

		}
	}
}
