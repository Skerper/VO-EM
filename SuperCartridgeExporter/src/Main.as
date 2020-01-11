package 
{
	import com.adobe.images.PNGEncoder;
	import com.gui.Button;
	import com.memory.ParticleScape;
	import com.memory.StringManip;
	import emu.hardware.cpu.CPU;
	import emu.hardware.mainboard.MoBo_01;
	import emu.helpers.CartLoader
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.ByteArray;
	import emu.hardware.memory.BA_RAM
	import emu.hardware.memory.cart.Cart01;
	
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class Main extends Sprite 
	{
		private var btn_load:Button = new Button("Load .dlx", 10, 10);
		private var btn_export:Button = new Button("Export .png", 95, 10);
		private var btn_load_label:Button = new Button("Load Label", 180, 10); 
		private var output:BitmapData;
		
		private var cart:BA_RAM;
		private var label_img:BitmapData;
		private var dummycpu:CPU;
		private var startpoint:uint = 0;
		
		private var file:FileReference;
		private var fileLoader:Loader;
		
		private var txt_name:TextField = new TextField();
		private var txt_auth:TextField = new TextField();
		private var txt_cart:TextField = new TextField();
		private var txt_conf:TextField = new TextField();
		
		
		//offsets
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			buildInfoSquareData("2DOF CHAR DEMO ", "ELLIOTT SMITH  ", 0, 0, "16-6-2016");  
			output = new BitmapData(500, 200, true, 0);
			dummycpu = new CPU(new MoBo_01(this.stage));
			var op_holder:Bitmap = new Bitmap(output);
			this.addChild(op_holder);
			op_holder.x = 10;
			op_holder.y = 100;
			var g:Graphics = this.graphics;
			g.beginFill(0x333344);
			g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			g.endFill();
			g.lineStyle(1, 0x777777);
			var i:uint = 0;
			while (i < stage.stageWidth) {
				g.moveTo(i, 0);
				g.lineTo(i, stage.stageHeight);
				if(i<stage.stageHeight){
					g.moveTo(0,i);
					g.lineTo(stage.stageWidth, i);
				}
				i += 20;
			}
			this.label_img = new BitmapData(Cart01.os_label.width, Cart01.os_label.height, true, 0xFFFFFFFF);
			
			
			this.cart = new BA_RAM(0, 0x4000 * Cart01.BANKS.length);
			
			txt_auth.x = txt_cart.x = txt_conf.x = txt_name.x = 600;
			txt_auth.height = txt_cart.height = txt_conf.height = txt_name.height = 20;
			
			txt_name.y = 100;
			txt_auth.y = 130;
			txt_cart.y = 160;
			txt_conf.y = 190;
			
			this.addChild(txt_name);
			this.addChild(txt_auth);
			this.addChild(txt_cart);
			this.addChild(txt_conf);
			
			txt_name.text = "NAME";
			txt_auth.text = "ANON";
			txt_cart.text = "0";
			txt_conf.text = "0";
			
			txt_auth.background = txt_conf.background = txt_name.background = txt_cart.background = true;
			
			
			txt_auth.type = txt_name.type = txt_cart.type = txt_conf.type = TextFieldType.INPUT
			
			
			
			this.addChild(btn_load);
			this.addChild(btn_export);
			this.addChild(btn_load_label);
			btn_load.addEventListener(MouseEvent.CLICK, e_load_dlx);
			btn_export.addEventListener(MouseEvent.CLICK, e_export_png);
			btn_load_label.addEventListener(MouseEvent.CLICK, e_load_label);
		}
		
		private function e_load_dlx(e:Event = null):void {
			file = new FileReference();
			file.addEventListener(Event.SELECT, e_load_dlx_selected);
			file.browse([new FileFilter("DLX executable file (*.dlx)", "*.dlx")]);
		}
		
		private function e_load_dlx_selected(e:Event = null):void {
			file.addEventListener(Event.COMPLETE, e_load_dlx_loaded);
			file.load();
		}
		
		private function e_load_dlx_loaded(e:Event = null):void {
			var fileReference:FileReference = e.target as FileReference;
			var tdatsd:ByteArray = fileReference["data"];
			var tdats:String = tdatsd.toString();
			CartLoader.loadCart(cart, tdats, dummycpu);
			startpoint = dummycpu.PC;
			trace(startpoint);
			drawCart();
		}
		
		private function e_export_png(e:Event = null):void {
			file = new FileReference();
			file.save(PNGEncoder.encode(output), ".png");
		}
		
		private function e_load_label(e:Event = null):void {
			file = new FileReference();
			file.addEventListener(Event.SELECT, e_label_selected);
			file.browse([new FileFilter("PNG image", "*.png")]);
		}	
		private function e_label_selected(e:Event = null):void {
			file.addEventListener(Event.COMPLETE, e_label_loaded);
			file.load();
		}		
		private function e_label_loaded(e:Event = null):void {
			fileLoader = new Loader();
 
			fileLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_parse_label_data);
			fileLoader.loadBytes(file.data);
			
		}
		private function e_parse_label_data(e:Event = null):void {
			label_img = new BitmapData(fileLoader.width, fileLoader.height, true, 0);
			label_img.draw(fileLoader);
			drawCart();
		}
		
		private function drawCart():void {
			var t:Sprite = new Sprite()
			var g:Graphics = t.graphics;
			g.beginFill(0x999999, 1);
			g.drawRect(0, 0, 500, 200);
			g.endFill();
			
			output.fillRect(output.rect, 0);
			output.draw(t);
			
		
			
			var i:uint = 0;
			var j:uint = 0;
			while (i < Cart01.BANKS.length) {
				output.fillRect(Cart01.BANKS[i], Cart01.BANK_OPACITY);
				j -= j % 0x4000;
				trace("Bank" + i + " offset: " + j.toString(16));
				
				while (j < (i+1) * 0x4000) {
					var c:uint = 0xFF000000;// Cart01.BANK_OPACITY;
					//c += Math.floor(Math.random() * Cart01.SHIMMER) << 24;
					//c -= Math.floor(Math.random() * Cart01.SHIMMER) << 24;
					c = c|(cart.read(j) << 16) | (cart.read(j + 1) << 8) | cart.read(j + 2);
							
					output.setPixel32(Cart01.BANKS[i].x + (((j%0x4000)/3) % 75), Cart01.BANKS[i].y + (((j%0x4000)/3) / 75), c);
					
					j += 3;
				}
				i++;
			}
			
			i = 0;
			while (i < Cart01.os_savedata.width * Cart01.os_savedata.height) {
				c = 0xFF000000; Cart01.BANK_OPACITY;
				//c += Math.floor(Math.random() * Cart01.SHIMMER) << 24;
				//c -= Math.floor(Math.random() * Cart01.SHIMMER) << 24;
				output.setPixel32(Cart01.os_savedata.x + i % Cart01.os_savedata.width, Cart01.os_savedata.y + i / Cart01.os_savedata.width, c);
				i++;
			}
			var te:BitmapData = new BitmapData(Cart01.os_label.width, Cart01.os_label.height, true, 0);
			te.copyPixels(label_img, new Rectangle(0, 0, Cart01.os_label.width, Cart01.os_label.height), new Point());
			te.fillRect(Cart01.os_label_bite, 0);
			
			output.copyPixels(te, new Rectangle(0, 0, Cart01.os_label.width, Cart01.os_label.height), new Point(Cart01.os_label.x, Cart01.os_label.y), null, null, true);
			
			var inf:ByteArray = buildInfoSquareData(txt_name.text, txt_auth.text, parseInt(txt_cart.text, 10), parseInt(txt_conf.text, 10));
			inf.position = 0;
			i = 0;
			while (i < 25 * 25 * 3) {
				c = 0xFF000000;// Cart01.BANK_OPACITY;
				//c += Math.floor(Math.random() * Cart01.SHIMMER) << 24;
				//c -= Math.floor(Math.random() * Cart01.SHIMMER) << 24;
				if (i < inf.length) {
					c = c | (inf.readByte() << 16) | (inf.readByte() << 8)|inf.readByte();
				}
				output.setPixel32((i/3) % Cart01.os_info.width, (i/3) / Cart01.os_info.width, c);
				i+=3;
			}
		}
		
		
		private const SIG_STR:String = "VO-EM";
		private function buildInfoSquareData(name:String = "UNTITLED", author:String = "ANONYMOUS", cart:uint = 0, conf:uint = 0, date:String = null ):ByteArray {
			cart = cart & 0xFF;
			conf = conf & 0xFF;
			
			var t:ByteArray = new ByteArray();
			var i:uint = 0;
			while (i < SIG_STR.length) {
				t.writeByte(SIG_STR.charCodeAt(i));
				i++;
			}
			t.writeByte(0);
			t.writeUnsignedInt((cart << 16) | conf);
			i = 0;
			if (!date) {
				date = "??-??-????";
			}
			i = 0;
			while (i < 9) {
				t.writeByte(date.charCodeAt(i));
				i++;
			}
			t.writeByte(0);
			i = 0;
			while (i < 15) {
				if (i < name.length) {
					t.writeByte(name.charCodeAt(i));
				}
				else {
					t.writeByte(0);
				}
				i++;
			}
			t.writeByte(0);
			i = 0;
			while (i < 15) {
				if (i < author.length) {
					t.writeByte(author.charCodeAt(i));
				}
				else {
					t.writeByte(0);
				}
				i++;
			}
			t.writeByte(0);
			t.writeUnsignedInt(startpoint);
			
			while (t.length % 3) {
				t.writeByte(0);
			}
			
			t.position = 0;
			var test:String = "";
			while (t.position < t.length) {
				test = test + " " + StringManip.pad(t.readByte().toString(16), "0", 2);
				if (!(t.position % 16)) {
					test = test + "\n";
				}
			}
			
			trace(test);
			return t;
		}
		
	}
	
}