package com.aframe {

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;

    public class ImageButton extends Button {

        public function ImageButton(img:Class, width:Number, height:Number, clickable:Boolean = true) {
            super(clickable);

            var bmp:Bitmap = new img();
            bmp.width = width;
            bmp.height = height;

            this.addChild(bmp);
        }
    }

}