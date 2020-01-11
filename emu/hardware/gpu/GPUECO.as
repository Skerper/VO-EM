package emu.hardware.gpu 
{
	import com.debug.Console;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.events.Event;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import emu.hardware.proto_Device;
	import emu.hardware.mainboard.proto_Motherboard;
	import org.flashdevelop.utils.FlashConnect;
	import com.memory.StringManip;
	/**
	 * This is the economy version of the GPU. 
	 * Layer 0 is always tiles and non-transparent
	 * Layer 1 is always sprites and non-scrollable
	 * Layer 2 is always tiles
	 * Layer 3 is always tiles and non-scrollable
	 * @author Elliott Smith [voidSkipper]
	 */
	public class GPUECO extends proto_Device
	{
		
		public var buffer:Array;
		public var output:Array;
		public var glowoutput:Array;
		public var spritelayer:BitmapData;
		public var spritelayerclearrect:Rectangle = new Rectangle(16, 16, 256, 176);
		public var layerimages:Array;
		public var glowlayerimages:Array;
		public var fader:BitmapData;
		public const FADE_TIME:uint = 50;
		public var glowing:Array = [];
		public var fadetimeout:uint = FADE_TIME;
		public var refreshcountdown:uint = 0;
		
		//DEALS WITH INVALIDATION
		public var invalidated:Boolean = false;
		public var vinvalidated:Boolean = false;
		public var inv_tiles:Array = [];
		
		public var H_SCAN:uint = 0;
		public var H_FIDELITY:uint = 7;
		public var H_TIMERS:Array = [1, 2, 4, 8, 16, 32, 80, 160];
		public var hblankrects:Array;
		public var hblankspriterects:Array;
		public var hblankoffsets:Array;
		
		public var relations:Array;
		
		//public var bus:Motherboard;

		
		//this contains all the controls.
		public var VRAM:ByteArray;
		
		public var spriteindex:Array;
		public const FLIP_NONE:uint = 	parseInt("000", 2);
		public const FLIP_V:uint = 		parseInt("001", 2);
		public const FLIP_H:uint = 		parseInt("010", 2);
		public const FLIP_HV:uint = 	parseInt("011", 2);
		public const FLIP_NONE32:uint = parseInt("100", 2);
		public const FLIP_V32:uint = 	parseInt("101", 2);
		public const FLIP_H32:uint = 	parseInt("110", 2);
		public const FLIP_HV32:uint =	parseInt("111", 2);
		
		
		//this section is for internal management of sprite and tiles
		public var spriteoffsets:Array;
		public var spritesheet:BitmapData;
		public var palettes:Array; //first 32 = nontransparent, next 32 = transparent
		public var glowpalettes:Array; 
		
		public const OS_SPRITE:uint = 0x0;
		public const OS_TILE_SPRITE:uint = 0x3000;
		public const OS_SPRITE_END:uint = 0x6000;
		public const OS_PALETTE:uint = 0x6000;
		public const OS_SPRITE_PALETTE:uint = 0x6000;
		public const OS_TILE_PALETTE:uint = 0x6100;
		public const OS_PALETTE_END:uint = 0x6200;
		public const OS_INSTANCE:uint = 0x6200;
		public const OS_TILE:uint = 0x6400;
		public const OS_TILE_END:uint = 0x6A00;
		public const OS_LAYER:uint = 0x6A00;
		public const OS_CONTROL:uint = 0x7300;
		
		public const S_WIDTH:uint = 240;
		public const S_HEIGHT:uint = 160;
		
		//componenent and datatype sizes
		public const spritecount:uint = 256;
		public const spritesize:uint = 96;
		public const spriteblocksize:uint = 6; //one sprite block = sprite width in bytes * sprite depth, eg 2bytes wide x 3bytes deep of colour
		public const palettecount:uint = 32;
		public const palettesize:uint = 16;
		public const layercount:uint = 4;
		public const layersize:uint = 4;
		public const instancecount:uint = 64;
		public const instancesize:uint = 4;
		public const tilecount:uint = 1024;
		public const tilesperlayer:uint = 256;
		public const tilesize:uint = 2;
		public var tileoffsets:Array;

		//control register offsets - offset from OS_CONTROL
		public const CRA_READFROM:uint = 0;
		public const CRA_WRITETO:uint = 4;
		public const CRA_LENGTH:uint = 8;
		public const CRA_DMACONTROL:uint = 12;
		public const CRA_INTERRUPTS:uint = 16;
		public const CRA_DMA_IRQ:uint = 20;
		public const CRA_VBLANK_IRQ:uint = 24;
		public const CRA_HBLANK_IRQ:uint = 28;
		public const CRA_MODE_IRQ:uint = 32;
		public const CRA_HBLANK_FIDELITY:uint = 36;
		public const CONTROL_REGISTERS_LENGTH:uint = 40;
		
		//tile control details
		public const TA_OPTIONS:uint = 0; 
		public const TM_OPTIONS_ROTV:uint = 	parseInt("10000000", 2);
		public const TM_OPTIONS_ROTH:uint = 	parseInt("01000000", 2);
		public const TM_OPTIONS_ROT:uint =  	parseInt("11000000", 2);
		public const TM_OPTIONS_TRANS:uint = 	parseInt("00100000", 2);
		public const TM_OPTIONS_PALETTE:uint = 	parseInt("00011111", 2);
		public const TA_IMAGE:uint = 1;
		public const TM_IMAGE_ADDR:uint = 		parseInt("01111111", 2);
		public const TM_IMAGE_ONOFF:uint = 		parseInt("10000000", 2);
		
		
		
		//layer control details
		public const LA_OPTIONS:uint = 0;
		public const LA_TRANS:uint = 1;
		public const LA_XOFFSET:uint = 2;
		public const LA_YOFFSET:uint = 3;
		public const LAYER_SIZE:uint = 4;
		public const LM_OPTIONS_ONOFF:uint = 		parseInt("00000001", 2);
		public const LM_OPTIONS_TILESWITCH:uint =	parseInt("00100000", 2);
		public const LM_OPTIONS_BLENDMODE:uint = 	parseInt("00011110", 2);
		public const LAYER_OPTIONS_LENGTH:uint = 16;
		public const OS_TILE0:uint = OS_LAYER;
		public const OS_SPRITELAYER:uint = OS_LAYER + layersize;
		public const OS_TILE1:uint = OS_LAYER + layersize * 2;
		public const OS_WINDOW:uint = OS_LAYER + layersize * 3;
		
		//instance control details
		public const IA_OPTIONS:uint = 0;
		public const IA_IMAGE:uint = 1;
		public const IA_X:uint = 2;
		public const IA_Y:uint = 3;
		public const IM_OPTIONS_PALETTE:uint = parseInt("00001111", 2);
		public const IM_OPTIONS_TRANS:uint =   parseInt("10000000", 2);
		public const IM_OPTIONS_ROTATE:uint =  parseInt("00110000", 2);
		public const IM_OPTIONS_ROTATE32:uint =parseInt("01110000", 2);
		public const IM_OPTIONS_DOUBLE:uint =  parseInt("01000000", 2);
		public const IMO_PALETTE:uint = 0;
		public const IMO_ROTATE:uint = 4;
		public const IMO_TRANS:uint = 6;
		public const IMO_DOUBLE:uint = 5;
		
		//sprite control details
		public const SA_TILESTART:uint = parseInt("0101100000000000", 2);
		
		
		//
		
		//private var IRQ_DMA_COMPLETE:uint = CTRL_IPR7;
		//private var IRQ_VBLANK:uint = CTRL_IPR5;
		
		public function GPUECO(location:uint = 0x0, bus:proto_Motherboard = null) 
		{
			super(location, bus);
			this.buffer = [new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0)];
						   
			this.output = [new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0)];
						   
			this.glowoutput = [new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0),
						   new BitmapData(S_WIDTH, S_HEIGHT, true, 0)];
			
			this.glowing = [false, false, false, false];
			this.fader  = new BitmapData(S_WIDTH, S_HEIGHT, true, 0xF5000000);
			this.VRAM = new ByteArray();
			VRAM.length = 0x73FF;
			this.size = 0x73FF;
			this.spriteindex = [new BitmapData(16, 4096, true, 0),
								new BitmapData(16, 4096, true, 0),
								new BitmapData(16, 4096, true, 0),
								new BitmapData(16, 4096, true, 0)];
								
			
			this.spritelayer = new BitmapData(256, 176, true, 0);
			this.layerimages = [new BitmapData(256, 256, true, 0), spritelayer, new BitmapData(256, 256, true, 0), new BitmapData(240, 160, true, 0)];
			this.glowlayerimages = [];
			var i:uint = 0;
			while (i < layercount) {
				glowlayerimages[i] = new BitmapData(256, 256, true, 0);
				i++;
			}
			i = 0;
			spriteoffsets = [[],[],[],[],[],[],[],[]];
			while (i < spritecount) {
				spriteoffsets[FLIP_NONE][i] = 	new Rectangle(0, 16 * i, 16, 16);
				spriteoffsets[FLIP_V][i] = 		new Rectangle(0, 4096 - 16 * (i+1), 16, 16);
				spriteoffsets[FLIP_H][i] = 		new Rectangle(0, 16 * i, 16, 16);
				spriteoffsets[FLIP_HV][i] = 	new Rectangle(0, 4096 - 16 * (i+1), 16, 16);
		
				spriteoffsets[FLIP_NONE32][i] = 	new Rectangle(0, 16 * (i-i%2), 16, 32);
				spriteoffsets[FLIP_V32][i] = 		new Rectangle(0, 4096 - 16 * ((i-i%2)+2), 16, 32);
				spriteoffsets[FLIP_H32][i] = 		new Rectangle(0, 16 * (i-i%2), 16, 32);
				spriteoffsets[FLIP_HV32][i] = 		new Rectangle(0, 4096 - 16 * ((i-i%2)+2), 16, 32);
				i++;
			}
			tileoffsets = [];
			i = 0;
			while (i < tilesperlayer) {
				tileoffsets[i] = new Point((i % 16) * 16, Math.floor(i / 16) * 16);
				i++;
			}
			
			this.palettes = [];
			this.glowpalettes = [];
			i = 0;
			var j:uint = 0;
			while (i < palettecount * 2) {
				j = 0;
				palettes[i] = [];
				glowpalettes[i] = [[0],[]];
				while (j < 256) {
					palettes[i][j] = 0x0;
					glowpalettes[i][1][j] = 0x0;
					j++;
				}
				i++;
			}
			this.hblankoffsets = [];
			this.hblankrects = [];
			this.hblankspriterects = [];
			i = 0;
			while(i<6){
				j = 0;
				hblankoffsets[i] = [];
				hblankrects[i] = [];
				hblankspriterects[i] = [];
				//trace(i, 6);
				while (j < S_HEIGHT) {
					//trace(j, S_HEIGHT);
					hblankoffsets[i][j] = new Point(0, j);
					hblankrects[i][j] = new Rectangle(0, j, S_WIDTH, 1<<i);
					hblankspriterects[i][j] = new Rectangle(16, j+16, S_WIDTH, 1<<i);
					j += 1<<i;
				}
				i++;
			}
			hblankoffsets[6] = [];
			hblankoffsets[6][0] = new Point(0, 0);
			hblankoffsets[6][80] = new Point(0, 80);
			hblankrects[6] = [];
			hblankrects[6][0] = new Rectangle(0, 0, S_WIDTH, 80);
			hblankrects[6][80] = new Rectangle(0, 80, S_WIDTH, 80);
			hblankoffsets[7] = [new Point(0, 0)];
			hblankrects[7] = [new Rectangle(0, 0, S_WIDTH, 160)];
			
			hblankspriterects[6] = [];
			hblankspriterects[6][0] = new Rectangle(16, 16, S_WIDTH, 80);
			hblankspriterects[6][80] = new Rectangle(16, 96, S_WIDTH, 80);
			hblankspriterects[7] = [new Rectangle(16, 16, S_WIDTH, 160)];
			
			writeWord(OS_CONTROL + CRA_DMA_IRQ,    CTRL_IPR7 | CTRL_IEN);
			writeWord(OS_CONTROL + CRA_VBLANK_IRQ, CTRL_IPR5 | CTRL_IEN);
			writeWord(OS_CONTROL + CRA_HBLANK_IRQ, CTRL_IPR4);
			write(OS_CONTROL + CRA_HBLANK_FIDELITY, 7);
		}
		
		override public function write(to:uint, value:uint):void {
			VRAM[to] = value;
			invalidated = true;
			vinvalidated = true;
			//trace(to.toString(16), value);
			if (to > OS_TILE_END) {
				return;
			}
			parseSpriteData(to);
			parsePaletteData(to);
			parseTileData(to);
		}
		
		override public function writeHalf(to:uint, value:uint):void {
			VRAM[to] = (value >> 8) & 0xFF;
			VRAM[to + 1] = value & 0xFF;
			invalidated = true;
			if (to + 1 > OS_TILE_END) {
				return;
			}
			parseSpriteData(to, 2);
			parsePaletteData(to, 2);
			parseTileData(to, 2);
		}
		
		override public function writeWord(to:uint, value:uint):void {
			VRAM[to] 	 = (value >> 24) & 0xFF;
			VRAM[to + 1] = (value >> 16) & 0xFF;
			VRAM[to + 2] = (value >> 8) & 0xFF;
			VRAM[to + 3] = value & 0xFF;
			invalidated = true;
			vinvalidated = true;
			if (to + 3 > OS_TILE_END) {
				return;
			}
			parseSpriteData(to, 4);
			parsePaletteData(to, 4);
			parseTileData(to, 4);
		}
		
		public function DMAtransfer():void {
			if (!readWord(OS_CONTROL + CRA_DMACONTROL)) {
				return;
			}
			
			var from:uint = readWord(OS_CONTROL + CRA_READFROM);
			var length:uint = readWord(OS_CONTROL + CRA_LENGTH);
			var to:uint = readWord(OS_CONTROL + CRA_WRITETO);
			//trace("DMA Write initiated: From 0x"+ from.toString(16)+" to(0x1)"+to.toString(16)+" length 0x"+length.toString(16));
			//Console.out("DMA Write initiated: From 0x"+ from.toString(16)+" to(0x1)"+to.toString(16)+" length 0x"+length.toString(16));
			var i:uint = 0;
			while (i < length) {
				VRAM[to + i] = bus.readByte(from + i);
				i++;
			}
			//trace(dump(0x7310, 0x7300, 4));
			parseSpriteData(to, length);
			parsePaletteData(to, length);
			parseTileData(to, length); 
			//trace(readWord(OS_CONTROL + CRA_CONTROL) & ~0x1);
			//dump(to + length, to);
			writeWord(OS_CONTROL + CRA_DMACONTROL, 0);
			IRQ(readWord(OS_CONTROL + CRA_DMA_IRQ));
			invalidated = true;
			vinvalidated = true;
			//trace(VRAMdump(to + length, to));
		}
		
		
		public function parseTileData(start:uint, length:uint = 1):void {
			if (start >= OS_TILE_END || start+length < OS_TILE) {
				//drawInvalidTiles();
				return;
			}
			if (start + length >= OS_TILE_END) {
				length = OS_TILE_END - start;
			}
			if (start < OS_TILE) {
				length -= OS_TILE - start;
				start = OS_TILE;
			}
			start -= OS_TILE;
			var align:uint = start % tilesize;
			start -= align;
			length += align;
			align = length % tilesize;
			if (align) {
				length += tilesize - align;
			}
			var i:uint = 0;
			while (i < length) {
				inv_tiles.push((start + i)/ 2);
				i += 2;
			}
		}
		
		public function parsePaletteData(start:uint, length:uint = 1):void {
			if (start >= OS_PALETTE_END || start+length < OS_PALETTE) {
				return;
			}
			if (start + length >= OS_PALETTE_END) {
				length = OS_PALETTE_END - start;
			}
			if (start < OS_PALETTE) {
				length -= OS_PALETTE - start;
				start = OS_PALETTE;
			}
			start -= OS_PALETTE;
			var align:uint = start % palettesize;
			start -= align;
			length += align;
			align = length % palettesize;
			if (align) {
				length += palettesize - align;
			}
			var touched:Array = [];
			var i:uint = 0;
			var c:uint = 0;
			var cur:uint = 0; 
			while (i < length) {
				cur = Math.floor((start + i) / palettesize);
				if (cur >= palettecount / 2 && touched[touched.length - 1] != cur) {
					//trace("Hit palette #" + cur);
					touched.push(cur);
				}
				c = (VRAM[OS_PALETTE + cur * palettesize + (i%palettesize)] << 8) | VRAM[OS_PALETTE + cur * palettesize + (i%palettesize) + 1];
				palettes[cur][Math.floor(i / 2)%8] 					= 0xFF000000 | (((c << 9) & 0xF80000) | ((c << 6) & 0xF800) | ((c << 3) & 0xF8));
				palettes[cur + palettecount][Math.floor(i / 2)%8]	= 0xFF000000 | (((c << 9) & 0xF80000) | ((c << 6) & 0xF800) | ((c << 3) & 0xF8));
				i += 2;
			}
			i = 0;
			while (i < palettecount) {
				palettes[i + palettecount][0] = 0;
				i++;
			}
			//check if we hurt anything's feelings
			i = 0
			VRAM.position = OS_TILE;
			var ct:uint;
			while (i < tilesperlayer * 3 * 2) {
				ct = VRAM.readUnsignedShort();
				var j:uint = 0;
				//trace(ct.toString(16));
				
				while (j < touched.length) {
					//trace("tile #" + (j / 2) + "img #" + (ct & 0xFF) + " pal #" + ((ct >> 8) & 0x1F) + " vs " + touched[j]);
					if ((ct & 0xFF) && (((ct >> 8) & 0x1F) == (touched[j]-16))) {
						//trace("hit tile #" + i / 2);
						inv_tiles.push(i/2);
						//trace(inv_tiles);
					}
					j++;
				}
				i += 2
			}
		}
		
		public function parseSpriteData(start:uint, length:uint = 1):void {
			//Console.out("Parsing sprite data","Start: ", start, "length: ", length);
			if (start >= OS_SPRITE_END || start + length < OS_SPRITE) {
				return;
			}
			if (start + length >= OS_SPRITE_END) {
				length = OS_SPRITE_END - start;
			}
			if (start < OS_SPRITE) {
				length -= OS_SPRITE - start;
				start = OS_SPRITE;
			}
			start -= OS_SPRITE;
			var align:uint = start % spriteblocksize;
			start -= align;
			length += align;
			align = length % spriteblocksize;
			if (align) {
				length += spriteblocksize - align;
			}
			//trace("Parsing sprite data","Start: ", start, "length: ", length);
			var a:uint = 0;
			var b:uint = 0;
			var c:uint = 0;
			var i:uint = 0;
			var x:uint = 0;
			var y:uint = 0;
			var j:int = 0;
			var cs:uint = 0;
			var touched:Array = [];
			while (i < length) {
				
				a = VRAM[start + i];
				b = VRAM[start + i + 2];
				c = VRAM[start + i + 4];
				cs = Math.floor((start + i) / spritesize);
				x = (i % 2) * 8; //determines whether we're in the left or right column
				y = cs * 16 + Math.floor(((start + i) % spritesize) / spriteblocksize);
				j = 7;
				if (cs > 128 && touched[touched.length - 1] != cs) {
					touched.push(cs);
				}
				var col:uint;
				while (j >= 0) {
					col = ((((a >> j) & 0x1) << 2) | (((b >> j) & 0x1) << 1) | ((c >> j) & 0x1)) << 24;
					//trace(cs, ":", x + 7 - j, 4095 - y, 		((((a >> j) & 0x1) << 2) | (((b >> j) & 0x1) << 1) | ((c >> j) & 0x1)) << 24);
					spriteindex[FLIP_NONE].setPixel32(x + 7 - j, y, col);
					spriteindex[FLIP_H	 ].setPixel32(16 - x - 8 + j, y, col);
					spriteindex[FLIP_V	 ].setPixel32(x + 7 - j, 4095-y, col);
					spriteindex[FLIP_HV	 ].setPixel32(16 - x - 8 + j, 4095-y, col);
					//trace(cs, spriteindex[FLIP_HV	 ], ":", 4096 - x - 8 + j, 4095-y, 		((((a >> j) & 0x1) << 2) | (((b >> j) & 0x1) << 1) | ((c >> j) & 0x1)) << 24);
					//trace("check:", FLIP_HV, spriteindex[FLIP_HV	 ].getPixel32(4096 - x - 8 + j, 4095-y));
					//trace("cs: "+(cs-128)+", x:"+(x + 7 - j)+", y:" +y+", a: "+uint((a>>j)&0x1).toString(2)+",b: "+uint((b>>j)&0x1).toString(2)+",c: "+uint((c>>j)&0x1).toString(2)+",value: "+uint(((((a >> (j-2))&0x1)<<2) | (((b >> j)&0x1)<<1) | ((c >> j)&0x1)) << 24).toString(16));
					j--;
				}
				//trace("i:",i,"a:", a,"b:", b,"c:", c,"cs:", cs,"x:", x,"y:", y,"j:", j);
				
				if(i%2){        //because sprites are aligned like
					i += 5;     //|0 1|
				}               //|2 3|
				else {          //|4 5| etc, we need to jump by 1 to get to the next 
					i++;        //      row, or 5 to get to the next block.
				}
				
				
			}	
			
			//check if we hurt anything's feelings
			i = 0
			VRAM.position = OS_TILE;
			var ct:uint;
			while (i < tilesperlayer * 3 * 2) {
				ct = VRAM.readUnsignedShort();
				j = 0;
				while (j < touched.length) {
					if ((ct&0xFF) == touched[j]) {
						inv_tiles.push(touched[j]);
					}
					j++;
				}
				i += 2
			}
			
			/*i = 128;
			while (i < 256) {
				var o:String = "Tile#" + (i - 128) + ": ";
				y = 0;
				while (y < 16) {
					x = 0;
					o = o + "\n";
					while (x < 16) {
						o = o + (BitmapData(spriteindex[0]).getPixel32(x + i * 16, y) >> 24) + " ";
						x++;
					}
					y++;
				}
				trace(o);
				i++;
			}*/
		}
		
		
		
		//TODO: MAINTAIN AN ARRAY OF PLACES THAT HAVE BEEN WRITTEN OR DMA'D TO,
		//		AND ONLY UPDATE THOSE AREAS. THIS WILL BECOME NECESSARY.
		public function parseMemory():void {
			var i:uint = 0;
			var j:uint = 0;
			var k:uint = 0;
			var sr:Rectangle = new Rectangle(0, 0, S_WIDTH, S_HEIGHT);
			//trace(dump(0x7330, 0x7300));
			//trace("Status of 0x" + (OS_CONTROL + CRA_CONTROL).toString(16) + ": 0x" + readWord(OS_CONTROL + CRA_CONTROL).toString(16));
			
						
			//var cur_layer_options:uint = 0;
			
			/*i = 0;
			while (i < spritelayerimages.length) {
				spritelayerimages[i].fillRect(sr, 0);
				if(glowing[i]){
					glowlayerimages[i].fillRect(sr, 0);
					glowing[i] = false;
				}
				
				i++;
			}*/
			if (inv_tiles.length) {
				vinvalidated = true;
				drawInvalidTiles();
			}
			//DRAW SPRITES
			spritelayer.fillRect(spritelayerclearrect, 0);
			i = 0;
			var position:uint = OS_INSTANCE;
			var dpoint:Point = new Point();
			while (i < instancecount) {
				dpoint.x = VRAM[position + IA_X]
				dpoint.y = VRAM[position + IA_Y];
				if (dpoint.x && dpoint.y) { //we only draw sprites that are visible obv
					var options:uint = VRAM[position+IA_OPTIONS];
					var cpalette:Array = palettes[(options & IM_OPTIONS_PALETTE) + 32 * ((options & IM_OPTIONS_TRANS)?1:0)];
					var rotation:uint = (options & IM_OPTIONS_ROTATE) >> IMO_ROTATE;
					var csoffset:Rectangle = spriteoffsets[(options&IM_OPTIONS_ROTATE32)>>IMO_ROTATE][VRAM[position+IA_IMAGE]];
					/*k = 0;
					while (k < 16 * 16) {
						trace(rotation, spriteindex[rotation], k % 16, uint(k / 16) + csoffset.y, ":", BitmapData(spriteindex[rotation]).getPixel32(k % 16, uint(k / 16) + csoffset.y));
						k++;
					}*/
					//trace(options.toString(2), csoffset);
					spritelayer.paletteMap(spriteindex[rotation], csoffset, dpoint, null, null, null, cpalette);
				}
				position += instancesize;
				i++;
			}	
		}
		
		private function drawInvalidTiles():void {
			inv_tiles.sort(Array.NUMERIC);
			var i:uint;
			var prev:uint = uint.MAX_VALUE;
			var cur:uint = 0;
			var ct:uint;
			var ch:uint;
			var cl:uint;
			var rect:Rectangle = new Rectangle(0, 0, 16, 16);
			while (cur < inv_tiles.length) {
				if (inv_tiles[cur] != prev) {
					prev = ct = inv_tiles[cur];
					ch = VRAM[OS_TILE+prev*2];
					cl = VRAM[OS_TILE + prev * 2 + 1];
					//trace("Drawing invalid tile: " + prev + " new index: "+cl.toString(16));
					var lo:uint = prev % 256;
					rect.x = tileoffsets[lo].x;
					rect.y = tileoffsets[lo].y;
					if(cl){	
						if (ct < 256) {
							BitmapData(layerimages[0]).fillRect(rect, 0);
							BitmapData(layerimages[0]).paletteMap(spriteindex[(ch & TM_OPTIONS_ROT) >> 6], spriteoffsets[(ch & TM_OPTIONS_ROT) >> 6][cl], tileoffsets[lo], null, null, null, palettes[(0x10|( ch & TM_OPTIONS_PALETTE))]);
						}
						else if (ct < 512) {
							//draw layer 1
							BitmapData(layerimages[2]).fillRect(rect, 0);
							BitmapData(layerimages[2]).paletteMap(spriteindex[(ch & TM_OPTIONS_ROT) >> 6], spriteoffsets[(ch & TM_OPTIONS_ROT) >> 6][cl], tileoffsets[lo], null, null, null, palettes[(0x10|( ch & TM_OPTIONS_PALETTE)) + 32 * ((ch & TM_OPTIONS_TRANS)?1:0)]);
						}
						else if (ct < 672) { //we only draw to 672 since the Window is unscrollable and everything below row 16 will never be seen.
							//draw window
							BitmapData(layerimages[3]).fillRect(rect, 0);
							BitmapData(layerimages[3]).paletteMap(spriteindex[(ch & TM_OPTIONS_ROT) >> 6], spriteoffsets[(ch & TM_OPTIONS_ROT) >> 6][cl], tileoffsets[i], null, null, null, palettes[(0x10|( ch & TM_OPTIONS_PALETTE)) + 32 * ((ch & TM_OPTIONS_TRANS)?1:0)]);
						}
					}
				}
				
				cur++;
			}
			inv_tiles = [];
		}
		
		
		
		override public function read(from:uint):uint {
			if (from > size) {
				trace("VRAM read attempted from nonexistent address: 0x" + from.toString(16));
				return 0;
			}
			return VRAM[from];
		}
		
		public function HorizontalBlank():void {
			H_FIDELITY = read(OS_CONTROL + CRA_HBLANK_FIDELITY);
			if (H_SCAN % H_TIMERS[H_FIDELITY]) {
				H_SCAN++;
				return;
			}
			IRQ(readWord(OS_CONTROL + CRA_HBLANK_IRQ));
			if (invalidated) {
				parseMemory();
				//trace(H_SCAN);
			}
		
			invalidated = false;
			if (H_SCAN >= S_HEIGHT) {
				H_SCAN = 0;
			}
			var c:BitmapData;
			var o:uint;
			var i:uint;
			var dr:Rectangle;
			c = buffer[0];
			dr = hblankrects[H_FIDELITY][H_SCAN].clone();
			VRAM.position = OS_TILE0 + LA_XOFFSET;
			dr.x += VRAM.readByte();
			dr.y += VRAM.readByte();
			c.copyPixels(layerimages[0], dr, hblankoffsets[H_FIDELITY][H_SCAN]);
			
			if (VRAM[OS_SPRITELAYER] & LM_OPTIONS_ONOFF) {
				c = buffer[1];
				c.copyPixels(layerimages[1], hblankspriterects[H_FIDELITY][H_SCAN], hblankoffsets[H_FIDELITY][H_SCAN]);
			}
			if (VRAM[OS_TILE1] & LM_OPTIONS_ONOFF) {
				c = buffer[2];
				dr = hblankrects[H_FIDELITY][H_SCAN].clone();
				VRAM.position = OS_TILE1 + LA_XOFFSET;
				dr.x += VRAM.readByte();
				dr.y += VRAM.readByte();
				c.copyPixels(layerimages[2], dr, hblankoffsets[H_FIDELITY][H_SCAN]);
			}
			
			if (VRAM[OS_WINDOW] & LM_OPTIONS_ONOFF) {
				c = buffer[3];
				c.copyPixels(layerimages[3], hblankrects[H_FIDELITY][H_SCAN], hblankoffsets[H_FIDELITY][H_SCAN]);
			}
			H_SCAN++;
		}
		
		
		override public function refresh(e:Event = null):void {
			IRQ(readWord(OS_CONTROL + CRA_VBLANK_IRQ));
			//trace("Blanking: " + vinvalidated.toString());
			if (!vinvalidated) {
				return;
			}
			//trace("Blanking!");
			//trace(VRAMdump());
			vinvalidated = false;
			
			/*var temp:Array = output;
			output = buffer;
			buffer = temp;*/
			
			var sr:Rectangle = new Rectangle(0, 0, S_WIDTH, S_HEIGHT);
			var i:uint = 0;
			//TODO: INVESTIGATE IF SWAPPING THE SCREENS BETWEEN ARRAYS WOULD WORK/BE FASTER!
			while (i < output.length) {
				BitmapData(output[i]).fillRect(sr, 0);
				BitmapData(output[i]).copyPixels(buffer[i], sr, new Point());
				BitmapData(buffer[i]).fillRect(sr, 0x000000);
				i++;
			}		
		}
		
		public function VRAMdump(to:int = -1, from:int = 0, perline:uint=0x10 ):String {
			var out:String = "";
			var i:uint = from;
	
			if (to == -1) {
				trace("Did blind dumping crash the VM? That's because I never tested it! Hahahahah. Check proto_Device.dump() for more funtimes!");
				to = this.size;
			}
			while (i < to) {
				if (!(i % perline)) {
					out = out+"\n[0x" + StringManip.pad(i.toString(16), "0", 4) + "] ";
				}
				out = out + StringManip.pad(uint(read(i)).toString(16), "0", 2) + " ";
				i++;
			}
			return out;
		}
		
		public function reset():void {
			VRAM.clear();
			VRAM.length = this.size;
			palettes = [];
			glowpalettes = [];
			var i:uint = 0;
			var j:uint = 0;
			while (i < palettecount * 2) {
				j = 0;
				palettes[i] = [];
				glowpalettes[i] = [[0],[]];
				while (j < 256) {
					palettes[i][j] = 0x0;
					glowpalettes[i][1][j] = 0x0;
					j++;
				}
				i++;
			}
			i = 0;
			while (i < buffer.length) {
				BitmapData(buffer[i]).fillRect(buffer[i].rect, 0);
				i++;
			}
			
			i = 0;
			while (i < output.length) {
				BitmapData(output[i]).fillRect(output[i].rect, 0);
				i++;
			}
			spritelayer.fillRect(spritelayer.rect, 0);
			i = 0;
			while (i < spriteindex.length) {
				BitmapData(spriteindex[i]).fillRect(spriteindex[i].rect, 0);
				i++;
			}
			
		}
	}

}