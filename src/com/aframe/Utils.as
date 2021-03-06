package com.aframe {

    import flash.display.Graphics;
    import flash.external.ExternalInterface;

    public class Utils {

        public static function drawRectangle(g:Graphics, x:Number, y:Number, w:Number, h:Number, color:Number, alpha:Number = 1):void {
            g.beginFill(color, alpha);
            g.drawRect(x, y, w, h);
            g.endFill();
        }

        public static function debug(info:Object):void {
            if (ExternalInterface.available) {
                ExternalInterface.call('VideoJS.flash.debug', debugObject(info));
            }
        }

        private static function debugObject(obj:Object):String {
            return JSON ? JSON.stringify(obj) : deepTrace(obj);
        }

        public static function deepTrace(obj:*, level:int = 0 ):String {
            if (obj == null) {
                return 'null'
            } else if (typeof(obj) === 'string' || typeof(obj) === 'number') {
                return obj.toString();
            }

            var s:String = "";
            for (var i:int = 0; i < level; i++) {
                s += "\t"
            }

            for (var prop:String in obj) {
                s += "[" + prop + "] -> " + deepTrace(obj[prop], level + 1);
            }
            return s;
        }

        public static function normalize(val:Number):Number {
            return Math.max(0, Math.min(1, val));
        }

    }
}