package com.aframe {

    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class Controls extends Sprite {
        [Embed (source = "img/fullscreen.png")] private static var fullScreenImg:Class;
        private static var fullScreenBtn:Sprite = new ImageButton(fullScreenImg, 13, 13);

        [Embed (source = "img/leave-fullscreen.png")] private static var leaveFullScreenImg:Class;
        private static var leaveFullScreenBtn:Sprite = new ImageButton(leaveFullScreenImg, 13, 13);

        [Embed (source = "img/pause.png")] private static var pauseImg:Class;
        private static var pauseBtn:Sprite = new ImageButton(pauseImg, 18, 24);

        [Embed (source = "img/play.png")] private static var playImg:Class;
        private static var playBtn:Sprite = new ImageButton(playImg, 15, 24);

        private static var scrubber:Scrubber = new Scrubber();

        private var w:Number = 35;
        private var h:Number = 63;
        private var isFullScreen:Boolean = false;
        private var g:Graphics;

        public function Controls() {
            g = this.graphics;

            addChild(playBtn);
            addChild(scrubber);

            addChild(fullScreenBtn);

            scrubber.addEventListener(ScrubberEvent.TYPE, seekHandler);
        }

        public function show():void {
            this.visible = true;
        }

        public function hide():void {
            this.visible = false;
        }

        public function resizeToFitStage(stageWidth:Number, stageHeight:Number):void {
            render(stageWidth, stageHeight, isFullScreen);
        }

        public function render(stageWidth:Number, stageHeight:Number, fullScreen:Boolean):void {
            isFullScreen = fullScreen;
            if (isFullScreen) {
                this.renderInFullScreen(stageWidth, stageHeight);
            } else {
                this.renderInWindow(stageWidth, stageHeight);
            }
        }

        private function renderInFullScreen(stageWidth:Number, stageHeight:Number):void {
            g.clear();
            Utils.drawRectangle(g, 0, 0, stageWidth, h, 0x111111, 0.8);

            fullScreenBtn.visible = false;

            playBtn.visible = true;
            playBtn.x = 10;
            playBtn.y = (h - playBtn.height) / 2;

            scrubber.visible = true;
//            scrubber.render(200, 11);
            scrubber.x = 50;
            scrubber.y = 20;

            this.height = h;
            this.width = stageWidth;
            this.x = 0;
            this.y = stageHeight - this.height;
        }

        private function renderInWindow(stageWidth:Number, stageHeight:Number):void {
            g.clear();
            Utils.drawRectangle(g, 0, 0, w, h, 0x111111, 0.8);

            fullScreenBtn.visible = true;
            fullScreenBtn.x = (w - fullScreenBtn.width) / 2;
            fullScreenBtn.y = (h - fullScreenBtn.height) / 2;

            playBtn.visible = false;
            scrubber.visible = false;

            this.height = h;
            this.width = w;
            this.x = stageWidth - w;
            this.y = stageHeight - this.height;
        }

        private function seekHandler(e:ScrubberEvent):void {
            scrubber.setPosition(e.position);
        }

        public function addFullScreenClickListener(eventHandler:Function):void {
            fullScreenBtn.addEventListener(MouseEvent.CLICK, eventHandler);
        }
    }

}