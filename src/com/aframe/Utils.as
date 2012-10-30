package com.aframe {

    import flash.display.Graphics;
    import flash.external.ExternalInterface;

    public class Utils {

        public static function drawRectangle(g:Graphics, x:Number, y:Number, w:Number, h:Number, color:Number, alpha:Number = 1):void {
            g.beginFill(color, alpha);
            g.drawRect(x, y, w, h);
            g.endFill();
        }

        public static function debug(info:String):void {
            if (ExternalInterface.available) {
                ExternalInterface.call('console.log', info);
            }
        }

        public static function normalize(val:Number):Number {
            return Math.max(0, Math.min(1, val));
        }

    }
}