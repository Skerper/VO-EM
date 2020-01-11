package 
{
	import adobe.utils.CustomActions;
	import com.gui.Button;
	import com.input.KeyCodes;
	import com.input.TextInput;
	import com.math.GW_Math;
	import com.memory.StringManip;
	import com.visual.BitmapDrawing;
	import com.visual.TileScape;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.text.engine.FontDescription;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class Main extends Sprite 
	{
		
		//tool mode consts
		private const T_SCROLL:uint = 0;   //scroll the map by click/dragging
		private const T_SELECT:uint = 1;  //select a tile
		private const T_ERASE:uint = 2;  //delete a tile
		private const T_FLOOD:uint = 8; //flood fill yo
		private const T_DRAG:uint = 3; //drag a tile
		private const T_SELECT_SQUARE:uint = 4; //activated when holding shift after clicking on one tile to select a square
		private const T_SELECT_MULT:uint = 5; //ctrl+click to select multiple individual tiles
		private const T_PLACE:uint = 6;
		private const T_COMBINE:uint = 7; //next clicked same-type tile or palette will be merged
		private const T_SWAPPER:uint = 8;
		private const T_PENCIL:uint = 9
		private const MISSING_SPRITE:Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
											1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
											2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
											3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
											4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
											5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
											6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 
											7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
											0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
											1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
											2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
											3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
											4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
											5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
											6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 
											7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7]
											
		private const MISSING_PALETTE:Array	= [0x0, 0x7C00, 0x3C0, 0x1F, 0x7FE0, 0x7C1F, 0x3FF, 0x7FFF];
		private const MISSING_TILE:Array = [];
		
		
		//hotkeys
		private const HK_HFLIP:uint = KeyCodes.H;
		private const HK_VFLIP:uint = KeyCodes.V;
		private const HK_TRANS:uint = KeyCodes.T;
		private const HK_DESEL:uint = KeyCodes.Q;
		
		//data offsets
		private const D_PALETTE:uint = 0;
		private const D_TRANS:uint = 1;
		private const D_IMAGE:uint = 2;
		private const M_TILE:uint = 2;
		private const M_TRANS:uint = 1;
		private const M_PALETTE:uint = 0;
		private const M_HFLIP:uint = 3;
		private const M_VFLIP:uint = 4;
		
		//states
		private const S_MAP_EDIT:uint = 0;
		private const S_TILE_EDIT:uint = 1;
		private const S_PALETTE_EDIT:uint = 2;
		
		//buttons
		//mode selection group
		private var b_scroll:Button;
		private var b_select:Button;
		private var b_erase:Button;
		private var b_place:Button;
		private var b_flood:Button;
		private var t_mode_divider:TextField = new TextField()
		private var b_pencil:Button;
		private var b_swapper:Button;
		//file management
		private var b_load_tile_map:Button;
		private var b_load_tile_sprites:Button;
		private var b_save_tile_sprites:Button;
		private var b_save_tile_map:Button;
		private var b_load_palette_data:Button;
		private var b_save_palette_data:Button;
		private var b_export_asm:Button;
		//layer selection
		private var b_layer0:Button;
		private var b_layer1:Button;
		private var b_layer2:Button;
		private var b_layer0_toggle:Button;
		private var b_layer1_toggle:Button;
		private var b_layer2_toggle:Button;
		//middle box tools
		private var b_combine:Button;
		private var b_delete:Button;
		private var b_newpal:Button;
		private var b_newtile:Button;
		//palette editor/tile palette order editor
		private var b_pedit_apply:Button;
		
		//highlighter
		private var layer_highlight:Sprite;
		private var layer0_toggle_highlight:Sprite;
		private var layer1_toggle_highlight:Sprite;
		private var layer2_toggle_highlight:Sprite;
		private var hl_label:TextField;
		
		//gui images
		private var i_tile_list:BitmapData = new BitmapData(2048, 16, true, 0);
		private var i_tile_list_window:BitmapData = new BitmapData(399, 16, true, 0);
		private var i_palette_list:BitmapData = new BitmapData(80, 4096, true, 0);
		private var i_palette_list_window:BitmapData = new BitmapData(78, 348, true, 0);
		private var i_world_map:Array = [new BitmapData(4080, 4080, true, 0),
										 new BitmapData(4080, 4080, true, 0),
										 new BitmapData(4080, 4080, true, 0)];
		private var i_world_map_window:BitmapData = new BitmapData(512, 350, true, 0);
		private var i_palette_order:BitmapData = new BitmapData(128, 16, true, 0);
		private var i_sprite_editor:BitmapData = new BitmapData(16 * 8, 16 * 8, true, 0);
		private var i_picker:BitmapData = new BitmapData(256, 128, false, 0);
		
		//gui elements
		private var tilelist:Sprite;
		private var palettelist:Sprite;
		private var worldmap:Sprite;
		private var paletteedit:Sprite;
		private var tileedit:Sprite;
		private var worldmap_highlight:Graphics;
		private var hl:Graphics;
		private var tool_highlighter:Sprite = new Sprite();
		private var info:TextField = new TextField();
		private var colorpicker:Sprite;
		
		//gui variables
		private var tileScroll:Number = 0;
		private var paletteScroll:Number = 0;
		private var mapScrollX:Number = 0;
		private var mapScrollY:Number = 0;
		private var dragging_palette:Boolean = false;
		private var dragging_tiles:Boolean = false;
		private var dragging_map:Boolean = false;
		private var mouse_moved:Boolean = false;
		private var mousedownpoint:Point = new Point();
		private var lastmouse:Point = new Point();
		private var selectiontype:uint = 0;
		private var subselectiontype:uint = 0;
		private var selected:Array = [];
		private var toolmode:uint = T_SELECT;
		private var hflipped:Boolean = false;
		private var vflipped:Boolean = false;
		private var transtoggle:Boolean = false;
		private var map_visible:Array = [true, false, false];
		private var current_map:uint = 0;
		private var related:Array;
		private var free_drawing:Boolean = false;
		
		//gui constants
		private const SELECT_NONE:uint = 0;
		private const SELECT_TILE:uint = 1;
		private const SELECT_PALETTE:uint = 2;
		private const SELECT_WORLD_SQUARE:uint = 3;
		private const SUB_SELECT_NONE:uint = 0;
		private const SUB_SELECT_P_EDIT:uint = 1;
		private const SUB_SELECT_T_EDIT:uint = 2;
		
		//data management
		private var rawTilesImage:BitmapData;
		private var data:Array = [];
		private var palettes:Array = [];
		private var map:Array = [[], [], []];
		private var undo:Array = [];
		private var undo_pos:uint = 0;
		
		//IO stuff
		private var file:FileReference;
		private var fileLoader:Loader;
		
		
		public function Main():void {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			MISSING_TILE[M_HFLIP] = false;
			MISSING_TILE[M_VFLIP] = false;
			MISSING_TILE[M_TILE] = MISSING_SPRITE;
			MISSING_TILE[M_PALETTE] = MISSING_PALETTE;
			MISSING_TILE[M_TRANS] = false;
			
			// build GUI:
			var g:Graphics = this.graphics;
			g.beginFill(0x333344);
			g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			g.endFill();
			g.lineStyle(1, 0xFFFFFF);
			//top toolbar
			g.drawRect(0, 0, 799, 34);
			b_load_tile_sprites = new Button("Load Sprites", 4, 4, 65);
			b_save_tile_sprites = new Button("Save Sprites", 71, 4, 65);
			b_load_tile_map	= new Button("Load Map", 138, 4, 65);
			b_save_tile_map = new Button("Save Map", 204, 4, 65);
			b_load_palette_data = new Button("Load Palettes", 271, 4, 65);
			b_save_palette_data = new Button("Save Palettes", 338, 4, 65);
			b_export_asm = new Button("Export", 405, 4);
			addChild(b_load_tile_sprites);
			addChild(b_save_tile_sprites);
			addChild(b_load_tile_map);
			addChild(b_save_tile_map);
			addChild(b_load_palette_data);
			addChild(b_save_palette_data);
			addChild(b_export_asm);
			b_save_tile_map.addEventListener(MouseEvent.CLICK, e_save_map);
			b_save_tile_sprites.addEventListener(MouseEvent.CLICK, e_save_sprites);
			b_export_asm.addEventListener(MouseEvent.CLICK, e_export_asm);
			b_load_palette_data.addEventListener(MouseEvent.CLICK, e_load_palette);
			b_save_palette_data.addEventListener(MouseEvent.CLICK, e_save_palette);
			addChild(info);
			info.x = b_export_asm.x + b_export_asm.width + 5;
			info.textColor = 0xFFFFFF;
			info.width = stage.width - info.x;
			info.text = "Ready to start!";
			info.selectable = false;
			info.y = 6;
			//left toolbar
			g.drawRect(0, 40, 50, 350);
			var t1:TextField = new TextField();
			t1.text = "Tools";
			t1.x = 10;
			t1.y = 41;
			t1.textColor = 0xFFFFFF;
			this.addChild(t1);
			b_select = new Button("Select", 5, 60, 40);
			b_scroll = new Button("Scroll", 5, 90, 40);
			b_erase = new Button("Erase", 5, 120, 40);
			b_place = new Button("Place", 5, 150, 40);
			b_flood = new Button("Flood", 5, 180, 40);
			t_mode_divider.text = "--------\nSprite";
			t_mode_divider.textColor = 0xFFFFFF;
			b_pencil = new Button("Pencil", 5, 240, 40);
			b_swapper = new Button("Swap", 5, 270, 40);
			addChild(b_select);
			addChild(b_scroll);
			addChild(b_erase);
			addChild(b_place);
			addChild(t_mode_divider);
			addChild(b_pencil);
			addChild(b_swapper);
			t_mode_divider.x = 5;
			t_mode_divider.y = 200;
			
			//addChild(b_flood);
			b_select.addEventListener(MouseEvent.CLICK, b_select_handler);
			b_scroll.addEventListener(MouseEvent.CLICK, b_scroll_handler);
			b_erase.addEventListener(MouseEvent.CLICK, b_erase_handler);
			b_place.addEventListener(MouseEvent.CLICK, b_place_handler);
			b_pencil.addEventListener(MouseEvent.CLICK, b_pencil_handler);
			b_swapper.addEventListener(MouseEvent.CLICK, b_swapper_handler);
			//b_flood.addEventListener(MouseEvent.CLICK, b_flood_handler);
			tool_highlighter.graphics.beginFill(0xFFFFFF, 0.5);
			//tool_highlighter.blendMode = BlendMode.ADD;
			tool_highlighter.graphics.drawRect(0, 0, 40, 25);
			tool_highlighter.graphics.endFill();
			tool_highlighter.x = b_select.x;
			tool_highlighter.y = b_select.y;
			addChild(tool_highlighter);
		
			
			//var mask:Sprite;
			
			//var tg:Sprite = new Sprite();
			//bottom tilebox
			g.drawRect(0, 395, 799, 33);
			tilelist = new Sprite();
			tilelist.addChild(new Bitmap(i_tile_list_window));
			addChild(tilelist);
			//addChild(tg);
			//tile_highlight = tg.graphics;
			tilelist.x = 1;
			tilelist.y = 396;
			tilelist.scaleX = 2;
			tilelist.scaleY = 2;
			tilelist.addEventListener(MouseEvent.MOUSE_DOWN, tiledrag);
			tilelist.addEventListener(MouseEvent.MOUSE_UP, tileselect);
			
			//tg = new Sprite();
			//middle main window
			g.drawRect(55, 40, 512, 350);
			worldmap = new Sprite();
			worldmap.addChild(new Bitmap(i_world_map_window));
			//worldmap.addChild(tg);
			//worldmap_highlight = tg.graphics;
			addChild(worldmap);
			worldmap.x = 55;
			worldmap.y = 40;
			worldmap.addEventListener(MouseEvent.MOUSE_DOWN, mapdrag);
			worldmap.addEventListener(MouseEvent.MOUSE_UP, mapselect);
			
			//layer options
			g.drawRect(577, 40, 133, 92);
			b_layer0 = new Button("Layer 0", 583, 45, 83, 25);
			b_layer1 = new Button("Layer 1", 583, 75, 83, 25); 
			b_layer2 = new Button("Window", 583, 105, 83, 25);
			b_layer0_toggle = new Button("Show", 671, 45, 35);
			b_layer1_toggle = new Button("Show", 671, 75, 35);
			b_layer2_toggle = new Button("Show", 671, 105, 35);
			layer_highlight = new Sprite();
			layer0_toggle_highlight = new Sprite();
			layer1_toggle_highlight = new Sprite();
			layer2_toggle_highlight = new Sprite();
			layer_highlight.graphics.beginFill(0xFFFFFF, 0.5);
			layer_highlight.graphics.drawRect(0, 0, 83, 25);
			layer_highlight.graphics.endFill();
			layer0_toggle_highlight.graphics.beginFill(0xFFFFFF, 0.5);
			layer0_toggle_highlight.graphics.drawRect(0, 0, 35, 25);
			layer0_toggle_highlight.graphics.endFill();
			layer1_toggle_highlight.graphics.beginFill(0xFFFFFF, 0.5);
			layer1_toggle_highlight.graphics.drawRect(0, 0, 35, 25);
			layer1_toggle_highlight.graphics.endFill();
			layer2_toggle_highlight.graphics.beginFill(0xFFFFFF, 0.5);
			layer2_toggle_highlight.graphics.drawRect(0, 0, 35, 25);
			layer2_toggle_highlight.graphics.endFill();
			layer_highlight.x = 583;
			layer_highlight.y = 45;
			layer0_toggle_highlight.x = 671;
			layer0_toggle_highlight.y = 45;
			layer0_toggle_highlight.mouseEnabled = false;
			layer1_toggle_highlight.mouseEnabled = false;
			layer2_toggle_highlight.mouseEnabled = false;
			layer1_toggle_highlight.x = 671;
			layer1_toggle_highlight.y = 75;
			layer1_toggle_highlight.visible = false;
			layer2_toggle_highlight.x = 671;
			layer2_toggle_highlight.y = 105;
			layer2_toggle_highlight.visible = false;
			addChild(b_layer0);
			addChild(b_layer1);
			addChild(b_layer2);
			addChild(b_layer0_toggle);
			addChild(b_layer1_toggle);
			addChild(b_layer2_toggle);
			addChild(layer_highlight);
			addChild(layer0_toggle_highlight);
			addChild(layer1_toggle_highlight);
			addChild(layer2_toggle_highlight);
			
			
			
			b_layer0.addEventListener(MouseEvent.CLICK, b_layer0_handler);
			b_layer1.addEventListener(MouseEvent.CLICK, b_layer1_handler);
			b_layer2.addEventListener(MouseEvent.CLICK, b_layer2_handler);
			b_layer0_toggle.addEventListener(MouseEvent.CLICK, b_layer0_toggle_handler);
			b_layer1_toggle.addEventListener(MouseEvent.CLICK, b_layer1_toggle_handler);
			b_layer2_toggle.addEventListener(MouseEvent.CLICK, b_layer2_toggle_handler);

			//multipurpose box
			b_combine = new Button("Combine", 578, 40+92+5, 65, 22);
			b_delete = new Button("Delete", 645, 40 + 92 + 5, 65, 22);
			b_newpal = new Button("New Palette", 578, 40 + 90 + 10 + 20, 65, 22);
			b_newtile = new Button("New Sprite", 645, 40 + 90 + 10 + 20, 65, 22);
			addChild(b_combine);
			addChild(b_delete);
			addChild(b_newpal);
			addChild(b_newtile);
			b_combine.addEventListener(MouseEvent.CLICK, b_combine_handler);
			b_delete.addEventListener(MouseEvent.CLICK, b_delete_handler);
			b_newpal.addEventListener(MouseEvent.CLICK, b_newpal_handler);
			b_newtile.addEventListener(MouseEvent.CLICK, b_newtile_handler);
			
			//palette/tile order editor
			g.drawRect(577, 185, 133, 205);
			paletteedit = new Sprite();
			addChild(paletteedit);
			paletteedit.addChild(new Bitmap(i_palette_order));
			paletteedit.x = 577 + 2.5;
			paletteedit.y = 185 + 2.5;
			//i_palette_order.fillRect(i_palette_order.rect, 0xFFFF0000);
			paletteedit.addEventListener(MouseEvent.MOUSE_DOWN, peditdrag);
			paletteedit.addEventListener(MouseEvent.MOUSE_UP, peditselect);
			
			tileedit = new Sprite();
			tileedit.addChild(new Bitmap(i_sprite_editor));
			addChild(tileedit);
			tileedit.x = 577 + (133 - 128) / 2;
			tileedit.y = 185 + 30;
			//i_sprite_editor.fillRect(i_sprite_editor.rect, 0xFF00FF00);
			tileedit.addEventListener(MouseEvent.MOUSE_DOWN, teditdrag);
			tileedit.addEventListener(MouseEvent.MOUSE_UP, teditselect);
	
			g.drawRect(paletteedit.x, paletteedit.y, paletteedit.width+1, paletteedit.height+1);
			g.drawRect(tileedit.x, tileedit.y-1, tileedit.width+1, tileedit.height+1);
			
			//tg = new Sprite();
			//palette explorer
			g.drawRect(800 - 80, 40, 79, 350);
			palettelist = new Sprite();
			palettelist.addChild(new Bitmap(i_palette_list_window));
			addChild(palettelist);
			
			//addChild(tg);
			//palette_highlight = tg.graphics;
			palettelist.x = 800 - 79;
			palettelist.y = 41;
			palettelist.addEventListener(MouseEvent.MOUSE_DOWN, palettedrag);
			palettelist.addEventListener(MouseEvent.MOUSE_UP, paletteselect);			
			
			
			//DRAW THINGS ABOVE THIS LINE!!
			var highlighter:Sprite = new Sprite();
			this.addChild(highlighter);
			hl = highlighter.graphics;
			hl_label = new TextField();
			hl_label.textColor = 0xFFFFFF;
			hl_label.selectable = false;
			hl_label.mouseEnabled = false;
			highlighter.mouseEnabled = false;
			this.addChild(hl_label);
			//highlighter.blendMode = BlendMode.ADD
			
			addEventListener(MouseEvent.MOUSE_MOVE, mousemovedhandler);
			addEventListener(MouseEvent.MOUSE_UP, mouseuphandler);
			addEventListener(Event.ENTER_FRAME, frameHandler);
			addEventListener(MouseEvent.MOUSE_DOWN, mousedownhandler);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, hotkeyhandler);
			
			b_load_tile_sprites.addEventListener(MouseEvent.CLICK, e_load_tile_sprites);
			b_load_tile_map.addEventListener(MouseEvent.CLICK, e_load_map);
			
			//This makes something awesome. 
			/*var tbd:BitmapData = new BitmapData(256, 128, false, 0);
			this.addChild(new Bitmap(tbd));
			var m:uint = 0;
			while (m < 32768) {
				tbd.setPixel(m % 256, m / 256, HSLtoRGB(m % 256, m/256, m/128));
				m++;
			}*/
					
			colorpicker = new Sprite();
			colorpicker.visible = false;
			colorpicker.addChild(new Bitmap(i_picker));
			this.addChild(colorpicker);
			colorpicker.addEventListener(MouseEvent.MOUSE_DOWN, colorpickerdrag);
			colorpicker.addEventListener(MouseEvent.MOUSE_UP, colorpickerselect);
			renderColorPicker();
		}
		
		private function HSLtoRGB15bit(h:Number, s:Number, l:Number):uint{
			h = h / 360;
			var r:Number;
			var g:Number;
			var b:Number;
 
			if(l==0)
			{
				r=g=b=0;
			}
			else
			{
				if(s == 0)
				{
					r=g=b=l;
				}
				else
				{
					var t2:Number = (l<=0.5)? l*(1+s):l+s-(l*s);
					var t1:Number = 2*l-t2;
					var t3:Vector.<Number> = new Vector.<Number>();
					t3.push(h+1/3);
					t3.push(h);
					t3.push(h-1/3);
					var clr:Vector.<Number> = new Vector.<Number>();
					clr.push(0);
					clr.push(0);
					clr.push(0);
					for(var i:int=0;i<3;i++)
					{
						if(t3[i]<0)
							t3[i]+=1;
						if(t3[i]>1)
							t3[i]-=1;
 
						if(6*t3[i] < 1)
							clr[i]=t1+(t2-t1)*t3[i]*6;
						else if(2*t3[i]<1)
							clr[i]=t2;
						else if(3*t3[i]<2)
							clr[i]=(t1+(t2-t1)*((2/3)-t3[i])*6);
						else
							clr[i]=t1;
					}
					r=clr[0];
					g=clr[1];
					b=clr[2];
				}
			}
			return ((uint(r*31)&0x1F)<<19)|((uint(g*31)&0x1F)<<11)|((uint(b*31)&0x1F)<<3);
		}
		
		private function HSLtoRGB(h:Number, s:Number, l:Number):uint{
			h = h / 360;
			var r:Number;
			var g:Number;
			var b:Number;
 
			if(l==0)
			{
				r=g=b=0;
			}
			else
			{
				if(s == 0)
				{
					r=g=b=l;
				}
				else
				{
					var t2:Number = (l<=0.5)? l*(1+s):l+s-(l*s);
					var t1:Number = 2*l-t2;
					var t3:Vector.<Number> = new Vector.<Number>();
					t3.push(h+1/3);
					t3.push(h);
					t3.push(h-1/3);
					var clr:Vector.<Number> = new Vector.<Number>();
					clr.push(0);
					clr.push(0);
					clr.push(0);
					for(var i:int=0;i<3;i++)
					{
						if(t3[i]<0)
							t3[i]+=1;
						if(t3[i]>1)
							t3[i]-=1;
 
						if(6*t3[i] < 1)
							clr[i]=t1+(t2-t1)*t3[i]*6;
						else if(2*t3[i]<1)
							clr[i]=t2;
						else if(3*t3[i]<2)
							clr[i]=(t1+(t2-t1)*((2/3)-t3[i])*6);
						else
							clr[i]=t1;
					}
					r=clr[0];
					g=clr[1];
					b=clr[2];
				}
			}
			return (uint(r*255)<<16)|(uint(g*255)<<8)|uint(b*255);
		}
		
		//SPRITE LOADING AND SAVING
		private function e_load_tile_sprites(e:Event = null):void {
			file = new FileReference();
			file.addEventListener(Event.SELECT, e_tile_sprite_selected);
			file.browse([new FileFilter("PNG image (*.png)", "*.png"), new FileFilter("VO-EM sprite archive (*.ves)", "*.ves")]);
		}	
		private function e_tile_sprite_selected(e:Event = null):void {
			file.addEventListener(Event.COMPLETE, e_tile_sprite_loaded);
			file.load();
		}		
		private function e_tile_sprite_loaded(e:Event = null):void {
			
			if (file.type == ".png") {
				info.text = ".png spritesheet loaded.";
				fileLoader = new Loader();
				fileLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_parse_tile_data);
				fileLoader.loadBytes(file.data);
			}
			else if (file.type == ".ves") {
				info.text = ".ves sprite archive loaded.";
				var fileReference:FileReference = e.target as FileReference;
				var spritest:ByteArray = fileReference["data"];
				e_parse_tile_archive(spritest.toString());
			}
			else {
				info.text = "It's actually a " + file.type;
			}
			return;
			
			
		}
		
		private function e_parse_tile_archive(d:String):void {
			addUndoLevel();
			clearSelection();
			data = [];
			var i:uint = 0;
			var dcleaned:String = "";
			while (i < d.length) {
				if (d.charAt(i) != " " && d.charAt(i) != "\n") {
					dcleaned = dcleaned + d.charAt(i);
				}
				i++;
			}
			
			var s:Array = dcleaned.split(".");
			i = 0;
			while (i < s.length) {
				var c:Array = String(s[i]).split(",");
				var j:uint = 0;
				data.push([parseInt(String(c[1]), 10), false,[]]);
				var cd:Array = data[data.length - 1];
				while (j < 16 * 16) {
					cd[D_IMAGE][j] = parseInt(String(c[0]).charAt(j), 10);
					j++;
				}
				i++;
			}
			renderAll();
		}
		
		private const FOOLS_MARGIN:uint = 3; //allowance for spritesheets that are slightly undersized due to cropping errors
		private function e_parse_tile_data(e:Event = null):void {
			addUndoLevel();
			clearSelection();
			rawTilesImage = new BitmapData((fileLoader.width+FOOLS_MARGIN)-((fileLoader.width+FOOLS_MARGIN)%16),(fileLoader.height+FOOLS_MARGIN)-((fileLoader.height+FOOLS_MARGIN)%16), true, 0);
			rawTilesImage.draw(fileLoader);
			
			data = [];
			palettes = [];
			i_tile_list.fillRect(i_tile_list.rect, 0);
			i_palette_list.fillRect(i_palette_list.rect, 0);
			paletteScroll = tileScroll = 0;
			
			//data.push([0, false, []]);
			
			var x:uint = 0;
			var y:uint = 0;
			var w:uint = rawTilesImage.width;
			var h:uint = rawTilesImage.height;
			h /= 16;
			w /= 16;
			
			var cur:BitmapData = new BitmapData(16, 16, true, 0);
			var i:uint;
			var j:uint;
			var k:uint;
			var p:Array; //palette
			var cp:uint;
			var d:Array; //indexed data
			while (y < h) {
				x = 0;
				while (x < w) {
					p = [];
					d = [];
					cur.fillRect(cur.rect, 0);
					cur.copyPixels(rawTilesImage, new Rectangle(x * 16, y * 16, 16, 16), new Point(0, 0));
					i = 0;
					while (i < 16 * 16) {
						cp = cur.getPixel32(i % 16, i / 16);
						j = 0;
						var found:Boolean = false;
						while (j < p.length) {
							if (cp == p[j]) { //search palette for matching color 
								found = true;
								d[i] = j; //if it matches, use that color's index for the data
								break;
							}
							j++;
						}
						if (!found) { //if no match is found, add a new colour to the palette
							if (p.length <= 8) {
								p.push(cp);
								d[i] = p.length-1; //and use its index for the offset
							}
							else {
								d[i] = p.length - 1;
							}
						}
						
						i++;
					}
					
					if (p.length > 8) {
						info.text = "At least one sprite had more than 8 colors. Check for artifacting!";
					}
					//here we compress the palette
					/*while (p.length > 8) {
						trace("Palette #" + palettes.length + " is currently length:" + p.length);
						var dis:Number = Number.MAX_VALUE;
						var pair:Array = [ -1, -1];
						var cdis:Number;
						for (j = 0; j < p.length; j++ ) {
							for (k = j + 1; k < p.length; k++) {
								if(p[k]&&p[j]){
									var r1:Number = (0xFF0000 & p[j]) >> 16;
									var r2:Number = (0xFF0000 & p[k]) >> 16;
									var g1:Number = (0x00FF00 & p[j]) >> 8;
									var g2:Number = (0x00FF00 & p[k]) >> 8;
									var b1:Number = (0x0000FF & p[j]) >> 0;
									var b2:Number = (0x0000FF & p[k]) >> 0;
									cdis = Math.sqrt((r2 - r1) * (r2 - r1) + (g2 - g1) * (g2 - g1) + (b2 - b1) * (b2 - b1));
									if (cdis < dis) {
										trace("Closest so far: #" + uint(p[j]).toString(16) + " and " + uint(p[k]).toString(16));
										trace("(Distance: " + cdis);
										pair = [j, k];
										dis = cdis;
									}
								}
							}
						}
						if (pair[0] != -1 && pair[1] != -1) {
							r1 = (0xFF0000 & p[pair[0]]) >> 16;
							r2 = (0xFF0000 & p[pair[1]]) >> 16;
							g1 = (0x00FF00 & p[pair[0]]) >> 8;
							g2 = (0x00FF00 & p[pair[1]]) >> 8;
							b1 = (0x0000FF & p[pair[0]]) >> 0;
							b2 = (0x0000FF & p[pair[1]]) >> 0;
							var newc:uint = p[pair[0]]//(uint((r1 + r2) / 2) << 16) | (uint((g1 + g2) / 2) << 8) | uint((b1 + b2) / 2);
							//trace("New color (from averaging): #" + newc.toString(16));
							trace("New color (from first detected): #" + newc.toString(16));
							p[pair[0]] = newc;
							var v:uint = 0;
							while (v < d.length) {
								if (d[v] == pair[1]) {
									d[v] == pair[0];
								}
								else if (d[v] == p.length -1){
									d[v] = pair[1];
								}
								v++;
							}
							p[pair[1]] = p.length - 1;
							p.pop();
							trace("----------------------------------");
						}
						else {
							trace("Failed to compress palette - is it all black?!");
							p.pop();
						}
					}*/
				
	
					var re:Array = p.concat(); //duplicate our palette array
					re.sort();				   //and sort it numerically
					j = 0;
					while (j < d.length) {
						k = 0;
						d[j] = re.indexOf(p[d[j]]); //modify data so it fits the ordered array
						j++;
					}
					
					j = 0;
					while (j < re.length) {
						re[j] = ((re[j] & 0xF80000) >> 9) | ((re[j] & 0xF800) >> 6) | ((re[j] & 0xF8) >> 3);
						j++;
					}
					//trace(re);
					j = 0;
					k = 0;
					var dp:int = -1;
					while (j < palettes.length) {
						if (String(re) == String(palettes[j])) {
							dp = j;
							break;
						}						
						j++;
					}
					
					
					if (dp == -1) {
						palettes.push(re);
						dp = palettes.length - 1;
					}

					var trans:Boolean = false;
					//trace(dp);
					//var z:uint = 0;
					//while (z < palettes.length) {
						//trace(palettes[z]);
						//z++;
					//}
					
					data.push([dp, trans,d]);
					x++;
				}
				y++;
				
			}
			renderTileList();
			renderPaletteList();
			renderMap(0);
			renderMap(1);
			renderMap(2);
			//trace(palettes);
		}
		//MAP BUTTON FUNCTIONS
		private function e_save_map(e:Event = null):void {
			file = new FileReference();
			var output:ByteArray = new ByteArray();
			output.writeUTFBytes(mapToString());
			file.save(output, ".vem");
			//trace(s);
		}
		
		private function e_load_map(e:Event = null):void {
			file = new FileReference();
			file.addEventListener(Event.SELECT, e_load_map_selected);
			file.browse([new FileFilter("vo-em map file (*.vem)", "*.vem")]);
		}
		
		private function e_load_map_selected(e:Event = null):void {
			file.addEventListener(Event.COMPLETE, e_load_map_loaded);
			file.load();
		}
		
		private function e_load_map_loaded(e:Event = null):void {
			addUndoLevel();
			clearSelection();
			var fileReference:FileReference = e.target as FileReference;
			var tmapsd:ByteArray = fileReference["data"];
			var tmaps:String = tmapsd.toString();
			var tmap:Array = [];
			var i:uint = 0;
			var k:uint;
			var j:uint;
			map = [[], [], []];
			
			tmap = tmaps.split("---\n");//split into tmap[0]-tmap[2]
			i = 0;
				
			while (i < tmap.length) {
				tmap[i] = String(tmap[i]).split("\n");
				j = tmap[i].length;
				while (j > 0) {
					j--
					if (!tmap[i][j].length) {
						tmap[i].splice(j, 1);
					}
				}
				var offset:uint = 0;	
				j = 0;
				while (j < tmap[i].length) {
					tmap[i][j] = String(tmap[i][j]).split(",");
					offset = j * 255;
					k = tmap[i][j].length;
					while (k > 0) {
						k--
						if (!tmap[i][j][k].length) {
							tmap[i][j].splice(k, 1);
						}
					}
					k = 0;
					while (k < tmap[i][j].length) {
						//split here
						if (tmap[i][j][k] != "0|0") {
							map_visible[i] = true;
							var ta:Array = tmap[i][j][k].split("|");
							var ct:String = String(ta[0]);
							map[i][offset + k] = [];
							map[i][offset + k][M_HFLIP] = false;
							map[i][offset + k][M_VFLIP] = false;
							map[i][offset + k][M_TRANS] = false;
							map[i][offset + k][M_PALETTE] = uint.MAX_VALUE;
							map[i][offset + k][M_TILE] = uint.MAX_VALUE;
							
							
							var l:uint = 0;
							while (l < ct.length) {
								if (ct.charAt(l) == "h") {
									map[i][offset + k][M_HFLIP] = true;
									ct = StringManip.cutFromString(ct, l, 1);
									l--;
								}
								else if (ct.charAt(l) == "v") {
									map[i][offset + k][M_VFLIP] = true;
									ct = StringManip.cutFromString(ct, l, 1);
									l--;
								}
								else if (ct.charAt(l) == "t") {
									map[i][offset + k][M_TRANS] = true;
									ct = StringManip.cutFromString(ct, l, 1);
									l--;
								}
								l++;
							}
							if (isNaN(parseInt(ct, 10))) {
							//	trace(ct);
							}
							map[i][offset + k][M_TILE] = parseInt(ct, 10);
							map[i][offset + k][M_PALETTE] = parseInt(ta[1], 10);
							//trace(map[i][offset + k]);
						}
						k++;
					}
					j++;
				}
				i++;
			}
			
			
			i = 0;
			while (i < 3) {
				renderMap(i);
				i++;
			}
		}
		
		//palette loader and saver functions
		private function e_load_palette(e:Event = null):void {
			file = new FileReference();
			file.addEventListener(Event.SELECT, e_palette_selected);
			file.browse([new FileFilter("vo-em palette file (*.vem)", "*.vep")]);
		}	
		private function e_palette_selected(e:Event = null):void {
			file.addEventListener(Event.COMPLETE, e_palette_loaded);
			file.load();
		}		
		private function e_palette_loaded(e:Event = null):void {
			addUndoLevel();
			clearSelection();
			var fileReference:FileReference = e.target as FileReference;
			var palsd:ByteArray = fileReference["data"];
			var pals:String = palsd.toString();
			var pala:Array = pals.split("\r\n");
			palettes = [];
			var i:uint = 0;
			while (i < pala.length) {

				pala[i] = String(pala[i]).split(",");
				palettes[i] = [];
				var j:uint = 0;
				while (j < pala[i].length) {
					var c:uint = uint(parseInt(pala[i][j], 16))
					palettes[i][j] = c;
					j++;
				}
				i++;
			}
			renderPaletteList();
			renderTileList();
			renderMap(0);
			renderMap(1);
			renderMap(2);
			//trace(palettes);
		}
		private function e_save_palette(e:Event = null):void {
			file = new FileReference();
			var output:ByteArray = new ByteArray();
			output.writeUTFBytes(paletteToString());
			file.save(output, ".vep");
			//trace(s);
		}
		
		private function paletteToString():String {
			var o:String = "";
			var i:uint = 0;
			while (i < palettes.length) {
				if (i) {
					o = o + "\r\n";
				}
				var j:uint = 0;
				while (j < palettes[i].length) {
					if (j) {
						o = o + ",";
					}
					o = o + uint(palettes[i][j]).toString(16);
					j++;
				}
				i++;
			}
			return o;
		}
		
		private function e_save_sprites(e:Event = null):void {
			var o:String = "";
			var i:uint = 0;
			while (i < data.length) {
				var j:uint = 0;
				while (j < 16 * 16) {
					if (!(j % 16)) {
						o = o + "\n";
					}
					o = o + uint(data[i][D_IMAGE][j]).toString()+" ";
					j++;
				}
				o = o + "\n," + uint(data[i][D_PALETTE]).toString() +".\n\n";
				i++;
			}
			file = new FileReference();
			var output:ByteArray = new ByteArray();
			output.writeUTFBytes(mapToString());
			file.save(o, ".ves");
		}
		
		//ASM exporter stuff
		private var exp_palettes:Boolean = true;
		private var exp_sprites:Boolean = true;
		private var exp_map:Boolean = true;
		private const TM_OPTIONS_ROTV:uint = 	parseInt("01000000", 2);
		private const TM_OPTIONS_ROTH:uint = 	parseInt("10000000", 2);
		private const TM_OPTIONS_TRANS:uint = 	parseInt("00100000", 2);
		private const TM_OPTIONS_PALETTE:uint = 	parseInt("00011111", 2);
		private function e_export_asm(e:Event = null):void {
			var i:uint = 0;
			var j:uint = 0;
			var k:uint = 0;
			var o:String = "";
			var eb:String = ";Palette Data\n";
			var ms:Point = findMapSize();
			i = 0;
			while (i < palettes.length) {
				j = 0;
				eb = eb + "PAL_" + StringManip.pad(i.toString(16).toUpperCase(), "0", 2) + "		.halfu	";
				
				while (j < 8) {
					if (j) {
						eb = eb + ",";
					}
					if (palettes[i][j]) {
						eb = eb + "16#" + StringManip.pad(uint(palettes[i][j]).toString(16).toUpperCase(), "0", 4);
						o = o + "0x" + StringManip.pad(uint(palettes[i][j]).toString(16), "0", 4)+", ";
					}
					else {
						eb = eb + "16#0000";
					}
					j++;
				}
				eb = eb + "\n";
				o = o + "\n"
				
				i++;
			}
			eb = eb + "PAL_LEN		.equ		16#" + uint(i * 16).toString(16).toUpperCase() + "\n\n";
			
			i = 0;
			j = 0;
			eb = eb+"\n;Sprite/Tile data:\n";
			var dbg:String = "Sprites:\n------------------------\n";
			while (i < data.length) {
				dbg = dbg + "[#"+i+"]---------------------------------\n";
				j = 0;
				eb = eb + "SPR_" + StringManip.pad(i.toString(16).toUpperCase(), "0", 2) + "		.halfu	";
				o = o + "[#" + i + ": palette:" + data[i][0] + " trans:" + data[i][1] + "]\n";
				while (j < data[i][2].length) {
					if (!(j % 16)) {
						o = o + "\n";
					}
					
					o = o + data[i][2][j]+ " ";
					j++;
				}
				j = 0;
				k = 0;
				var a:uint = 0;
				var b:uint = 0;
				var c:uint = 0;
				while (j < data[i][2].length) {
					k = 0;
					a = b = c = 0;
					while (k < 16) {
						dbg = dbg + " " + data[i][2][j + k];
						a = a | (((data[i][2][j + k] >> 2 ) & 1) << (15 - k)); 
						b = b | (((data[i][2][j + k] >> 1 ) & 1) << (15 - k)); 
						c = c | (((data[i][2][j + k]      ) & 1) << (15 - k));
						
						k++;
					}
					//trace(a.toString().length, b.toString().length, c.toString().length);
					if (j) {
						eb = eb + ",";
						
					}
					dbg = dbg + "\n";
					eb = eb + "16#" + StringManip.pad(a.toString(16).toUpperCase(), "0", 4) + ",16#" + StringManip.pad(b.toString(16).toUpperCase(), "0", 4) + ",16#" + StringManip.pad(c.toString(16).toUpperCase(), "0", 4);
					//eb = eb + "\n\n" + padstring(a.toString(2), "0", 16) + "\n" + padstring(b.toString(2), "0", 16) + "\n" + padstring(c.toString(2), "0", 16);
					j += 16;
				}
				eb = eb + "\n";
				o = o+"\n\n"
				i++;
			}
			eb = eb + "SPR_LEN		.equ	16#" + uint(i * 16 * 3 * 2).toString(16).toUpperCase();
			trace(dbg);
			//format is map[layer][horizonal line][vertical tile][tile, x, y]
			var mo:String = ""
			eb = eb+"\n\n;Map data:";
			var cmap:Array = mapToString().split("---\n");
			trace("cmap length: " + cmap.length);
			i = 0;
			while (i < cmap.length) {
				if (map_visible[i] && cmap[i]) {
					mo = "";
					cmap[i] = String(cmap[i]).split("\n");
					j = cmap[i].length;
					while (j > 0) {
						j--
						if (!cmap[i][j].length) {
							cmap[i].splice(j, 1);
						}
					}
						
					j = 0;
					mo = mo + "LAY_" + i + "_DATA	.halfu	";
					var len:uint = 0;
					//trace("Doing: "+map[i][j]);
					while (j < cmap[i].length) {
						
						cmap[i][j] = String(cmap[i][j]).split(",");
						//trace(map[i][j]);
						
						k = cmap[i][j].length;
						while (k > 0) {
							k--
							if (!cmap[i][j][k].length) {
								cmap[i][j].splice(k, 1);
								//trace("snip!");
							}
						}
						k = 0;
						while (k < cmap[i][j].length) {
							if (k|j) {
								mo = mo + ",";
							}
							var cth:Array = String(cmap[i][j][k]).split("|");
							var ct:String = cth[0];
							var hb:uint = 0;
							var l:uint = 0;
							while (l < ct.length) {
								if (ct.charAt(l) == "h") {
									hb = hb | TM_OPTIONS_ROTH;
									ct = StringManip.cutFromString(ct, l, 1);
									l--;
								}
								else if (ct.charAt(l) == "v") {
									hb = hb | TM_OPTIONS_ROTV;
									ct = StringManip.cutFromString(ct, l, 1);
									l--;
								}
								else if (ct.charAt(l) == "t") {
									hb = hb | TM_OPTIONS_TRANS;
									ct = StringManip.cutFromString(ct, l, 1);
									l--;
								}
								l++;
							}
							var lb:uint = 0;
							var ctp:int = parseInt(ct, 10);
							if (ctp < 0) { ctp = 0; };
							if (ctp) {
								lb = parseInt("10000000", 2) | ctp;
							}
							hb = hb|parseInt(cth[1], 10);
							//hb = hb | data[ctp][0];
							//trace(ctp, data[ctp]);
							mo = mo + "16#" + StringManip.pad(uint((hb << 8) | lb).toString(16).toUpperCase(), "0", 4);
							len += 2;
							k++;
						}
						j++;
					}
					var mds:String = "";
					mds = mds + "\nLAY_" + i;
					mds = mds + "\nLAY_" + i + "_LEN	.word	16#" + len.toString(16).toUpperCase();
					mds = mds + "\nLAY_" + i + "_WIDTH	.word	10#" + cmap[i][0].length;
					mds = mds + "\nLAY_" + i + "_HEIGHT	.word	10#" + cmap[i].length+"\n";
					mds = mds + mo + "\n";
					mo = mds;
					eb = eb + mo;
				}
				i++;
			}
			
			trace("____________________");
			trace(eb);
			//trace("\n", mo);
			file = new FileReference();
			var output:ByteArray = new ByteArray();
			output.writeUTFBytes(eb);
			file.save(output, ".dls");
		}
		
		private function renderPaletteList(targets:Array = null ):void {
			//i_palette_list.fillRect(i_palette_list.rect, 0);
			var i:uint = 0;
			var t:BitmapData = new BitmapData(80, 10, true, 0);
			i_palette_list.fillRect(i_palette_list.rect, 0);
			if (!targets) {
				targets = [];
				while (i < palettes.length) {
					targets.push(i);
					i++;
				}
			}
			i = 0;
			i_palette_list.lock();
			while (i < targets.length) {
				var cp:Array = reqPal(targets[i]);
				t.fillRect(t.rect, 0);
				
				var j:uint = 0;
				while(j<cp.length){
					var c:uint = cp[j];
					t.fillRect(new Rectangle(j*10, 0, 10, 10), 0xFF000000 | (((c << 9) & 0xF80000) | ((c << 6) & 0xF800) | ((c << 3) & 0xF8)));
					j++;
				}
				i_palette_list.copyPixels(t, t.rect, new Point(0, i * 10));
				i++;
			}
			i_palette_list.unlock();
		}
		
		private function renderTileList():void {
			//dumpVisualData();
			var rc:BitmapData = i_tile_list;
			rc.lock();
			rc.fillRect(rc.rect, 0);
			var i:uint = 0;
			while (i < data.length) {
				var y:uint = 0;
				while (y < 16) {
					var x:uint = 0;
					while (x < 16) {
						var c:uint = 0;
						if(data[i][2][y * 16 + x] < reqPal(data[i][0]).length){
							c = reqPal(data[i][0])[data[i][2][y * 16 + x]];
						}
						rc.setPixel32(x + i * 16, y, 0xFF000000 | (((c << 9) & 0xF80000) | ((c << 6) & 0xF800) | ((c << 3) & 0xF8)));
						x++;
					}
					y++;
				}
				i++;
			}
			rc.unlock();
		}
		
		private function renderMap(target:uint):void {
			var i:uint = 0;
			var rc:BitmapData = i_world_map[target];
			rc.lock();
			rc.fillRect(rc.rect, 0);
			while (i < 255 * 255) {
				if (map[target][i]) {
					var cp:Array = reqPal(map[target][i][M_PALETTE]);
					var cd:Array = reqDat(map[target][i][M_TILE]);
					//trace(map[target][i]);
					var y:int = 0;
					while (y < 16) {
						var x:int = 0;
						while (x < 16) {
							if(cd[D_IMAGE][y * 16 + x]||!map[target][i][M_TRANS]){
								var c:uint = 0;
								if(cd[D_IMAGE][y * 16 + x] <= cp.length){
									c = cp[cd[D_IMAGE][y * 16 + x]];
								}
								var fx:int = 0;
								var fy:int = 0;
								var cx:int = x;
								var cy:int = y;
								if (map[target][i][M_HFLIP]) {
									fx = 15;
								}
								else {
									cx = -x;
								}
								if (map[target][i][M_VFLIP]) {
									fy = 15;
								}
								else {
									cy = -y;
								}
								rc.setPixel32((fx-cx) + Math.floor(i % 255)*16, (fy-cy) + Math.floor(i / 255)*16, 0xFF000000 | (((c << 9) & 0xF80000) | ((c << 6) & 0xF800) | ((c << 3) & 0xF8)));
							}
							x++;
						}
						y++;
					}
				}
				i++;
			}
			rc.unlock();
		}

		private function renderMapTile(at:uint, on:uint):void {
			var i:uint = at;
			var target:uint = on;
			var rc:BitmapData = i_world_map[target];
			rc.lock();
			rc.fillRect(new Rectangle(Math.floor(i % 255) * 16, Math.floor(i / 255) * 16, 16, 16), 0);
			//rc.fillRect(rc.rect, 0);
			if (map[target][i]) {
				var cp:Array = reqPal(map[target][i][M_PALETTE]);
				var cd:Array = reqDat(map[target][i][M_TILE]);
				//trace(map[target][i]);
				var y:int = 0;
				while (y < 16) {
					var x:int = 0;
					while (x < 16) {
						if(cd[D_IMAGE][y * 16 + x]||!map[target][i][M_TRANS]){
							var c:uint = 0;
							if(cd[D_IMAGE][y * 16 + x] <= cp.length){
								c = cp[cd[D_IMAGE][y * 16 + x]];
							}
							var fx:int = 0;
							var fy:int = 0;
							var cx:int = x;
							var cy:int = y;
							if (map[target][i][M_HFLIP]) {
								fx = 15;
							}
							else {
								cx = -x;
							}
							if (map[target][i][M_VFLIP]) {
								fy = 15;
							}
							else {
								cy = -y;
							}
							rc.setPixel32((fx-cx) + Math.floor(i % 255)*16, (fy-cy) + Math.floor(i / 255)*16, 0xFF000000 | (((c << 9) & 0xF80000) | ((c << 6) & 0xF800) | ((c << 3) & 0xF8)));
						}
						x++;
					}
					y++;
				}
			}
			rc.unlock();
		}
		
		private function renderColorPicker():void {
			i_picker.lock();
			var m:uint = 0;
			while (m < 32768) {
				i_picker.setPixel(m % 256, m / 256, HSLtoRGB15bit((Number(m % 256)/256)*360, picker_sat,1-(Number(m/256)/128)));
				m++;
			}
			i_picker.unlock();
		}
		//selection functions
		private function clearSelection():void {
			selectiontype = SELECT_NONE;
			subselectiontype = SUB_SELECT_NONE;
			toolmode = T_SELECT;
			selected = [];
		}
		private function clearSubSelection():void {
			subselectiontype = SUB_SELECT_NONE;
			selected[1] = null;
		}
		//mouse handlers
		private function mousemovedhandler(e:Event = null):void {
			mouse_moved = true;
			if (dragging_tiles) {
				tileScroll += (lastmouse.x - stage.mouseX)/2;
			}
			if (dragging_palette) {
				paletteScroll += lastmouse.y - stage.mouseY;
			}
			if (dragging_map) {
				mapScrollX += (lastmouse.x - stage.mouseX);
				mapScrollY += (lastmouse.y - stage.mouseY);
			}
			if (free_drawing && toolmode == T_PLACE && worldmap.getRect(stage).containsPoint(new Point(stage.mouseX, stage.mouseY))) {
				var hit:uint = getIndex(HL_WORLDSQUARE, mouseX, mouseY);
			
				if (selectiontype == SELECT_TILE) {
					map[current_map][hit] = [];
					map[current_map][hit][M_PALETTE] = uint(data[selected[0]][D_PALETTE]);
					map[current_map][hit][M_TILE] = uint(selected[0]);
					if (current_map) { //no transparency on bottom layer!
					map[current_map][hit][M_TRANS] = transtoggle;
					}
					else {
						map[current_map][hit][M_TRANS] = false;
					}
					map[current_map][hit][M_HFLIP] = hflipped;
					map[current_map][hit][M_VFLIP] = vflipped;
					renderMapTile(hit, current_map);
				}
			}
			lastmouse.x = stage.mouseX;
			lastmouse.y = stage.mouseY;
		}
		
		private function palettedrag(e:Event = null):void {
			dragging_palette = true;
			mouse_moved = false;
		}
		
		private function paletteselect(e:Event = null):void {
			var i:uint;
			var j:uint;
			var k:uint;
			if (!mouse_moved) {
				addUndoLevel();
				clearSubSelection();
				var hit:uint = Math.floor((stage.mouseY - palettelist.y + paletteScroll)/10);
					
				switch(selectiontype) {	
					case SELECT_NONE:
					case SELECT_PALETTE:
						if (hit >= palettes.length) {
							clearSelection();
							return;
						}
						if (toolmode == T_COMBINE) {
							i = 0;
							while (i < related.length) {
								if (related[i] == hit) {
									toolmode = T_SELECT;
									selected = [combinePalettes(related[i], selected[0])];
								}
								i++;
							}
							return;
						}
						selectiontype = SELECT_PALETTE;
						selected = [hit];
						drawEditPal();
						drawEditTile();
					break;
					case SELECT_TILE:
						if(hit<palettes.length){
							data[selected[0]][D_PALETTE] = hit;
							renderTileList();
							drawEditPal();
							drawEditTile();
						}
					break;
					case SELECT_WORLD_SQUARE:
						if (hit >= palettes.length) {
							return;
						}
						if (map[current_map][selected[0]]) {
							map[current_map][selected[0]][M_PALETTE] = hit;
							renderAll();
						}
					break;
				}
			}
		}
		
		private function tiledrag(e:Event = null):void {
			dragging_tiles = true;
			mouse_moved = false;
		}
		
		private function tileselect(e:Event = null):void {
			if (!mouse_moved) {
				selectiontype = SELECT_TILE;
				selected = [Math.floor((stage.mouseX - tilelist.x + tileScroll*2) / 32)];
				//trace(selected, data.length);
				if (selected[0] >= data.length) {
					clearSelection();
				}
				else {
					drawEditPal();
					drawEditTile();
				}
				clearSubSelection();
			}
		}
		
		private function mapdrag(e:Event = null):void {
			switch(toolmode) {
				case T_SCROLL:
					dragging_map = true;
					mouse_moved = false;
				break;
				case T_DRAG:
				
				break;
				case T_SELECT:
				
				break;
				case T_ERASE:
				
				break;
				case T_PLACE:
					if (!free_drawing) {
						addUndoLevel();
					}
					free_drawing = true;
				break;
			}
		}
		
		private function mapselect(e:Event = null):void {
			if (mouse_moved) {
				return;
			}
			clearSubSelection();
			if (!map_visible[current_map]) { //no sense letting people draw on an invisible map
				return;
			}
			var hit:uint = getIndex(HL_WORLDSQUARE, mouseX, mouseY);
			
			switch(toolmode) {
				case T_SELECT:
					//nested switch on tools, maybe we're erasing or selecting
					if (!map[current_map][hit]) {
						return;
					}
					selected = [hit];
					selectiontype = SELECT_WORLD_SQUARE;
					drawEditPal();
					drawEditTile();
				break;
				case T_PLACE:
					//def placing a tile here
					if (selectiontype == SELECT_TILE) {
						addUndoLevel();
						map[current_map][hit] = [];
						map[current_map][hit][M_PALETTE] = uint(data[selected[0]][D_PALETTE]);
						map[current_map][hit][M_TILE] = uint(selected[0]);
						if (current_map) { //no transparency on bottom layer!
							map[current_map][hit][M_TRANS] = transtoggle;
						}
						else {
							map[current_map][hit][M_TRANS] = false;
						}
						map[current_map][hit][M_HFLIP] = hflipped;
						map[current_map][hit][M_VFLIP] = vflipped;
						renderMapTile(hit, current_map);
					}
				break;
				case T_ERASE:
					addUndoLevel();
					map[current_map][hit] = null;
					renderMapTile(hit, current_map);
				break;
				case T_FLOOD:
					addUndoLevel();
					floodFill(hit, selected[0], current_map, selectiontype);
					renderMap(current_map);
				break;
			}
		}
	
		private function peditdrag(e:Event = null):void {
			mouse_moved = false;
		}
		
		private function peditselect(e:Event = null):void {
			var t:uint;
			var cp:Array;
			if (mouse_moved) {
				return;
			}
			if (selectiontype != SELECT_WORLD_SQUARE && selectiontype != SELECT_TILE && selectiontype != SELECT_PALETTE) {
				return;
			}
			if(subselectiontype == SUB_SELECT_P_EDIT){
				if (!selected[1]) {
					selected[1] = getIndex(HL_PALEDIT, mouseX, mouseY);
				}
				else {
					
					if (selectiontype == SELECT_PALETTE) {
						cp = reqPal(selected[0]);
					}
					else if (selectiontype == SELECT_TILE) {
						cp = reqPal(reqDat(selected[0])[D_PALETTE]);
					}
					else if (selectiontype == SELECT_WORLD_SQUARE) {
						if (!map[current_map][selected[0]]) {
							return;
						}
						cp = reqPal(map[current_map][selected[0]][M_PALETTE]);
					}
					else {
						return;
					}
					if(toolmode == T_SWAPPER){	
						addUndoLevel();
						t = cp[selected[1]];
						cp[selected[1]] = cp[getIndex(HL_PALEDIT, mouseX, mouseY)] 
						cp[getIndex(HL_PALEDIT, mouseX, mouseY)] = t;
						subselectiontype = SUB_SELECT_NONE;
						selected[1] = null;
						renderAll();
					}
					else{
						selected[1] = getIndex(HL_PALEDIT, mouseX, mouseY)
					}
				}
			}
			else if (subselectiontype == SUB_SELECT_T_EDIT) {
				addUndoLevel();
				remapColourChannel(universalGetDataID(selected[0]), universalGetTile(selected[0])[D_IMAGE][selected[1]], getIndex(HL_PALEDIT, mouseX, mouseY));
				renderAll();
			}
			else {
				subselectiontype = SUB_SELECT_P_EDIT
				selected[1] = getIndex(HL_PALEDIT, mouseX, mouseY);
			}
		}
		
		private function teditdrag(e:Event = null):void {
				mouse_moved = false;
		}
		
		private function teditselect(e:Event = null):void {
	
			if (selectiontype != SELECT_TILE && selectiontype != SELECT_WORLD_SQUARE) {
				return;
			}
			var hit:uint = getIndex(HL_TILEEDIT, mouseX, mouseY);
			var hitChannel:uint = universalGetTile(selected[0])[D_IMAGE][hit]
			if (mouse_moved) {
				return;
			}
			if (subselectiontype == SUB_SELECT_P_EDIT) {
				if (toolmode == T_SWAPPER) {
					addUndoLevel();
					remapColourChannel(universalGetDataID(selected[0]), hitChannel, selected[1]);
					renderAll();
					subselectiontype = SUB_SELECT_NONE;
					selected[1] = null;
				}
				else if (toolmode == T_PENCIL) {
					info.text = "Drawing with pencils! ["+uint(selected[0])+"]"+hit+"->" + uint(selected[1]).toString();
					addUndoLevel();
					data[selected[0]][D_IMAGE][hit] = selected[1];
					renderAll();
				}
			}
			else if (subselectiontype == SUB_SELECT_T_EDIT) {
				if (toolmode == T_SWAPPER) {
					addUndoLevel();
					//trace("Swapping channels " + universalGetDataID(selected[0]) + " and " + selected[1] + ".");
					swapColourChannels(universalGetDataID(selected[0]), universalGetTile(selected[0])[D_IMAGE][selected[1]], hitChannel);
					renderAll();
					subselectiontype = SUB_SELECT_NONE;
					selected[1] = null;
					addUndoLevel();
				}
			}
			else {
				if (toolmode == T_SELECT || toolmode == T_SWAPPER) {
					subselectiontype = SUB_SELECT_T_EDIT;
					selected[1] = hit;
				}
			}
		}
		
		private function colorpickerdrag(e:Event = null):void {
			mouse_moved = false;
		}
		
		private function colorpickerselect(e:Event = null):void {
			if (subselectiontype == SUB_SELECT_P_EDIT ){
				var s:uint = i_picker.getPixel(stage.mouseX - colorpicker.x, stage.mouseY - colorpicker.y);
				s = ((s & 0xF80000) >> 9) | ((s & 0xF800) >> 6) | ((s & 0xF8) >> 3);
				var cpal:Array = MISSING_PALETTE;
				if (selected[0] == -1) {
					return;
				}
				switch(selectiontype) {
					case SELECT_PALETTE:
						cpal = reqPal(selected[0])
					break;
					case SELECT_WORLD_SQUARE:
						if (!map[current_map][selected[0]]) {
							return;
						}
						else {
							cpal = reqPal(map[current_map][selected[0]][M_PALETTE]);
						}
					break;
					case SELECT_TILE:
						cpal = reqPal(reqDat(selected[0])[D_PALETTE]);
					break;	
					return;
				}
				info.text = "New color selected! " + cpal[selected[1]]+"->"+s;
				addUndoLevel();
				cpal[selected[1]] = s;
				renderAll();	
			}
		}
		
		private function renderAll():void {
			renderMap(0);
			renderMap(1);
			renderMap(2);
			renderTileList();
			renderPaletteList();
			drawEditPal();
			drawEditTile();
		}
		
		//toolbox button listeners
		private function b_select_handler(e:Event = null):void {
			toolmode = T_SELECT;
			tool_highlighter.x = b_select.x;
			tool_highlighter.y = b_select.y;
		}	
		private function b_scroll_handler(e:Event = null):void {
			toolmode = T_SCROLL;
			tool_highlighter.x = b_scroll.x;
			tool_highlighter.y = b_scroll.y;
		}
		private function b_erase_handler(e:Event = null):void {
			toolmode = T_ERASE;
			tool_highlighter.x = b_erase.x;
			tool_highlighter.y = b_erase.y;
		}
		private function b_place_handler(e:Event = null):void {
			toolmode = T_PLACE;
			tool_highlighter.x = b_place.x;
			tool_highlighter.y = b_place.y;
		}
		private function b_flood_handler(e:Event = null):void {
			toolmode = T_FLOOD;
			tool_highlighter.x = b_flood.x;
			tool_highlighter.y = b_flood.y;
		}
		private function b_pencil_handler(e:Event = null):void {
			toolmode = T_PENCIL;
			tool_highlighter.x = b_pencil.x;
			tool_highlighter.y = b_pencil.y;
		}
		private function b_swapper_handler(e:Event = null):void {
			toolmode = T_SWAPPER;
			tool_highlighter.x = b_swapper.x;
			tool_highlighter.y = b_swapper.y;
		}
		//layerbox handlers
		private function b_layer0_handler(e:Event = null):void {
			layer_highlight.y = b_layer0.y;
			current_map = 0;
		}
		private function b_layer1_handler(e:Event = null):void {
			layer_highlight.y = b_layer1.y;
			current_map = 1;
		}
		private function b_layer2_handler(e:Event = null):void {
			layer_highlight.y = b_layer2.y;
			current_map = 2;
		}
		private function b_layer0_toggle_handler(e:Event = null):void {
			map_visible[0] = !map_visible[0]
			layer0_toggle_highlight.visible = map_visible[0]; 
		}
		private function b_layer1_toggle_handler(e:Event = null):void {
			map_visible[1] = !map_visible[1]
			layer1_toggle_highlight.visible = map_visible[1]; 
		}
		private function b_layer2_toggle_handler(e:Event = null):void {
			map_visible[2] = !map_visible[2]
			layer2_toggle_highlight.visible = map_visible[2]; 
		}
		
		//middletools handlers
		private function b_combine_handler(e:Event = null):void {
			if (selectiontype == SELECT_PALETTE) {
				if (toolmode == T_COMBINE) {
					toolmode = T_SELECT;
					related = [];
					return;
				}
				toolmode = T_COMBINE;
				//find applicable palettes
				related = [];
				var c:Array = palettes[selected[0]];
				var i:uint = 0;
				var match:uint;
				while (i < palettes.length) {
					match = 0;
					if (i != selected[0]) {
						var t:Array = []
						var j:uint = 0;
						while (j < palettes[i].length) {
							t.push(palettes[i][j]);
							j++;
						}
						j = 0;
						while (j < c.length) {
							t.push(c[j]);
							j++;
						}
						t.sort(Array.NUMERIC);
						j = t.length - 2;
						while (j > 0) {
							if (t[j] == t[j + 1]) {
								t.splice(j + 1, 1);
							}
							j--;
						}
						if (t.length <= 8) {
							related.push(i);
						}
					}
					i++;
				}
			}
		}
		private function b_delete_handler(e:Event = null):void {
			info.text = "Delete feature coming soon...!";
		}
		private function b_newpal_handler(e:Event = null):void {
			addUndoLevel();
			palettes.push([0]);
			selected[0] = palettes.length - 1;
			selectiontype = S_PALETTE_EDIT;
			subselectiontype = SUB_SELECT_NONE;
			selected[1] = -1;
			renderPaletteList();
		}
		private function b_newtile_handler(e:Event = null):void {
			addUndoLevel();
			data.push([0, false, []]);
			if (!palettes.length) {
				palettes.push([]);
			}
			var i:uint = 0;
			while (i < 16 * 16) {
				data[data.length - 1][D_IMAGE][i] = 0;
				i++;
			}
			clearSelection();
			clearSubSelection();
			selectiontype = SELECT_TILE;
			selected[0] = data.length - 1;
			renderAll();
		}
		
		private function mouseuphandler(e:Event = null):void {
			dragging_palette = false;
			dragging_tiles = false;
			dragging_map = false;
			free_drawing = false;
			//TODO: CHANGE THIS TO DRAGGING SQUARES!
		}
		
		private function mousedownhandler(e:Event = null):void {
			mousedownpoint.x = this.mouseX;
			mousedownpoint.y = this.mouseY;
			lastmouse.x = this.mouseX;
			lastmouse.y = this.mouseY;
			mouse_moved = false;
		}
		private var picker_sat:Number = 1;
		private var picker_sat_step:Number = 0.1;
		private function hotkeyhandler(e:KeyboardEvent):void {
			switch(e.keyCode) {
				case HK_HFLIP:
					hflipped = !hflipped;
				break;
				case HK_VFLIP:
					vflipped = !vflipped;
				break;
				case HK_TRANS:
					transtoggle = !transtoggle;
				break;
				case HK_DESEL:
					clearSelection();
				break;
				case KeyCodes.Z:
					doUndo();
				break;
				case KeyCodes.Y:
					doRedo();
				break;
				case 219:
					if (picker_sat > 0) {
						picker_sat -= picker_sat_step;
						renderColorPicker();
					}
				break;
				case 221:
					if (picker_sat < 1) {
						picker_sat += picker_sat_step;
						renderColorPicker();
					}
				break;
			}
		}
		
		
		//sprite/palette editor handlers
		private function drawEditPal():void {
			
			if (selectiontype == SELECT_NONE) {
				i_palette_order.fillRect(i_palette_order.rect, 0);
				return;
			}
			var i:uint = 0;
			var cpal:Array = MISSING_PALETTE;
			if (selected[0] == -1) {
				return;
			}
			switch(selectiontype) {
				case SELECT_PALETTE:
					cpal = reqPal(selected[0])
				break;
				case SELECT_WORLD_SQUARE:
					if (!map[current_map][selected[0]]) {
						return;
					}
					else {
						cpal = reqPal(map[current_map][selected[0]][M_PALETTE]);
					}
				break;
				case SELECT_TILE:
					cpal = reqPal(reqDat(selected[0])[D_PALETTE]);
				break;	
				return;
			}
			i_palette_order.lock();
			while (i < 8) {
				var c:uint = 0xFF000000;
				if (cpal[i]) {
					c = cpal[i];
					c = 0xFF000000 | (((c << 9) & 0xF80000) | ((c << 6) & 0xF800) | ((c << 3) & 0xF8));
				}
				i_palette_order.fillRect(new Rectangle(i * 16, 0, 16, 16), c);
				i++;
			}
			i_palette_order.unlock();
		}
		private function drawEditTile():void {
			if (selectiontype == SELECT_NONE) {
				i_sprite_editor.fillRect(i_sprite_editor.rect, 0);
				return;
			}
			var cd:Array;
			var cp:Array;
			if (selectiontype == SELECT_TILE) {
				//trace(reqDat(selected[0]));
				cd = reqDat(selected[0])[D_IMAGE];
				cp = reqPal(reqDat(selected[0])[D_PALETTE]);
			}
			else if ( selectiontype == SELECT_WORLD_SQUARE) {
				if (!map[current_map][selected[0]]) {
					return;
				}
				cd = reqDat(map[current_map][selected[0]][M_TILE])[D_IMAGE];
				cp = reqPal(map[current_map][selected[0]][M_PALETTE]);
			}
			else {
				return;
			}
			i_sprite_editor.lock();
			var i:uint = 0;
			while (i < 16*16) {
				var c:uint = cp[cd[i]];
				c = 0xFF000000 | (((c << 9) & 0xF80000) | ((c << 6) & 0xF800) | ((c << 3) & 0xF8));
			
				i_sprite_editor.fillRect(new Rectangle((i % 16) * 8, Math.floor(i / 16) * 8, 8, 8), c);
				i++;
			}
			i_sprite_editor.unlock();
		}
		
		private function reqPal(i:uint):Array {
			if (palettes[i]) {
				return palettes[i];
			}
			return MISSING_PALETTE;
		}
		private function reqDat(i:uint):Array {
			if (data[i]) {
				return data[i]
			}
			else {
				return MISSING_TILE;
			}
		}
		private function universalGetTile(i:uint):Array {
			switch(selectiontype) {
				case SELECT_TILE:
					return reqDat(i);
				break;
				case SELECT_WORLD_SQUARE:
					if (map[current_map][i]) {
						return reqDat(map[current_map][i][M_TILE])
					}
					return MISSING_TILE;
				break;
			}
			return MISSING_TILE;
		}
		private function universalGetDataID(i:uint):uint {
			switch(selectiontype) {
				case SELECT_TILE:
					return i;
				break;
				case SELECT_WORLD_SQUARE:
					if (map[current_map][i]) {
						return map[current_map][i][M_TILE]
					}
				break;
			}
			return 0;
		}
		private function universalGetPal(i:uint):Array {
			switch(selectiontype) {
				case SELECT_PALETTE:
					return reqPal(i);
				break;
				case SELECT_TILE:
					return reqPal(reqDat(i)[D_PALETTE]);
				break;
				case SELECT_WORLD_SQUARE:
					if (map[current_map][i]) {
						return reqPal(map[current_map][i][M_PALETTE]);
					}
					
				break;
			}
			return MISSING_PALETTE;
		}
		private const HL_TILE:uint = 0;
		private const HL_PALETTE:uint = 1;
		private const HL_WORLDSQUARE:uint = 2;
		private const HL_PALEDIT:uint = 3;
		private const HL_TILEEDIT:uint = 4;
		private var textLoader:URLLoader;
		private function highlight(target:uint, index:uint, colour:uint = 0xFFFFFF):void {
			hl.lineStyle(2, colour, 0.5);
			switch(target) {
				case HL_TILE:
					hl.drawRect(tilelist.x + index * 32 - tileScroll*2, tilelist.y , 32, 32);
				break;
				case HL_PALETTE:
					hl.drawRect(palettelist.x, palettelist.y + paletteScroll + index * 10, palettelist.width, 10);
					
				break;
				case HL_WORLDSQUARE:
					hl.drawRect(worldmap.x + (index%255) * 16 - mapScrollX, worldmap.y + Math.floor(index/255) * 16 - mapScrollY, 16, 16);
					hl_label.x = worldmap.x + (index % 255) * 16 - mapScrollX + 5;
					hl_label.y = worldmap.y + Math.floor(index / 255) * 16 - mapScrollY;
					hl_label.text = index.toString(16);
				break;
				case HL_PALEDIT:
					hl.drawRect(paletteedit.x + index * 16, paletteedit.y, 16, 16);
				break;
				case HL_TILEEDIT:
					var cd:Array = [];
					if (selectiontype == SELECT_TILE) {
						if (!data[selected[0]]) {
							return;
						}
						else {
							cd = data[selected[0]][D_IMAGE];
						}
					}
					else if (selectiontype == SELECT_WORLD_SQUARE) {
						if (!data[map[current_map][selected[0]][M_TILE]]) {
							return;
						}
						else {
							cd = data[map[current_map][selected[0]][M_TILE]][D_IMAGE];
							
						}
					}
					else {
						return;
					}
					var i:uint = 0;
					if (toolmode == T_SWAPPER || toolmode == T_SELECT){
						while (i < 16 * 16) {
							if (cd[i] == cd[index]) {
								hl.drawRect(tileedit.x + (i % 16) * 8, tileedit.y + Math.floor(i / 16) * 8, 8, 8);
							}
							i++;
						}
					}
					else if (toolmode == T_PENCIL) {
						hl.drawRect(tileedit.x + (index % 16) * 8, tileedit.y + Math.floor(index / 16) * 8, 8, 8);
					}
				break;
			}
		}
		/**
		 * Flood fills an enclosed area either with a tile or flood replaces palettes
		 * @param	at		the point to start filling from
		 * @param	w		the palette or tile to fill with
		 * @param	target	the target layer
		 * @param	type	must be either SELECT_TILE or SELECT_PALETTE
		 * @param	orig	value of the original square that was clicked
		 * @param	strict	if false, can fill through corner joins
		 */
		private function floodFill(at:uint, w:uint, target:uint, type:uint, orig:uint = uint.MAX_VALUE, strict:Boolean = false):void {	
			if (type != SELECT_TILE && type != SELECT_PALETTE) {
				return;
			}
			var mtype:uint;
			var o:uint = orig;
			if (type == SELECT_TILE) {
				mtype = M_TILE;
 
				if (orig == uint.MAX_VALUE) {
					if(map[target][at]){
						o = map[target][at][M_TILE];
					}
					else {
						o = uint.MAX_VALUE - 1;
					}
				}
			}
			else if (type == SELECT_PALETTE) {
				mtype = M_PALETTE;
				if (orig == uint.MAX_VALUE) {
					if(map[target][at]){
						o = map[target][at][M_PALETTE];
					}
					else {
						return;
					}
				}
			}
			var pos:Point = GW_Math.toCoord(at, 255);
			if(o != uint.MAX_VALUE-1){
				if (type == SELECT_TILE) {
					map[target][at][M_TILE] = w;
					map[target][at][M_PALETTE] = data[w][D_PALETTE];
				}
				else if (type == SELECT_PALETTE) {
					map[target][at][M_PALETTE] = palettes[w];
				}
				//trace(map[target][at]);
				//above
				if (map[target][GW_Math.toIndex(pos.x, pos.y - 1, 255)]&&map[target][GW_Math.toIndex(pos.x, pos.y - 1, 255)][mtype] == o) {
					floodFill(GW_Math.toIndex(pos.x, pos.y - 1, 255), w, target, type, o);
				}
				//below
				if (map[target][GW_Math.toIndex(pos.x, pos.y + 1, 255)]&&map[target][GW_Math.toIndex(pos.x, pos.y + 1, 255)][mtype] == o) {
					floodFill(GW_Math.toIndex(pos.x, pos.y + 1, 255), w, target, type, o);
				}
				//left
				if (map[target][GW_Math.toIndex(pos.x - 1, pos.y, 255)]&&map[target][GW_Math.toIndex(pos.x - 1, pos.y, 255)][mtype] == o) {
					floodFill(GW_Math.toIndex(pos.x - 1, pos.y, 255), w, target, type, o);
				}
				//right
				if (map[target][GW_Math.toIndex(pos.x + 1, pos.y, 255)]&&map[target][GW_Math.toIndex(pos.x + 1, pos.y, 255)][mtype] == o) {
					floodFill(GW_Math.toIndex(pos.x + 1, pos.y, 255), w, target, type, o);
				}
				if (strict) {
					return;
				}
				//above left
				if (map[target][GW_Math.toIndex(pos.x-1, pos.y - 1, 255)]&&map[target][GW_Math.toIndex(pos.x-1, pos.y - 1, 255)][mtype] == o) {
					floodFill(GW_Math.toIndex(pos.x-1, pos.y - 1, 255), w, target, type, o);
				}
				//above right
				if (map[target][GW_Math.toIndex(pos.x+1, pos.y - 1, 255)]&&map[target][GW_Math.toIndex(pos.x+1, pos.y - 1, 255)][mtype] == o) {
					floodFill(GW_Math.toIndex(pos.x+1, pos.y - 1, 255), w, target, type, o);
				}
				//below left
				if (map[target][GW_Math.toIndex(pos.x-1, pos.y + 1, 255)]&&map[target][GW_Math.toIndex(pos.x-1, pos.y + 1, 255)][mtype] == o) {
					floodFill(GW_Math.toIndex(pos.x-1, pos.y + 1, 255), w, target, type, o);
				}
				//below right
				if (map[target][GW_Math.toIndex(pos.x+1, pos.y + 1, 255)]&&map[target][GW_Math.toIndex(pos.x+1, pos.y + 1, 255)][mtype] == o) {
					floodFill(GW_Math.toIndex(pos.x+1, pos.y + 1, 255), w, target, type, o);
				}
			}
			else {
				if (type == SELECT_PALETTE) {
					return;
				}
				map[target][at] = [];
				map[target][at][M_HFLIP] = hflipped;
				map[target][at][M_VFLIP] = vflipped;
				map[target][at][M_TRANS] = transtoggle;
				map[target][at][M_PALETTE] = data[w][D_PALETTE];
				map[target][at][M_TILE] = w;
				
				//above
				if (!map[target][GW_Math.toIndex(pos.x, pos.y - 1, 255)]) {
					floodFill(GW_Math.toIndex(pos.x, pos.y - 1, 255), w, target, type, o);
				}
				//below
				if (!map[target][GW_Math.toIndex(pos.x, pos.y + 1, 255)]) {
					floodFill(GW_Math.toIndex(pos.x, pos.y + 1, 255), w, target, type, o);
				}
				//left
				if (!map[target][GW_Math.toIndex(pos.x - 1, pos.y, 255)]) {
					floodFill(GW_Math.toIndex(pos.x - 1, pos.y, 255), w, target, type, o);
				}
				//right
				if (!map[target][GW_Math.toIndex(pos.x + 1, pos.y, 255)]) {
					floodFill(GW_Math.toIndex(pos.x + 1, pos.y, 255), w, target, type, o);
				}
				if (strict) {
					return;
				}
				//above left
				if (!map[target][GW_Math.toIndex(pos.x-1, pos.y - 1, 255)]) {
					floodFill(GW_Math.toIndex(pos.x-1, pos.y - 1, 255), w, target, type, o);
				}
				//above right
				if (!map[target][GW_Math.toIndex(pos.x+1, pos.y - 1, 255)]) {
					floodFill(GW_Math.toIndex(pos.x+1, pos.y - 1, 255), w, target, type, o);
				}
				//below left
				if (!map[target][GW_Math.toIndex(pos.x-1, pos.y + 1, 255)]) {
					floodFill(GW_Math.toIndex(pos.x-1, pos.y + 1, 255), w, target, type, o);
				}
				//below right
				if (!map[target][GW_Math.toIndex(pos.x+1, pos.y + 1, 255)]) {
					floodFill(GW_Math.toIndex(pos.x+1, pos.y + 1, 255), w, target, type, o);
				}
			}
		}
		private function findMapSize():Point {
			var r:Point = new Point();
			var m:uint = 0;
			while (m < map.length) {
				var i:uint = 0;
				while (i < map[m].length) {
					if (map[m][i]) {
						if (i % 255 > r.x) {
							r.x = i%255;
						}
						if (i / 255 > r.y) {
							r.y = uint(i / 255);
						}
					}
					i++;
				}
				m++;
			}
			return r;
		}
		private function mapToString():String {
			var dim:Point = findMapSize();
			if (dim.x < 15) {
				dim.x = 15;
			}
			if (dim.y < 15) {
				dim.y = 15;
			}
			var s:String = "";
			var m:uint = 0;
			while (m < map.length) {
				var y:uint = 0;
				while (y <= dim.y) {
					var x:uint = 0;
					while (x <= dim.x) {
						if (map[m][y * 255 + x]) {
							var cur:Array = map[m][y * 255 + x]; 
							s = s + uint(cur[M_TILE]).toString();
							if (cur[M_HFLIP]) {
								s = s + "h";
							}
							if (cur[M_VFLIP]) {
								s = s + "v";
							}
							if (cur[M_TRANS]) {
								s = s + "t";
							}
							s = s + "|" + cur[M_PALETTE];
						}
						else {
							s = s + "0|0";
						}
						s = s + ",";
						x++;
					}
					s = s + "\n";//TODO: DIS BROKE. FIGURE OUT WHY IT BROKE THE IMPORTER.
					y++;
				}
				if (m != 3) {
					s = s + "---\n";
				}
				m++;
			}
			return s;
		}
		private function combinePalettes(a:uint, b:uint):uint {
			trace("Combining palette #" + a + "[" + palettes[a] + "] and palette #" + b + "[" + palettes[b] + "]...");
			var c:Array = palettes[a].concat(palettes[b]);
			c.sort(Array.NUMERIC);
			var i:uint = 0;
			trace("Result: ["+c+"], now trimming...");
			while (i < c.length-1) {
				if (c[i] == c[i + 1]) {
					c.splice(i, 1);
					i = 0;
				}
				else {
					i++;
				}
			}
			trace("Trimmed! Result: [" + c + "]");
			palettes.push(c);
			var result:uint = palettes.length - 1;
			i = 0;
			trace("Remapping affected tiles...");
			while (i < data.length) {
				if (data[i][D_PALETTE] == a) {
					remapTile(i, a, result);
					data[i][D_PALETTE] = result;
				}
				else if (data[i][D_PALETTE] == b) {
					remapTile(i, b, result);
					data[i][D_PALETTE] = result;
				}
				i++;
			}
			i = 0;
			var j:uint;
			while (i < 3) {
				j = 0;
				while (j < map[i].length) {
					if (map[i][j]) {
						if (map[i][j][M_PALETTE] == a || map[i][j][M_PALETTE] == b) {
							map[i][j][M_PALETTE] = result;
						}
					}
					j++;
				}
				i++;
			}
			var rep:Array = [a, b];
			rep.sort(Array.NUMERIC);
			i = rep.length;
			var k:uint;
			while (i-- > 0) {
				palettes.splice(rep[i], 1);
				j = 0;
				while (j < data.length) {
					if (data[j][D_PALETTE] >= rep[i]) {
						data[j][D_PALETTE] = data[j][D_PALETTE] - 1;
					}
					j++;
				}
				k = 0;
				while (k < 3) {
					j = 0;
					while (j < map[k].length) {
						if(map[k][j]){
							if (map[k][j][M_PALETTE] >= rep[i]) {
								map[k][j][M_PALETTE] = map[k][j][M_PALETTE] - 1;
							}
						}
						j++;
					}
					k++;
				}
			}
			i = 0;
			while (i < palettes.length) {
				while (palettes[i].length > 8) {
					palettes[i].pop();
				}
				i++;
			}
			i = 0;
			while (i < 3) {
				renderMap(i);
				i++;
			}
			renderPaletteList();
			renderTileList();
			return result-2;
		}
		/**
		 * Remaps the tile map given from the colours at an old palette index to a new one
		 * @param	tile	tile index
		 * @param	from	current palette that it's mapped to
		 * @param	to		new palette to map [must contain the same colours at least as a subset]
		 * @return
		 */
		private function remapTile(tile:uint, from:uint, to:uint):void {
			var i:uint = 0;
			while (i < data[tile][D_IMAGE].length) {
				var oldpal:Array = palettes[from];
				var newpal:Array = palettes[to]
				//trace("Old value: " + data[tile][D_IMAGE][i] + ", [" + oldpal + "]");
				//trace("New value: " + newpal.indexOf(oldpal[data[tile][D_IMAGE][i]])+", ["+newpal+"]");
				data[tile][D_IMAGE][i] = newpal.indexOf(oldpal[data[tile][D_IMAGE][i]]);
				i++;
			}
		}
		private function remapColourChannel(tile:uint, from:uint, to:uint):void {
			if (!data[tile]) {
				return;
			}
			var i:uint = 0;
			while (i < 16 * 16) {
				if (data[tile][D_IMAGE][i] == from) {
					data[tile][D_IMAGE][i] = to;
				}
				i++;
			}
		}
		private function swapColourChannels(tile:uint, a:uint, b:uint):void {
			//trace("Swapping colour channels " + a + " and " + b + " on tile #" + tile + "...");
			if (!data[tile]) {
				//trace("Tile not found - aborting.");
				return;
			}
			var i:uint = 0;
			while (i < 16 * 16) {
				if (data[tile][D_IMAGE][i] == a) {
					//trace("Remapping " + (i % 16) + "," + (i / 16) + " (a->b)");
					data[tile][D_IMAGE][i] = b;
				}
				else if (data[tile][D_IMAGE][i] == b) {
					//trace("Remapping " + (i % 16) + "," + (i / 16) + " (b->a)");
					data[tile][D_IMAGE][i] = a;
				}
				i++;
			}
		}
		private function dumpVisualData():void {
			var i:uint = 0;
			var j:uint = 0;
			var s:String = "";
			i = 0;
			while (i < palettes.length) {
				trace("Palette #" + i + " - [" + palettes[i] + "]");
				i++;
			}
			
			i = 0;
			while (i < data.length) {
				trace("Tile #" + i + ": \n	palette=" + data[i][D_PALETTE] + "\n	Data=\n");
				j = 0;
				s = "";
				while (j < data[i][D_IMAGE].length) {
					if (j && !(j % 16)) {
						s = s + "\n";
					}
					s = s + data[i][D_IMAGE][j] + " ";
					j++;
				}
				trace(s+"---------\n");
				i++;
			}
		}
		private function getIndex(target:uint, x:Number, y:Number):uint {
			switch(target) {
				case HL_TILE:
					return Math.floor((x - tilelist.x + tileScroll * 2) / 32);
				break;
				case HL_PALETTE:
					return Math.floor((y - palettelist.y + paletteScroll)/10);
				break;
				case HL_WORLDSQUARE:
					return Math.floor((y - worldmap.y + mapScrollY) / 16) * 255 + Math.floor((x - worldmap.x + mapScrollX) / 16);
				break;
				case HL_PALEDIT:
					return Math.floor((x - paletteedit.x) / 16);
				break;
				case HL_TILEEDIT:
					return Math.floor((y - tileedit.y) / 8) * 16 + Math.floor((x - tileedit.x) / 8);
				break;
			}
			
			return 0;
		}
		
		//undo/redo management
		private function ArrayCopy(value:*):* {
			var ba:ByteArray = new ByteArray();
			ba.writeObject(value);
			ba.position = 0;
			return ba.readObject();
		}
		
		private function addUndoLevel():void {
			//undo.splice(undo_pos, undo.length, [data, palettes, map]);
			undo.push([ArrayCopy(data), ArrayCopy(palettes), ArrayCopy(map)]);
			//undo_pos++;
			/*var i:uint = 0;
			trace("\n\nUndo array...........");
			while (i < undo.length) {
				trace(">>>>>>LV" + i + ":\ndata:" + undo[i][0] + "\npal:" + undo[i][1] + "\nmap:" + undo[i][2]);
				i++;
			}*/
		}
		
		private function doUndo():void {
			/*if (undo_pos > 0) {
				undo_pos--;
				clearSelection();
				data = undo[undo_pos][0];
				palettes = undo[undo_pos][1];
				map = undo[undo_pos][2];
				renderAll();
			}*/
			if (!undo.length) {
				return;
			}
			var temp:Array = undo.pop();
			//clearSelection();
			data = temp[0];
			palettes = temp[1];
			map = temp[2];
			renderAll();
		}
		private function doRedo():void {
			return;
			if (undo_pos < undo.length - 1) {
				undo_pos++;
				clearSubSelection();
				data = undo[undo_pos][0];
				palettes = undo[undo_pos][1];
				map = undo[undo_pos][2];
				renderAll();
			}
		}
		
		private function frameHandler(e:Event = null):void {
			/*if (colorpicker.getRect(stage).contains(mouseX, mouseY)) {
				info.text = StringManip.pad(i_picker.getPixel(stage.mouseX-colorpicker.x, stage.mouseY-colorpicker.y).toString(2), "0", 24, true, true, 8);
			}*/
			var i:uint = 0;
			if(data.length*16>i_tile_list_window.width){
				if (tileScroll > data.length*16 - i_tile_list_window.width) {
					tileScroll = data.length*16 - i_tile_list_window.width;
				}
				else if (tileScroll < 0) {
					tileScroll = 0;
				}
			}
			else {
				tileScroll = 0;
			}
			i_tile_list_window.copyPixels(i_tile_list, new Rectangle(tileScroll, 0, i_tile_list_window.width, 16), new Point() );
			
			if(palettes.length*10>i_palette_list_window.height){
				if (paletteScroll > palettes.length*10 - i_palette_list_window.height) {
					paletteScroll = palettes.length*10 - i_palette_list_window.height;
				}
				else if (paletteScroll < 0) {
					paletteScroll = 0;
				}
			}
			else {
				paletteScroll = 0;
			}
			i_palette_list_window.copyPixels(i_palette_list, new Rectangle(0, paletteScroll, i_palette_list_window.width, i_palette_list_window.height), new Point() );
			
			if (mapScrollX < 0) {
				mapScrollX = 0;
			}
			else if (mapScrollX + i_world_map_window.width > 4080) {
				mapScrollX = mapScrollX - i_world_map_window.width;
			}
			if (mapScrollY < 0) {
				mapScrollY = 0;
			}
			else if (mapScrollY + i_world_map_window.height > 4800) {
				mapScrollY = 4080 - i_world_map_window.height;
			}
			i_world_map_window.fillRect(i_world_map_window.rect, 0);
			i = 0;
			while (i < i_world_map.length) {
				if (map_visible[i]) {
					i_world_map_window.copyPixels(i_world_map[i], new Rectangle(mapScrollX, mapScrollY, i_world_map_window.width, i_world_map_window.height), new Point(), null, null, true);
				}
				i++
			}
			
			//tile_highlight.clear();
			//palette_highlight.clear();
			//worldmap_highlight.clear();
			hl.clear();
			switch(selectiontype) {
				case SELECT_NONE:
				
				break;
				case SELECT_PALETTE:
					if (!palettes[selected[0]]) {
						clearSelection();
						return;
					}
					highlight(HL_PALETTE, selected[0], 0x0000FF);
					i = 0;
					while (i < data.length) {
						if (data[i][D_PALETTE] == selected[0]) {
							highlight(HL_TILE, i, 0x00FFFF);
						}
						i++;
					}
					if (toolmode == T_COMBINE) {
						i = 0;
						while (i < related.length) {
							highlight(HL_PALETTE, related[i], 0xFFAAAA);
							i++;
						}
					}
				break;
				case SELECT_TILE:
					if (!data[selected[0]]) {
						clearSelection();
						return;
					}
					highlight(HL_TILE, selected[0], 0x00FF00);
					highlight(HL_PALETTE, data[selected[0]][D_PALETTE], 0x00FFFF);
				break;
				case SELECT_WORLD_SQUARE:
					if (!map[current_map][selected[0]]) {
						clearSelection();
						return;
					}
					highlight(HL_WORLDSQUARE, selected[0], 0xFF00);
					highlight(HL_PALETTE, map[current_map][selected[0]][M_PALETTE], 0x00FFFF);
					highlight(HL_TILE, map[current_map][selected[0]][M_TILE], 0x00FFFF);
				break;
			}
			switch(subselectiontype) {
				case SUB_SELECT_P_EDIT:
					highlight(HL_PALEDIT, selected[1], 0x00FF00);
				break;
				case SUB_SELECT_T_EDIT:
					highlight(HL_TILEEDIT, selected[1], 0x00FF00);
				break;
			}
			
			if (subselectiontype == SUB_SELECT_P_EDIT) {
				colorpicker.x = paletteedit.x - colorpicker.width - 3;
				colorpicker.y = paletteedit.y - 3;
				colorpicker.visible = true;
			}
			else {
				colorpicker.x = 4000;
				colorpicker.visible = false;
			}
			
			if (worldmap.getRect(stage).containsPoint(new Point(mouseX, mouseY))) {
				highlight(HL_WORLDSQUARE, getIndex(HL_WORLDSQUARE, mouseX, mouseY)); 
			}
			if (tilelist.getRect(stage).containsPoint(new Point(mouseX, mouseY))) {
				highlight(HL_TILE, getIndex(HL_TILE, mouseX, mouseY));
			}
			if (palettelist.getRect(stage).containsPoint(new Point(mouseX, mouseY))) {
				highlight(HL_PALETTE, getIndex(HL_PALETTE, mouseX, mouseY));
			}
			if (paletteedit.getRect(stage).containsPoint(new Point(mouseX, mouseY))) {
				highlight(HL_PALEDIT, getIndex(HL_PALEDIT, mouseX, mouseY));
			}
			if (tileedit.getRect(stage).containsPoint(new Point(mouseX, mouseY))) {
				highlight(HL_TILEEDIT, getIndex(HL_TILEEDIT, mouseX, mouseY));
			}
		}
	}
}