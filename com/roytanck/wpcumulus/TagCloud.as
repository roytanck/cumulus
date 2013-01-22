/*
	com.roytanck.wpcumulus.TagCloud
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
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.StageQuality;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.geom.ColorTransform;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.events.ContextMenuEvent;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import com.roytanck.wpcumulus.Tag;

	public class TagCloud extends MovieClip	{
		
		// private vars
		private var radius:Number;
		private var mcList:Array;
		private var dtr:Number;
		private var d:Number;
		private var sa:Number;
		private var ca:Number;
		private var sb:Number;
		private var cb:Number;
		private var sc:Number;
		private var cc:Number;
		private var originx:Number;
		private var originy:Number;
		private var tcolor:Number;
		private var hicolor:Number;
		private var tcolor2:Number;
		private var tspeed:Number;
		private var distr:Boolean;
		private var lasta:Number;
		private var lastb:Number;
		private var active:Boolean;
		private var tagData:Object;
		private var loader:URLLoader;
		private var xmlData:XML;
		
		// public vars
		public var holder:MovieClip;
		public var mousetrap:MovieClip;
		public var rtl:Boolean;
		public var fontname:String;
		public var fontweight:String;
		
		public function TagCloud(){
			// stage settings
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.quality = StageQuality.HIGH;
			stage.align = StageAlign.TOP_LEFT;
			// get settings from flashvars
			tcolor = ( this.loaderInfo.parameters.tcolor == null ) ? 0x000000 : Number(this.loaderInfo.parameters.tcolor);
			tcolor2 = ( this.loaderInfo.parameters.tcolor2 == null ) ? 0x003366 : Number(this.loaderInfo.parameters.tcolor2);
			hicolor = ( this.loaderInfo.parameters.hicolor == null ) ? 0x000000 : Number(this.loaderInfo.parameters.hicolor);
			tspeed = ( this.loaderInfo.parameters.tspeed == null ) ? 1 : Number(this.loaderInfo.parameters.tspeed)/100;
			distr = ( this.loaderInfo.parameters.distr != "true" );
			// get desired font properties
			rtl = ( this.loaderInfo.parameters.rtl == "true" );
			fontname = ( this.loaderInfo.parameters.fontname == null ) ? "_sans" : this.loaderInfo.parameters.fontname;
			fontweight = ( this.loaderInfo.parameters.fontweight == null ) ? "bold" : this.loaderInfo.parameters.fontweight;
			// add context menu item
			var myContextMenu:ContextMenu = new ContextMenu();
			myContextMenu.hideBuiltInItems();
			var item:ContextMenuItem = new ContextMenuItem("Cumulus Tag Cloud by Roy Tanck");
			myContextMenu.customItems.push(item);
			this.contextMenu = myContextMenu;
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuItemSelectHandler);
			// assemble the path to load the tags cloud data from (relative path for securoty reasons (NEEDS WORK!)
			var a:Array = this.loaderInfo.url.split("/");
			a.pop();
			var baseURL:String = a.join("/") + "/";
			var cloudpath:String = ( this.loaderInfo.parameters.cloudpath == null ) ? "tagcloud.xml" : this.loaderInfo.parameters.cloudpath;
			var reqUrl:String = ( this.loaderInfo.url.substr( 0, 4 ) == "http" ) ? baseURL + cloudpath : cloudpath;
			var req:URLRequest = new URLRequest( reqUrl );
			// catch flashvars, send them along with the request
			var fv:Object = LoaderInfo(this.root.loaderInfo).parameters;
			var urlVars:URLVariables = new URLVariables();
			for( var varStr:String in fv ){
				urlVars[varStr] = fv[varStr];
			}
			if( this.loaderInfo.url.substr( 0, 4 ) == "http" ){
				req.data = urlVars;
			}
			loader = new URLLoader( req );
			loader.addEventListener( "complete", init );
			loader.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
			loader.load( req );
		}
		
		private function init( e:Event ):void {
			// store XML data
			xmlData = new XML( loader.data );
			trace( xmlData );
			// set some vars
			radius = 150;
			dtr = Math.PI/180;
			d = 300;
			sineCosine( 0,0,0 );
			mcList = [];
			active = false;
			lasta = 1;
			lastb = 1;
			// create mousetrap mc
			mousetrap = new MovieClip();
			mousetrap.graphics.beginFill(0x000000,0);
			mousetrap.graphics.drawRect(0,0,100,100);
			addChildAt(mousetrap,0);
			// create holder mc, center it		
			holder = new MovieClip();
			addChild(holder);
			resizeHandler();
			// loop though them to find the smallest and largest tags
			var largest:Number = 0;
			var smallest:Number = 9999;
			for( var id:String in xmlData.tag ){
				var nr:Number = Number( xmlData.tag[id].size[0] );
				largest = Math.max( largest, nr );
				smallest = Math.min( smallest, nr );
			}
			// loop through tags, create movie clips
			for( var i:String in xmlData.tag ){
				// figure out what color it should be
				var nr2:Number = Number( xmlData.tag[i].size[0] );
				var perc:Number = ( smallest == largest ) ? 1 : (nr2-smallest) / (largest-smallest);
				var col:Number = ( xmlData.tag[i].color[0] == undefined ) ? getColorFromGradient( perc ) : Number( xmlData.tag[i].color[0] );
				var hicol:Number = ( xmlData.tag[i].hicolor[0] == undefined ) ? ( ( hicolor == tcolor ) ? getColorFromGradient( perc ) : hicolor ) : Number( xmlData.tag[i].hicolor[0] );
				// create mc
				var mc:Tag = new Tag( xmlData.tag[i], col, hicol, this );
				holder.addChild(mc);
				// store reference
				mcList.push( mc );
			}
			// distribute the tags on the sphere
			positionAll();
			// add event listeners
			addEventListener(Event.ENTER_FRAME, updateTags);
			stage.addEventListener(Event.MOUSE_LEAVE, mouseExitHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			stage.addEventListener(Event.RESIZE, resizeHandler);
		}

		private function updateTags( e:Event ):void {
			var a:Number;
			var b:Number;
			if( active ){
				a = (-Math.min( Math.max( holder.mouseY, -250 ), 250 ) / 150 ) * tspeed;
				b = (Math.min( Math.max( holder.mouseX, -250 ), 250 ) /150 ) * tspeed;
			} else {
				a = lasta * 0.98;
				b = lastb * 0.98;
			}
			lasta = a;
			lastb = b;
			// if a and b under threshold, skip motion calculations to free up the processor
			if( Math.abs(a) > 0.01 || Math.abs(b) > 0.01 ){
				var c:Number = 0;
				sineCosine( a, b, c );
				for( var j:Number=0; j<mcList.length; j++ ) {
					// multiply positions by a x-rotation matrix
					var rx1:Number = mcList[j].cx;
					var ry1:Number = mcList[j].cy * ca + mcList[j].cz * -sa;
					var rz1:Number = mcList[j].cy * sa + mcList[j].cz * ca;
					// multiply new positions by a y-rotation matrix
					var rx2:Number = rx1 * cb + rz1 * sb;
					var ry2:Number = ry1;
					var rz2:Number = rx1 * -sb + rz1 * cb;
					// multiply new positions by a z-rotation matrix
					var rx3:Number = rx2 * cc + ry2 * -sc;
					var ry3:Number = rx2 * sc + ry2 * cc;
					var rz3:Number = rz2;
					// set arrays to new positions
					mcList[j].cx = rx3;
					mcList[j].cy = ry3;
					mcList[j].cz = rz3;
					// add perspective
					var per:Number = d / (d+rz3);
					// set mc position, scale, alpha
					mcList[j].x = rx3 * per;
					mcList[j].y = ry3 * per;
					mcList[j].scaleX = mcList[j].scaleY = per;
					mcList[j].alpha = per/2;
				}
				depthSort();
			}
		}
		
		private function depthSort():void {
			mcList.sortOn( "cz", Array.DESCENDING | Array.NUMERIC );
			var current:Number = 0;
			for( var i:Number=0; i<mcList.length; i++ ){
				holder.setChildIndex( mcList[i], i );
				if( mcList[i].active == true ){
					current = i;
				}
			}
			holder.setChildIndex( mcList[current], mcList.length-1 );
		}
		
		private function positionAll():void {		
			var phi:Number = 0;
			var theta:Number = 0;
			var max:Number = mcList.length;
			// mix up the list so not all a' live on the north pole
			mcList.sort( function():Number { return Math.random()<0.5 ? 1 : -1; } );
			// distibute
			for( var i:Number=1; i<max+1; i++){
				if( distr ){
					phi = Math.acos(-1+(2*i-1)/max);
					theta = Math.sqrt(max*Math.PI)*phi;
				} else {
					phi = Math.random()*(Math.PI);
					theta = Math.random()*(2*Math.PI);
				}
				// Coordinate conversion
				mcList[i-1].cx = radius * Math.cos(theta)*Math.sin(phi);
				mcList[i-1].cy = radius * Math.sin(theta)*Math.sin(phi);
				mcList[i-1].cz = radius * Math.cos(phi);
			}
		}
		
		private function menuItemSelectHandler( e:ContextMenuEvent ):void {
			var request:URLRequest = new URLRequest( "http://www.cumulus-cloud.org" );
			navigateToURL(request);
		}
		
		private function mouseExitHandler( e:Event ):void { active = false; }
		private function mouseMoveHandler( e:MouseEvent ):void { active = true; }
		
		private function resizeHandler( e:Event = null ):void {
			var s:Stage = this.stage;
			holder.x = s.stageWidth/2;
			holder.y = s.stageHeight/2;
			var scale:Number;
			if( s.stageWidth > s.stageHeight ){
				scale = (s.stageHeight/500);
			} else {
				scale = (s.stageWidth/500);
			}
			holder.scaleX = holder.scaleY = scale;
			// scale mousetrap too
			mousetrap.width = s.stageWidth;
			mousetrap.height = s.stageHeight;
		}
		
		private function sineCosine( a:Number, b:Number, c:Number ):void {
			sa = Math.sin(a * dtr);
			ca = Math.cos(a * dtr);
			sb = Math.sin(b * dtr);
			cb = Math.cos(b * dtr);
			sc = Math.sin(c * dtr);
			cc = Math.cos(c * dtr);
		}
		
		private function getColorFromGradient( perc:Number ):Number {
			var r:Number = ( perc * ( tcolor >> 16 ) ) + ( (1-perc) * ( tcolor2 >> 16 ) );
			var g:Number = ( perc * ( (tcolor >> 8) % 256 ) ) + ( (1-perc) * ( (tcolor2 >> 8) % 256 ) );
			var b:Number = ( perc * ( tcolor % 256 ) ) + ( (1-perc) * ( tcolor2 % 256 ) );
			return( (r << 16) | (g << 8) | b );
		}

		private function ioErrorHandler(e:IOErrorEvent):void { displayError( "IO error: "+e ); }
		
		private function displayError( msg:String ):void {
			trace( msg );
			var debug:TextField = new TextField();
			debug.width = stage.stageWidth;
			debug.height = stage.stageHeight;
			debug.multiline = true;
			debug.wordWrap = true;
			debug.background = true;
			debug.text = msg;
			addChild( debug );
		}
		
	}

}
