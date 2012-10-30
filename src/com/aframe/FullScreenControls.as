package com.aframe {

    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class FullScreenControls extends Sprite {
        [Embed (source = "img/leave-fullscreen.png")] private static var leaveFullScreenImg:Class;
        private static var leaveFullScreenBtn:Sprite = new ImageButton(leaveFullScreenImg, 13, 13);

        [Embed (source = "img/pause.png")] private static var pauseImg:Class;
        private static var pauseBtn:Sprite = new ImageButton(pauseImg, 18, 24);

        [Embed (source = "img/play.png")] private static var playImg:Class;
        private static var playBtn:Sprite = new ImageButton(playImg, 15, 24);

        [Embed (source = "img/volume.png")] private static var volumeImg:Class;
        private static var volumeBtn:Sprite = new ImageButton(volumeImg, 12, 16, false);

        private static var seekControl:Scrubber = new Scrubber();
        private static var volumeControl:Scrubber = new Scrubber();

        private var h:Number = 36;
        private var g:Graphics;

        public function FullScreenControls() {
            g = this.graphics;

            addChild(playBtn);
            addChild(pauseBtn);
            addChild(seekControl);
            addChild(volumeBtn);
            addChild(volumeControl);
            addChild(leaveFullScreenBtn);
        }

        public function render(stageWidth:Number, stageHeight:Number):void {
            var scrubberHeight:Number = 11;

            g.clear();
            Utils.drawRectangle(g, 0, 0, stageWidth, h, 0x000000, 0.8);

            seekControl.render(stageWidth - 210, scrubberHeight);
            volumeControl.render(50, scrubberHeight);
            pauseBtn.visible = false;

            setXAndCenterY(playBtn, 20);
            setXAndCenterY(pauseBtn, 20);
            setXAndCenterY(seekControl, 60);
            setXAndCenterY(volumeBtn, stageWidth - 120);
            setXAndCenterY(volumeControl, stageWidth - 100);
            setXAndCenterY(leaveFullScreenBtn, stageWidth - leaveFullScreenBtn.width - 10);

            this.height = h;
            this.width = stageWidth;
            this.x = 0;
            this.y = stageHeight - this.height + 1;
        }

        private function setXAndCenterY(obj:Sprite, x:Number):void {
            obj.x = x;
            obj.y = (h - obj.height) / 2;
        }

        public function addLeaveFullScreenClickListener(eventHandler:Function):void {
            leaveFullScreenBtn.addEventListener(MouseEvent.CLICK, eventHandler);
        }

        public function addPlayClickListener(eventHandler:Function):void {
            playBtn.addEventListener(MouseEvent.CLICK, eventHandler);
        }

        public function addPauseClickListener(eventHandler:Function):void {
            pauseBtn.addEventListener(MouseEvent.CLICK, eventHandler);
        }

        public function addVolumeListener(eventHandler:Function):void {
            volumeControl.addEventListener(ScrubberEvent.TYPE, eventHandler);
        }

        public function addSeekListener(eventHandler:Function):void {
            seekControl.addEventListener(ScrubberEvent.TYPE, eventHandler);
        }

        public function setVolumePosition(pos:Number):void {
            volumeControl.setPosition(pos);
        }

        public function setSeekPosition(pos:Number):void {
            seekControl.setPosition(pos);
        }

        public function showPlayButton():void {
            pauseBtn.visible = false;
            playBtn.visible = true;
        }

        public function showPauseButton():void {
            playBtn.visible = false;
            pauseBtn.visible = true;
        }

    }

}
