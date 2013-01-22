/*
	com.roytanck.wpcumulus.Tag
	Copyright: Roy Tanck 
		
	This file is part of WP-Cumulus.

	WP-Cumulus is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	WP-Cumulus is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with WP-Cumulus.  If not, see <http://www.gnu.org/licenses/>.
*/

package com.roytanck.wpcumulus
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.display.Graphics;
	import flash.geom.ColorTransform;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.geom.Matrix;
	import flash.text.engine.*;
	import com.roytanck.wpcumulus.TagCloud;
	
	public class Tag extends Sprite {
		
		private var _object:Object;
		private var _cx:Number;
		private var _cy:Number;
		private var _cz:Number;
		private var _color:Number;
		private var _hicolor:Number;
		private var _active:Boolean;
		
		public function Tag( o:Object, color:Number, hicolor:Number, cloud:TagCloud ){
			_object = o;
			_color = color;
			_hicolor = hicolor;
			_active = false;
			// get some settings from the main timeline
			var scale:Number = cloud.holder.scaleX;
			// determine scale factor for bitmap copy of tag
			var scaleFactor:Number = scale * 2; // add resolution to bitmap copy by rendering bigger at larger canvas sizes
			var scaleFactor2:Number = 5; // extra scale factor used to get better kerning
			// styles, etc
			var fd:FontDescription = new FontDescription();
			fd.fontName = cloud.fontname;
			fd.fontLookup = FontLookup.DEVICE;
			if( cloud.fontweight == "bold" ){ fd.fontWeight = FontWeight.BOLD; }
			fd.renderingMode = RenderingMode.NORMAL;
			var fm:ElementFormat = new ElementFormat(); 
			fm.fontDescription = fd;
			fm.fontSize = ( Number(_object.size[0]) * 2) * scaleFactor * scaleFactor2;
			fm.color = _color;
			fm.kerning = Kerning.ON;
			// create instances
			var tb:TextBlock = new TextBlock();
			if( cloud.rtl ){ tb.bidiLevel = 1; } // set rtl is specified
			var te:TextElement = new TextElement( _object.text[0], fm );
			tb.content = te;
			var tl:TextLine = tb.createTextLine(null);
			addChild(tl);
			// create BitmapData copy of text to animate smoothly
			var bmd:BitmapData = new BitmapData( tl.textWidth/scaleFactor2, tl.textHeight/scaleFactor2, true, 0 );
			var m:Matrix = new Matrix();
			m.translate( 0, tl.ascent );
			m.scale ( 1/scaleFactor2, 1/scaleFactor2 );
			bmd.draw( tl, m );
			var b:Bitmap = new Bitmap( bmd );
			b.smoothing = true;
			//b.pixelSnapping = PixelSnapping.NEVER;
			addChild(b);
			// hide original text objects, show copy image instead
			tl.visible = false;
			removeChild(tl);
			tl = null;
			tb= null;
			fd = null;
			fm = null;
			b.scaleX = b.scaleY = 1/scaleFactor; // reduce back down to get sharper image allowing for scaling
			b.x = -b.width/2;
			b.y = -b.height/2;
			// check for http links only
			//if( _object.href.substr(0,4).toLowerCase() == "http" ){
			if( _object.href[0] != null ){
				// force mouse cursor on rollover
				this.mouseChildren = false;
				this.buttonMode = true;
				this.useHandCursor = true;
				// events
				this.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				this.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
				this.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			}
		}
		
		private function mouseOverHandler( e:MouseEvent ):void {
			var ct:ColorTransform = this.transform.colorTransform;
			ct.color = _hicolor;
			this.transform.colorTransform = ct;
			_active = true;
		}
		
		private function mouseOutHandler( e:MouseEvent ):void {
			var ct:ColorTransform = this.transform.colorTransform;
			ct.color = _color;
			this.transform.colorTransform = ct;
			_active = false;
		}
		
		private function mouseUpHandler( e:MouseEvent ):void {
			var request:URLRequest = new URLRequest( _object.href[0] );
			var target:String = _object.target[0] == undefined ? "_self" : _object.target[0];
			navigateToURL( request, target );
		}

		// setters and getters
		public function set cx( n:Number ):void { _cx = n; }
		public function get cx():Number { return _cx; }
		public function set cy( n:Number ):void { _cy = n; }
		public function get cy():Number { return _cy; }
		public function set cz( n:Number ):void { _cz = n; }
		public function get cz():Number { return _cz; }
		public function get active():Boolean { return _active; }

	}

}
