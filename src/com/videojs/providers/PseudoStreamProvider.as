package com.videojs.providers{

    import com.aframe.Utils;

    import com.videojs.VideoJSModel;
    import com.videojs.events.VideoPlaybackEvent;
    import com.videojs.structs.ExternalErrorEventName;
    import com.videojs.structs.ExternalEventName;
    import com.videojs.structs.PlaybackType;

    import flash.events.EventDispatcher;
    import flash.events.NetStatusEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.media.Video;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.utils.Timer;
    import flash.utils.getTimer;

    // modified version of PseudoStreamProvider code from FlowPlayer, http://flowplayer.org
    // By: Anssi Piirainen, <support@flowplayer.org>
    // Copyright (c) 2008-2011 Flowplayer Oy
    // H.264 support by: Arjen Wagenaar, <h264@code-shop.com>
    // Copyright (c) 2009 CodeShop B.V.
    public class PseudoStreamProvider extends EventDispatcher implements IProvider {

        private var _nc:NetConnection;
        private var _ns:NetStream;
        private var _throughputTimer:Timer;
        private var _currentThroughput:int = 0; // in B/sec
        private var _loadStartTimestamp:int;
        private var _loadStarted:Boolean = false;
        private var _loadCompleted:Boolean = false;
        private var _loadErrored:Boolean = false;
        private var _pauseOnStart:Boolean = false;
        private var _pausePending:Boolean = false;
        private var _videoReference:Video;

        private var _seekDataStore:SeekDataStore;

        /**
         * When the player is paused, and a seek is executed, the NetStream.time property will NOT update until the decoder encounters a new time tag,
         * which won't happen until playback is resumed. This wrecks havoc with external scrubber logic, so when the player is paused and a seek is requested,
         * we cache the intended time, and use it IN PLACE OF NetStream's time when the time accessor is hit.
         */
        private var _pausedSeekValue:Number = -1;

        private var _src:Object;
        private var _metadata:Object;
        private var _isPlaying:Boolean = false;
        private var _isPaused:Boolean = true;
        private var _isBuffering:Boolean = false;
        private var _isSeeking:Boolean = false;
        private var _canSeekAhead:Boolean = false;
        private var _hasEnded:Boolean = false;
        private var _canPlayThrough:Boolean = false;
        private var _loop:Boolean = false;

        protected var _model:VideoJSModel;

        public function PseudoStreamProvider(){
            _model = VideoJSModel.getInstance();
            _metadata = {};
            _throughputTimer = new Timer(250, 0);
            _throughputTimer.addEventListener(TimerEvent.TIMER, onThroughputTimerTick);

        }

        public function get loop():Boolean{
            return _loop;
        }

        public function set loop(pLoop:Boolean):void{
            _loop = pLoop;
        }

//        private var lastTime:Number = 0;
        public function get time():Number {
            if (_ns != null) {
                if (_pausedSeekValue != -1) {
                    return _pausedSeekValue;
                } else {
                    var t:Number = _serverSeekInProgress ? 0 : _ns.time;

                    var value:Number = _seekDataStore
                            ? _seekDataStore.currentPlayheadTime(t, _model.startTime)
                            : _ns.time - _model.startTime;

                    // TODO: calculate shownDuration based on start and end params in url
                    if (_model.subclip && Math.abs(_model.shownDuration - value) <= 1) {
                        // duration configured and we are reaching the end. Round the value so that end is reached at the correct configured end point.
                        value = Math.ceil(value);
                    }

//                    if (lastTime != value) {
//                        Utils.debug('t ' + value);
//                        lastTime = value;
//                    }

                    return value < 0 ? 0 : value;
                }
            }
            else {
                return 0;
            }
        }

        private var _duration:Number = 0;

        public function get duration():Number{
            return _duration;
        }

        private function setDuration(val:Number):void {
            _duration = val;
        }

        public function get readyState():int{
            // if we have metadata and a known duration
            if(_metadata != null && _metadata.duration != undefined){
                // if playback has begun
                if(_isPlaying){
                    // if the asset can play through without rebuffering
                    if(_canPlayThrough){
                        return 4;
                    }
                    // if we don't know if the asset can play through without buffering
                    else{
                        // if the buffer is full, we assume we can seek a head at least a keyframe
                        if(_ns.bufferLength >= _ns.bufferTime){
                            return 3;
                        }
                        // otherwise, we can't be certain that seeking ahead will work
                        else{
                            return 2;
                        }
                    }
                }
                // if playback has not begun
                else{
                    return 1;
                }
            }
            // if we have no metadata
            else{
                return 0;
            }
        }

        public function get networkState():int{
            if (!_loadStarted) {
                return 0;
            }
            else if (_loadCompleted) {
                return 1;
            }
            else if (_loadErrored) {
                return 3;
            }
            else {
                return 2;
            }
        }

        public function get buffered():Number{
            if(duration > 0){
                return (_ns.bytesLoaded / _ns.bytesTotal) * duration;
            }
            else{
                return 0;
            }
        }

        public function get bufferedBytesEnd():int{
            return _loadStarted ? _ns.bytesLoaded : 0;
        }

        public function get bytesLoaded():int{
            return 0;
        }

        public function get bytesTotal():int{
            return 0;
        }

        public function get playing():Boolean{
            return _isPlaying;
        }

        public function get paused():Boolean{
            return _isPaused;
        }

        public function get ended():Boolean{
            return false;
        }

        public function get seeking():Boolean{
            return _isSeeking;
        }

        public function get usesNetStream():Boolean{
            return true;
        }

        public function get metadata():Object{
            return _metadata;
        }

        public function set src(pSrc:Object):void{
            init(pSrc, false);
        }

        public function get srcAsString():String{
            if(_src != null){
                return _src.path;
            }
            return "";
        }

        public function init(pSrc:Object, pAutoplay:Boolean):void{
            _src = pSrc;
            _loadErrored = false;
            _loadStarted = false;
            _loadCompleted = false;
            if(pAutoplay){
                initNetConnection();
            }
        }

        public function load():void{
            _pauseOnStart = true;
            _isPlaying = false;
            _isPaused = true;
            initNetConnection();
        }

        public function play():void{
            // if this is a fresh playback request
            if(!_loadStarted){
                _pauseOnStart = false;
                _isPlaying = false;
                _isPaused = false;
                // _metadata = {};
                initNetConnection();
            }
            // if the asset is already loading
            else{
                _pausePending = false;
                _ns.resume();
                _isPaused = false;
                _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
                _model.broadcastEventExternally(ExternalEventName.ON_START);
                _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_START, {}));
            }
        }

        public function pause():void{
            if(_isPlaying && !_isPaused){
                _ns.pause();
                _isPaused = true;
                _model.broadcastEventExternally(ExternalEventName.ON_PAUSE);
                if(_isBuffering){
                    _pausePending = true;
                }
            }
        }

        public function resume():void{
            if(_isPlaying && _isPaused){
                _ns.resume();
                _isPaused = false;
                _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
                _model.broadcastEventExternally(ExternalEventName.ON_START);
            }
        }

        private var _bufferStart:Number = 0;
        private var _serverSeekInProgress:Boolean = false;

        public function get bufferStart():Number {
            return _bufferStart - _model.startTime;
        }

        public function get bufferEnd():Number {
            if (!_ns) return 0;
            return bufferStart + _ns.bytesLoaded / _ns.bytesTotal * (duration - bufferStart);
        }

        private function isInBuffer(seconds:Number):Boolean {
            if (!_seekDataStore || !_seekDataStore.dataAvailable) {
                Utils.debug("No keyframe data available, can only seek inside the buffer");
                return true;
            }

            return bufferStart <= seconds - _model.startTime && seconds - _model.startTime <= bufferEnd;
        }

        private function serverSeek(_ns:NetStream, seconds:Number, setBufferStart:Boolean = true):void {
            if (setBufferStart) {
                _bufferStart = seconds;
            }

            // issue #315
            //this resets on replay before time is updated
            if (seconds == 0) {
                _seekDataStore.reset();
            }

            var requestUrl:String = appendQueryString(srcAsString, seconds);
            Utils.debug("doing server seek, url " + requestUrl);
            _serverSeekInProgress = true;

            if (_isPaused) {
                _pausePending = true;
            }
            _ns.play(requestUrl);
        }

        private function appendQueryString(url:String, start:Number):String {
            if (start == 0) return url;

            var query:String = url + '&start=' + _seekDataStore.getQueryStringStartValue(start);

            return query;
        }

        protected function doSeek(seconds:Number):void {
            var target:Number = seconds + _model.startTime;

            //if target is near the end do a server seek to get the correct seekpoint to end correctly.
            if (isInBuffer(target)) {
                Utils.debug("seeking inside buffer, target " + target + " seconds");
                if (_seekDataStore) {
                    target = _seekDataStore.inBufferSeekTarget(target);
                }
                _ns.seek(target);
            } else {
                serverSeek(_ns, target);
            }
        }

        public function seekBySeconds(pTime:Number):void{
            if(_isPlaying){
                if(duration != 0 && pTime <= duration){
                    _isSeeking = true;
                    _throughputTimer.stop();
                    if(_isPaused){
                        _pausedSeekValue = pTime;
                    }
                    doSeek(pTime);
                    _isBuffering = true;
                }
            }
            else if (_hasEnded){
                doSeek(pTime);
                _isPlaying = true;
                _hasEnded = false;
                _isBuffering = true;
            } else {
                // just doing seek
                doSeek(pTime);
            }
        }

        public function stop():void{
            if(_isPlaying){
                _ns.close();
                _isPlaying = false;
                _hasEnded = true;
                _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_CLOSE, {}));
                _throughputTimer.stop();
                _throughputTimer.reset();
            }
        }

        public function attachVideo(pVideo:Video):void{
            _videoReference = pVideo;
        }

        public function die():void{

        }

        private function initNetConnection():void{
            if(_nc == null){
                _nc = new NetConnection();
                _nc.client = this;
                _nc.addEventListener(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
                _nc.connect(null);
            }
        }

        private function initNetStream():void{
            if(_ns != null){
                _ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
                _ns = null;
            }
            _ns = new NetStream(_nc);
            _ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
            _ns.client = this;
            _ns.bufferTime = .5;
            _ns.play(_src.path);
            _videoReference.attachNetStream(_ns);

            _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_READY, {ns:_ns}));
        }

        private function calculateThroughput():void{
            // if it's finished loading, we can kill the calculations and assume it can play through
            if(_ns.bytesLoaded == _ns.bytesTotal){
                _canPlayThrough = true;
                _loadCompleted = true;
                _throughputTimer.stop();
                _throughputTimer.reset();
                _model.broadcastEventExternally(ExternalEventName.ON_CAN_PLAY_THROUGH);
            }
            // if it's still loading, but we know its duration, we can check to see if the current transfer rate
            // will sustain uninterrupted playback - this requires the duration to be known, which is currently
            // only accessible via metadata, which isn't parsed until the Flash Player encounters the metadata atom
            // in the file itself, which means that this logic will only work if the asset is playing - preload
            // won't ever cause this logic to run :(
            else if(_ns.bytesTotal > 0 && _metadata != null && _metadata.duration != undefined){
                _currentThroughput = _ns.bytesLoaded / ((getTimer() - _loadStartTimestamp) / 1000);
                var __estimatedTimeToLoad:Number = (_ns.bytesTotal - _ns.bytesLoaded) * _currentThroughput;
                if(__estimatedTimeToLoad <= _metadata.duration){
                    _throughputTimer.stop();
                    _throughputTimer.reset();
                    _canPlayThrough = true;
                    _model.broadcastEventExternally(ExternalEventName.ON_CAN_PLAY_THROUGH);
                }
            }
        }

        private function onNetConnectionStatus(e:NetStatusEvent):void{
            // Utils.debug(e.info.code);
            switch(e.info.code){
                case "NetConnection.Connect.Success":
                    initNetStream();
                    break;
                case "NetConnection.Connect.Failed":
                    break;
            }
            _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_NETCONNECTION_STATUS, {info:e.info}));
        }

        private function serverSeekDone():void {
            if (_serverSeekInProgress) {
                _serverSeekInProgress = false;
                _model.broadcastEventExternally(ExternalEventName.ON_SEEK_COMPLETE);
            }
        }

        private function onNetStreamStatus(e:NetStatusEvent):void{
//            Utils.debug(e.info.code);
//            Utils.debug('server seek: ' + _serverSeekInProgress);
            switch(e.info.code){
                case "NetStream.Play.Start":
                    serverSeekDone();

                    _pausedSeekValue = -1;
//                    _metadata = null;
                    _canPlayThrough = false;
                    _hasEnded = false;
                    _isBuffering = true;
                    _currentThroughput = 0;
                    _loadStartTimestamp = getTimer();
                    _throughputTimer.reset();
                    _throughputTimer.start();
                    _model.broadcastEventExternally(ExternalEventName.ON_LOAD_START);
                    _model.broadcastEventExternally(ExternalEventName.ON_BUFFER_EMPTY);
                    if(_pauseOnStart && _loadStarted == false){
                        _ns.pause();
                        _isPaused = true;
                    }
                    else{
                        _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
                        _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_START, {info:e.info}));
                    }
                    _loadStarted = true;
                    break;

                case "NetStream.Buffer.Flush":
                    _isBuffering = true;
                    break;

                case "NetStream.Buffer.Full":
                    serverSeekDone();
                    _pausedSeekValue = -1;
                    _isBuffering = false;
                    _isPlaying = true;
                    _model.broadcastEventExternally(ExternalEventName.ON_BUFFER_FULL);
                    _model.broadcastEventExternally(ExternalEventName.ON_CAN_PLAY);
                    _model.broadcastEventExternally(ExternalEventName.ON_START);
                    if(_pausePending){
                        _pausePending = false;
                        _ns.pause();
                        _isPaused = true;
                    }
                    break;

                case "NetStream.Buffer.Empty":
                    _isBuffering = true;
                    _model.broadcastEventExternally(ExternalEventName.ON_BUFFER_EMPTY);
                    break;

                case "NetStream.Play.Stop":
                    serverSeekDone();
                    if(!_loop){
                        _isPlaying = false;
                        _hasEnded = true;
                        _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_CLOSE, {info:e.info}));
                        _model.broadcastEventExternally(ExternalEventName.ON_PLAYBACK_COMPLETE);
                    }
                    else{
                        _ns.seek(0);
                    }

                    _throughputTimer.stop();
                    _throughputTimer.reset();
                    break;

                case "NetStream.Seek.Notify":
                    _isPlaying = true;
                    _isSeeking = false;
                    _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_STREAM_SEEK_COMPLETE, {info:e.info}));
                    _model.broadcastEventExternally(ExternalEventName.ON_SEEK_COMPLETE);
                    _model.broadcastEventExternally(ExternalEventName.ON_BUFFER_EMPTY);
                    _currentThroughput = 0;
                    _loadStartTimestamp = getTimer();
                    _throughputTimer.reset();
                    _throughputTimer.start();
                    break;

                case "NetStream.Play.StreamNotFound":
                    _loadErrored = true;
                    _model.broadcastErrorEventExternally(ExternalErrorEventName.SRC_404);
                    break;
            }
            _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_NETSTREAM_STATUS, {info:e.info}));
        }

        private function onThroughputTimerTick(e:TimerEvent):void{
            calculateThroughput();
        }

        public function onMetaData(pMetaData:Object):void{
//            Utils.debug("received metadata");

            // TODO: check if it is a new file
            if (!_seekDataStore) {
                _metadata = pMetaData;

                _seekDataStore = new SeekDataStore(_metadata);

                if (_metadata.duration != undefined) {
                    _canSeekAhead = true;
                    setDuration(_metadata.duration);
                    _model.broadcastEventExternally(ExternalEventName.ON_DURATION_CHANGE, _metadata.duration);
                } else{
                    _canSeekAhead = false;
                }

                _model.broadcastEvent(new VideoPlaybackEvent(VideoPlaybackEvent.ON_META_DATA, {metadata:_metadata}));
                _model.broadcastEventExternally(ExternalEventName.ON_METADATA, _metadata);
            }
        }

        public function onPlayStatus(e:Object):void{

        }
    }
}