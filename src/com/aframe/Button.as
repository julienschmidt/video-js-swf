package com.aframe {

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;

    public class Button extends Sprite {

        public function Button() {
            this.addEventListener(MouseEvent.MOUSE_OVER, showPointerCursor);
            this.addEventListener(MouseEvent.MOUSE_OUT, showStandardCursor);
        }

        private static function showPointerCursor(e:MouseEvent):void {
            Mouse.cursor = "button";
        }

        private static function showStandardCursor(e:MouseEvent):void {
            Mouse.cursor = "auto";
        }
    }

}