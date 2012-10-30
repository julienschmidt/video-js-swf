package com.aframe {

    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class WindowedControls extends Sprite {
        [Embed (source = "img/fullscreen.png")] private static var fullScreenImg:Class;
        private static var fullScreenBtn:Sprite = new ImageButton(fullScreenImg, 13, 13);

        private var w:Number = 35;
        private var h:Number = 63;
        private var g:Graphics;

        public function WindowedControls() {
            g = this.graphics;

            addChild(fullScreenBtn);
        }

        public function render(stageWidth:Number, stageHeight:Number):void {
            g.clear();
            Utils.drawRectangle(g, 0, 0, w, h, 0x000000, 0.8);

            fullScreenBtn.x = (w - fullScreenBtn.width) / 2;
            fullScreenBtn.y = (h - fullScreenBtn.height) / 2;

            this.height = h;
            this.width = w;
            this.x = stageWidth - w;
            this.y = stageHeight - this.height;
        }

        public function addFullScreenClickListener(eventHandler:Function):void {
            fullScreenBtn.addEventListener(MouseEvent.CLICK, eventHandler);
        }
    }

}