package com.aframe {

    import flash.events.Event;

    public class ScrubberEvent extends Event {
        public static var TYPE:String = "ScrubberEvent";

        private var _position:Number;

        public function ScrubberEvent(position:Number) {
            super(TYPE);
            _position = position;
        }

        public function get position():Number {
            return _position;
        }
    }
}