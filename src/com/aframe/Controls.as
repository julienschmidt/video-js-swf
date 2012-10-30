package com.aframe {

    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class Controls extends Sprite {

        private var isFullScreen:Boolean = false;
        private var g:Graphics;

        private var windowedControls:WindowedControls = new WindowedControls();
        private var fullScreenControls:FullScreenControls = new FullScreenControls();

        public function Controls() {
            g = this.graphics;

            addChild(windowedControls);
            addChild(fullScreenControls);

            this.addEventListener(MouseEvent.CLICK, stopPropagation);
        }

        private static function stopPropagation(e:MouseEvent):void {
            e.stopImmediatePropagation();
        }

        public function show():void {
            this.visible = true;
        }

        public function hide():void {
            // cannot hide controls in fullscreen mode
            if (isFullScreen) {
                return;
            }
            this.visible = false;
        }

        public function resizeToFitStage(stageWidth:Number, stageHeight:Number):void {
            render(stageWidth, stageHeight, isFullScreen);
        }

        public function render(stageWidth:Number, stageHeight:Number, fullScreen:Boolean):void {
            isFullScreen = fullScreen;
            if (isFullScreen) {
                windowedControls.visible = false;
                fullScreenControls.render(stageWidth, stageHeight);
                fullScreenControls.visible = true;
            } else {
                fullScreenControls.visible = false;
                windowedControls.render(stageWidth, stageHeight);
                windowedControls.visible = true;
            }
        }

        public function addFullScreenClickListener(eventHandler:Function):void {
            windowedControls.addFullScreenClickListener(eventHandler);
        }

        public function addLeaveFullScreenClickListener(eventHandler:Function):void {
            fullScreenControls.addLeaveFullScreenClickListener(eventHandler);
        }

        public function addPlayClickListener(eventHandler:Function):void {
            fullScreenControls.addPlayClickListener(eventHandler);
        }

        public function addPauseClickListener(eventHandler:Function):void {
            fullScreenControls.addPauseClickListener(eventHandler);
        }

        public function addVolumeListener(eventHandler:Function):void {
            fullScreenControls.addVolumeListener(eventHandler);
        }

        public function addSeekListener(eventHandler:Function):void {
            fullScreenControls.addSeekListener(eventHandler);
        }

        public function setVolumePosition(pos:Number):void {
            fullScreenControls.setVolumePosition(pos);
        }

        public function setSeekPosition(pos:Number):void {
            fullScreenControls.setSeekPosition(pos);
        }

        public function showPlayButton():void {
            fullScreenControls.showPlayButton();
        }

        public function showPauseButton():void {
            fullScreenControls.showPauseButton();
        }
    }

}