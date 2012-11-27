package{
    import com.aframe.Controls;
    import com.aframe.ImageButton;
    import com.aframe.ScrubberEvent;
    import com.aframe.Utils;

    import com.videojs.VideoJSApp;
    import com.videojs.VideoJSModel;
    import com.videojs.VideoJSView;
    import com.videojs.events.VideoJSEvent;
    import com.videojs.structs.ExternalErrorEventName;

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageDisplayState;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.FullScreenEvent;
    import flash.events.IEventDispatcher;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.geom.Rectangle;
    import flash.media.Video;
    import flash.system.Security;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.utils.Timer;
    import flash.utils.setTimeout;
    
    [SWF(backgroundColor="#000000", frameRate="60", width="480", height="270")]
    public class VideoJS extends Sprite{
        private var controls:Controls = new Controls();

        private var isFullScreen:Boolean = false;

        private var _app:VideoJSApp;
        private var _stageSizeTimer:Timer;

        public function VideoJS(){
            _stageSizeTimer = new Timer(150);
            _stageSizeTimer.addEventListener(TimerEvent.TIMER, onStageSizeTimerTick);
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        private function init():void{
            // Allow JS calls from other domains
            Security.allowDomain("*");
            Security.allowInsecureDomain("*");

//            if (loaderInfo.hasOwnProperty("uncaughtErrorEvents")){
//                // we'll want to suppress ANY uncaught .debug errors in production (for the sake of ux)
//                IEventDispatcher(loaderInfo["uncaughtErrorEvents"]).addEventListener("uncaughtError", onUncaughtError);
//            }
            
            if(ExternalInterface.available){
                registerExternalMethods();
            }

            _app = new VideoJSApp();
            addChild(_app);

            addChild(controls);
            positionControls();

            controls.addFullScreenClickListener(onFullScreenClick);
            controls.addLeaveFullScreenClickListener(onLeaveFullScreenClick);
            controls.addPlayClickListener(onPlayClick);
            controls.addPauseClickListener(onPauseClick);

            controls.addVolumeListener(onVolume);
            controls.addSeekListener(onSeek);

            stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenChange);
            stage.addEventListener(MouseEvent.CLICK, stageClick);

            _app.model.stageRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);

            var _ctxMenu:ContextMenu = new ContextMenu();
            _ctxMenu.hideBuiltInItems();
            this.contextMenu = _ctxMenu;
        }

        private function positionControls():void {
            controls.resizeToFitStage(stage.stageWidth, stage.stageHeight);
        }

        private function onFullScreenChange(event:FullScreenEvent):void {
            isFullScreen = event.fullScreen;
            controls.render(stage.stageWidth, stage.stageHeight, isFullScreen);
            controls.setVolumePosition(_app.model.volume);
            displayCorrectSeekPosition();
            if (_app.model.paused) {
                controls.showPlayButton();
            } else {
                controls.showPauseButton();
            }
//            Utils.debug('full screen: ' + event.fullScreen ? 'enter' : 'exit');
        }

        private function displayCorrectSeekPosition():void {
            var duration:Number = _app.model.shownDuration;
            var time:Number = _app.model.time;
            var pos:Number = duration == 0 ? 0 : time / duration;
            controls.setSeekPosition(pos);
        }

        private function onFullScreenClick(e:MouseEvent):void {
//            Utils.debug('full screen click');
            stage.displayState = StageDisplayState.FULL_SCREEN;
        }

        private function onLeaveFullScreenClick(e:MouseEvent):void {
//            Utils.debug('full screen click');
            stage.displayState = StageDisplayState.NORMAL;
        }

        private function stageClick(e:MouseEvent):void {
//            Utils.debug('stage click - toggle')
            if (_app.model.paused) {
                _app.model.play();
                controls.showPauseButton();
            } else {
                _app.model.pause();
                controls.showPlayButton();
            }
        }

        private function onPlayClick(e:MouseEvent):void {
            _app.model.play();
            controls.showPauseButton();
        }

        private function onPauseClick(e:MouseEvent):void {
            _app.model.pause();
            controls.showPlayButton();
        }

        private function onVolume(e:ScrubberEvent):void {
            _app.model.volume = e.position;
            controls.setVolumePosition(_app.model.volume);
        }

        private function onSeek(e:ScrubberEvent):void {
            var duration:Number = _app.model.shownDuration;
            var newTime:Number = e.position * duration;

            // Don't let video end while scrubbing.
            if (newTime >= duration) {
                newTime = newTime - 0.1;
            }

//            Utils.debug('Flash scrubber wants seek to ' + newTime);

            _app.model.seekBySeconds(newTime);
            setTimeout(displayCorrectSeekPosition, 50);
        }

        private function registerExternalMethods():void{
            
            try{
                ExternalInterface.addCallback("vjs_echo", onEchoCalled);
                ExternalInterface.addCallback("vjs_getProperty", onGetPropertyCalled);
                ExternalInterface.addCallback("vjs_setProperty", onSetPropertyCalled);
                ExternalInterface.addCallback("vjs_autoplay", onAutoplayCalled);
                ExternalInterface.addCallback("vjs_src", onSrcCalled);
                ExternalInterface.addCallback("vjs_load", onLoadCalled);
                ExternalInterface.addCallback("vjs_play", onPlayCalled);
                ExternalInterface.addCallback("vjs_pause", onPauseCalled);
                ExternalInterface.addCallback("vjs_resume", onResumeCalled);
                ExternalInterface.addCallback("vjs_stop", onStopCalled);
                ExternalInterface.addCallback("vjs_hideControls", onHideControls);
                ExternalInterface.addCallback("vjs_showControls", onShowControls);
            }
            catch(e:SecurityError){
                if (loaderInfo.parameters.debug != undefined && loaderInfo.parameters.debug == "true") {
                    throw new SecurityError(e.message);
                }
            }
            catch(e:Error){
                Utils.debug(e.message);
                if (loaderInfo.parameters.debug != undefined && loaderInfo.parameters.debug == "true") {
                    throw new Error(e.message);
                }
            }
            finally{}
            
            setTimeout(finish, 50);
        }
        
        private function finish():void{
            
            if(loaderInfo.parameters.mode != undefined){
                _app.model.mode = loaderInfo.parameters.mode;
            }
            
            if(loaderInfo.parameters.eventProxyFunction != undefined){
                _app.model.jsEventProxyName = loaderInfo.parameters.eventProxyFunction;
            }
            
            if(loaderInfo.parameters.errorEventProxyFunction != undefined){
                _app.model.jsErrorEventProxyName = loaderInfo.parameters.errorEventProxyFunction;
            }
            
            if(loaderInfo.parameters.autoplay != undefined && loaderInfo.parameters.autoplay == "true"){
                _app.model.autoplay = true;
            }
            
            if(loaderInfo.parameters.preload != undefined && loaderInfo.parameters.preload == "true"){
                _app.model.preload = true;
            }
            
            if(loaderInfo.parameters.poster != undefined && loaderInfo.parameters.poster != ""){
                _app.model.poster = String(loaderInfo.parameters.poster);
            }

            _app.model.shownDuration = getValueFromFlashvars('duration');
            _app.model.startTime = getValueFromFlashvars('startTime');
            _app.model.endTime = getValueFromFlashvars('endTime');

            if (loaderInfo.parameters.subclip != undefined && loaderInfo.parameters.subclip == "true") {
                _app.model.subclip = true;
            }

            if (loaderInfo.parameters.src != undefined && loaderInfo.parameters.src != "") {
                var src:String = getSrcSupportingPseudostreaming(loaderInfo.parameters.src);
                Utils.debug('params: ' + src);
                _app.model.srcFromFlashvars = src;
            }
            else {
                if(loaderInfo.parameters.RTMPConnection != undefined && loaderInfo.parameters.RTMPConnection != ""){
                    _app.model.rtmpConnectionURL = loaderInfo.parameters.RTMPConnection;
                }
                if(loaderInfo.parameters.RTMPStream != undefined && loaderInfo.parameters.RTMPStream != ""){
                    _app.model.rtmpStream = loaderInfo.parameters.rtmpStream;
                }
            }
            
            if(loaderInfo.parameters.readyFunction != undefined){
                try{
                    ExternalInterface.call(loaderInfo.parameters.readyFunction, ExternalInterface.objectID);
                }
                catch(e:Error){
                    if (loaderInfo.parameters.debug != undefined && loaderInfo.parameters.debug == "true") {
                        throw new Error(e.message);
                    }
                }
            }
        }

        private function getSrcSupportingPseudostreaming(src:String):String {
            if (_app.model.subclip) {
                // TODO: end used in url should match seekpoint - move this logic to PseudoStreamProvider
                src += '&end=' + _app.model.endTime;
            }
            return src;
        }

        private function getValueFromFlashvars(name:String):Number {
            var value:Number = 0;
            if (loaderInfo.parameters[name] != undefined) {
                value = Number(loaderInfo.parameters[name]);
                if (isNaN(value)) {
                    value = 0;
                }
            }
            return value;
        }
        
        private function onAddedToStage(e:Event):void{
            stage.addEventListener(Event.RESIZE, onStageResize);
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            _stageSizeTimer.start();
        }
        
        private function onStageSizeTimerTick(e:TimerEvent):void{
            if(stage.stageWidth > 0 && stage.stageHeight > 0){
                _stageSizeTimer.stop();
                _stageSizeTimer.removeEventListener(TimerEvent.TIMER, onStageSizeTimerTick);
                init();
            }
        }
        
        private function onStageResize(e:Event):void{
            if(_app != null){
                _app.model.stageRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
                _app.model.broadcastEvent(new VideoJSEvent(VideoJSEvent.STAGE_RESIZE, {}));
            }
            positionControls();
        }
        
        private function onEchoCalled(pResponse:* = null):*{
            return pResponse;
        }
        
        private function onGetPropertyCalled(pPropertyName:String = ""):*{

            switch(pPropertyName){
                case "mode":
                    return _app.model.mode;
                case "autoplay":
                    return _app.model.autoplay;
                case "loop":
                    return _app.model.loop;
                case "preload":
                    return _app.model.preload;    
                    break;
                case "metadata":
                    return _app.model.metadata;
                    break;
                case "duration":
                    return _app.model.duration;
                    break;
                case "eventProxyFunction":
                    return _app.model.jsEventProxyName;
                    break;
                case "errorEventProxyFunction":
                    return _app.model.jsErrorEventProxyName;
                    break;
                case "currentSrc":
                    return _app.model.src;
                    break;
                case "currentTime":
                    displayCorrectSeekPosition();
                    return _app.model.timeWithShift;
                    break;
                case "time":
                    return _app.model.time;
                    break;
                case "initialTime":
                    return 0;
                    break;
                case "defaultPlaybackRate":
                    return 1;
                    break;
                case "ended":
                    return _app.model.hasEnded;
                    break;
                case "volume":
                    return _app.model.volume;
                    break;
                case "muted":
                    return _app.model.muted;
                    break;
                case "paused":
                    return _app.model.paused;
                    break;
                case "seeking":
                    return _app.model.seeking;
                    break;
                case "networkState":
                    return _app.model.networkState;
                    break;
                case "readyState":
                    return _app.model.readyState;
                    break;
                case "buffered":
                    return _app.model.buffered;
                    break;
                case "bufferedBytesStart":
                    return 0;
                    break;
                case "bufferedBytesEnd":
                    return _app.model.bufferedBytesEnd;
                    break;
                case "bytesTotal":
                    return _app.model.bytesTotal;
                    break;
                case "videoWidth":
                    return _app.model.videoWidth;
                    break;
                case "videoHeight":
                    return _app.model.videoHeight;
                    break;
            }
            return null;
        }
        
        private function onSetPropertyCalled(pPropertyName:String = "", pValue:* = null):void{

            switch(pPropertyName){
                case "mode":
                    _app.model.mode = String(pValue);
                    break;
                case "loop":
                    _app.model.loop = _app.model.humanToBoolean(pValue);
                    break;
                case "background":
                    _app.model.backgroundColor = _app.model.hexToNumber(String(pValue));
                    _app.model.backgroundAlpha = 1;
                    break;
                case "eventProxyFunction":
                    _app.model.jsEventProxyName = String(pValue);
                    break;
                case "errorEventProxyFunction":
                    _app.model.jsErrorEventProxyName = String(pValue);
                    break;
                case "preload":
                    _app.model.preload = _app.model.humanToBoolean(pValue);
                    break;
                case "poster":
                    _app.model.poster = String(pValue);
                    break;
                case "src":
                    _app.model.src = getSrcSupportingPseudostreaming(pValue);
//                    Utils.debug('setter: ' + _app.model.src);
                    break;
                case "currentTime":
//                    Utils.debug('JS wants to seek to: ' + Number(pValue));
                    _app.model.seekBySeconds(Number(pValue) - _app.model.startTime);
                    break;
                case "muted":
                    _app.model.muted = _app.model.humanToBoolean(pValue);
                    break;
                case "volume":
                    _app.model.volume = Number(pValue);
                    controls.setVolumePosition(Number(pValue));
                    break;
                case "RTMPConnection":
                    _app.model.rtmpConnectionURL = String(pValue);
                    break;
                case "RTMPStream":
                    _app.model.rtmpStream = String(pValue);
                    break;
                default:
                    _app.model.broadcastErrorEventExternally(ExternalErrorEventName.PROPERTY_NOT_FOUND, pPropertyName);
                    break;
            }
        }
        
        private function onAutoplayCalled(pAutoplay:* = false):void{
            _app.model.autoplay = _app.model.humanToBoolean(pAutoplay);
        }

        private function onSrcCalled(pSrc:* = ""):void {
            _app.model.src = getSrcSupportingPseudostreaming(pSrc);
//            Utils.debug('on src: ' + _app.model.src);
        }
        
        private function onLoadCalled():void{
            _app.model.load();
        }
        
        private function onPlayCalled():void{
            _app.model.play();
        }
        
        private function onPauseCalled():void{
            _app.model.pause();
        }
        
        private function onResumeCalled():void{
            _app.model.resume();
        }

        private function onStopCalled():void {
            _app.model.stop();
        }

//        private function onUncaughtError(e:Event):void {
//            e.preventDefault();
//            Utils.debug('uncaught error: ' + e.toString());
//        }

        private function onShowControls():void {
            controls.show();
        }

        private function onHideControls():void {
            controls.hide();
        }
    }
}
