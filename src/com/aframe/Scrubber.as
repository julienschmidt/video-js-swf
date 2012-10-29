package com.aframe {

    import com.aframe.Utils;

    import flash.display.Graphics;
    import flash.events.MouseEvent;

    public class Scrubber extends Button {

        private var g:Graphics;

        public function Scrubber() {
            g = this.graphics;

            this.addEventListener(MouseEvent.CLICK, clickHandler);
        }

        public function render(w:Number, h:Number, position:Number = 0):void {
            g.clear();
            Utils.drawRectangle(g, 0, 0, w, h, 0x333333);

            if (position != 0) {
                Utils.drawRectangle(g, 0, 0, w * position, h, 0x1CBCDE);
            }

            this.width = w;
            this.height = h;
        }

        private function clickHandler(e:MouseEvent):void {
            var pos:Number = e.localX / this.width;
            this.dispatchEvent(new ScrubberEvent(pos));
        }

        public function setPosition(position:Number):void {
            render(this.width, this.height, position);
        }

    }
}