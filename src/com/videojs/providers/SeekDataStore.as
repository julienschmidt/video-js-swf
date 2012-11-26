package com.videojs.providers {

    import com.aframe.Utils;

    // modified version of DefaultSeekDataStore and H264SeekDataStore code from FlowPlayer, http://flowplayer.org
    // By: Anssi Piirainen, <support@flowplayer.org>
    // Copyright (c) 2008-2011 Flowplayer Oy
    // H.264 support by: Arjen Wagenaar, <h264@code-shop.com>
    // Copyright (c) 2009 CodeShop B.V.
    public class SeekDataStore {
        protected var _keyFrameTimes:Array;
        private var _prevSeekTime:Number = 0;

        public function SeekDataStore(metaData:Object) {
            if (!metaData) return;
            Utils.debug("will extract keyframe metadata");
            try {
                _keyFrameTimes = extractKeyFrameTimes(metaData);
            } catch (e:Error) {
                Utils.debug("error getting keyframes " + e.message);
                // TODO: dispatch error
            }
        }

        protected function extractKeyFrameTimes(metadata:Object):Array {
            var times:Array = new Array();
            for (var j:Number = 0; j != metadata.seekpoints.length; ++j) {
                times[j] = Number(metadata.seekpoints[j]['time']);
//                Utils.debug(times[j]);
            }
            return times;
        }

        internal function allowRandomSeek():Boolean {
            return _keyFrameTimes != null && _keyFrameTimes.length > 0;
        }

        internal function get dataAvailable():Boolean {
            return _keyFrameTimes != null;
        }

        public function getQueryStringStartValue(seekPosition: Number, rangeBegin:Number = 0, rangeEnd:Number = undefined):Number {
            if (!rangeEnd) {
                rangeEnd = _keyFrameTimes.length - 1;
            }
            if (rangeBegin == rangeEnd || rangeEnd - rangeBegin == 1) {
                _prevSeekTime =_keyFrameTimes[rangeBegin];
                return     queryParamValue(rangeBegin);
            }

            var rangeMid:Number = Math.floor((rangeEnd + rangeBegin)/2);
            if (_keyFrameTimes[rangeMid] >= seekPosition) {
                return getQueryStringStartValue(seekPosition, rangeBegin, rangeMid);
            } else {
                var offset:Number = (rangeEnd - rangeMid) == 1 ? 0 : 1;
                return getQueryStringStartValue(seekPosition, rangeMid + offset, rangeEnd);
            }
        }

        protected function queryParamValue(pos:Number):Number {
            return _keyFrameTimes[pos] + 0.01;
        }

        public function reset():void {
            _prevSeekTime = 0;
        }

        public function inBufferSeekTarget(target:Number):Number {
            return Math.max(target - _prevSeekTime, 0);
        }

        public function currentPlayheadTime(time:Number, start:Number):Number {
            return time - start + _prevSeekTime;
        }
    }

}