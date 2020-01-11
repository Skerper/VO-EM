package emu.hardware.mainboard 
{
	import com.debug.Console;
	import emu.hardware.clock.TIMA;
	import emu.hardware.cpu.CPU;
	import emu.hardware.display.DisplayAdaptor;
	import emu.hardware.gpu.GPUECO;
	import emu.hardware.input.GamePad;
	import emu.hardware.memory.BA_RAM;
	import emu.hardware.memory.cart.Cart01;
	import emu.hardware.memory.ROM;
	import emu.hardware.NullDevice;
	import emu.helpers.CartLoader;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import emu.hardware.proto_Device;
	import emu.hardware.mainboard.proto_Motherboard;
	import emu.hardware.display.Display;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class MoBo_01 extends proto_Motherboard
	{
		
		public var gpu:GPUECO;
		public var lram:BA_RAM;
		public var sram:BA_RAM;
		private var world:Stage;
		private var oblivion:NullDevice;
		private var keypad:GamePad;
		private var tima:TIMA;
		public var dispAdaptor:DisplayAdaptor;
		public var bios:ROM;
		public var exph_memory:ROM;
		public var debugticks:uint = 0;
		public var restartsafe:Boolean = true;
		
		//////////////////////////
		//embeds//////////////////

		[Embed(source = "../CMOS/01MemExComb.dlx", mimeType = "application/octet-stream")]
		private var cmos_exphc:Class;
		public var cmos_exph:String = new cmos_exphc()
		
		public function MoBo_01(stage:Stage) 
		{
			super(stage);
			this.world = stage;
			this.gpu = new GPUECO(0x10000, this);
			this.dispAdaptor = new DisplayAdaptor(0x30000, this);
			this.display = new Display(gpu.output, gpu.glowlayerimages);
			dispAdaptor.hook(display.overlay);

		}
		
		override public function start(cart:Array):void {
			this.cpu = new CPU(this);
			this.cartridge = new Cart01(0, this);
			this.sram = new BA_RAM(0x8000, 0x7FFF);
			this.lram = new BA_RAM(0x20000, 0xFFFF);
			this.clock = new Timer(1);
			this.oblivion = new NullDevice();
			this.keypad = new GamePad(0xFFFFFF00, this);
			this.exph_memory = new ROM(0x0, 0x7FFF);
			this.tima = new TIMA(0xFFFFFF04, this);
			keypad.hook(world);
			dispAdaptor.blank();
		
			super.start(cart);
			CartLoader.loadCart(exph_memory, cmos_exph);
			exph_memory.lock();
			//CartLoader.loadCart(cartridge, cart, cpu);
			cpu.init();
			cartridge.loadData(cart);
			var i:uint = 0;
			var sign:Array = [0x56, 0x4F, 0x2D, 0x45, 0x4D];
			while (i < sign.length) {
				if (cartridge.info.read(i) != sign[i]) {
					trace(cartridge.info.read(i), sign[i]);
					Console.out("Invalid cartridge inserted.");
					return;
				}
				i++;
			}
			var infostr:String = "Cartridge info:\nDate:   ";
			i = 10;
			while (i < 20) {
				if(cartridge.info.read(i)){
					infostr = infostr + String.fromCharCode(cartridge.info.read(i));
				}
				i++;
			}
			infostr = infostr+"\nTitle:  ";
			i = 20;
			while (i < 36) {
				if(cartridge.info.read(i)){
					infostr = infostr + String.fromCharCode(cartridge.info.read(i));
				}
				i++;
			}
			infostr = infostr+"\nAuthor: ";
			i = 36;
			while (i < 52) {
				if(cartridge.info.read(i)){
					infostr = infostr + String.fromCharCode(cartridge.info.read(i));
				}
				i++;
			}
			Console.out(infostr);
			trace(infostr)
			
			//ROM(cartridge).lock();
			//trace("Bios dump:",bios.dump(50));
			
			//trace(memory.dump(0x0AAA, 0, 0x8));
			this.selectTarget = selectTargetRegular;
			
			cpu.setPC(cartridge.info.readWord(0x34));
			//this.selectTarget = selectTargetMemEx;
			//cpu.setPC(0);
			//this.clock.addEventListener(TimerEvent.TIMER, cpu.cycle);
			//world.addEventListener(Event.ENTER_FRAME, gpu.refresh);
			//clock.start();
		}
		
		override public function tick(e:Event = null):void {
			var i:uint = 0;
			
			if (!(tickcount & 0x1)) {
				if (cpu.paused) { return };
				cpu.cycle(200);
				while (i < 45) {
					if (cpu.paused) { return };
					cpu.cycle(16)
					gpu.DMAtransfer(); 
					i++;
				}
				
				i = 0;
				while (i < 280 / 8) {
					if (cpu.paused) { return };
					cpu.cycle(8);
					gpu.HorizontalBlank();
					i++;
				}
			}
			else {
				while (i < 125) {
					if (cpu.paused) { return };
					cpu.cycle(8);
					gpu.HorizontalBlank();
					i++;
				}
				if (cpu.paused) { return };
				gpu.refresh();
				dispAdaptor.refresh();
				cpu.cycle(200);
			}
			super.tick();
		}
		
		override public function debugTick(e:Event = null):void {
			//trace("Debugging: " + debugticks + ", CPU wait status: " + cpu.wait.toString()+", FLIP: "+(tickcount&0x1));
			
			if (!(tickcount & 0x1)) {
				//trace("First half...");
				if(debugticks<200){
					cpu.cycle();
					if (cpu.wait) {
						//trace("CPU bored, setting to 200");
						debugticks = 200;
						return;
					}
				}
				else if (debugticks < 920) {
					cpu.cycle()
					if (cpu.wait) {
						debugticks += 16 - ((debugticks - 200) % 16);
						//trace("CPU bored, setting to "+debugticks);
					}
					if(!((debugticks-200)%16)){
						gpu.DMAtransfer(); 
						//trace("DMA transfer...");
						//debugticks++;
						//return;
					}
				}
				else if (debugticks < 280+920) {
					cpu.cycle();
					if (cpu.wait) {
						debugticks += 8 - ((debugticks - 920) % 8);
						//trace("CPU bored, setting to "+debugticks);
					}
					if(!((debugticks-920)%8)){
						gpu.HorizontalBlank();
						//trace("Horizontal blank...");
						//debugticks++;
						//return;
					}
				}
			}
			else {
				//trace("Second half...");
				if (debugticks < 2200) {
					cpu.cycle();
					if (cpu.wait) {
						debugticks += 8 - ((debugticks - 1200) % 8);
						//trace("CPU bored, setting to "+debugticks);
					}
					if(!((debugticks-1200)%8)){
						gpu.HorizontalBlank();
						//trace("Horizontal blank...");
						//return;
					}
					
				}
				else if(debugticks<2400){
					cpu.cycle();
					if (cpu.wait) {
						debugticks = 2400;
						//trace("CPU bored, setting to "+debugticks);
						//return;
					}
				}
				if(debugticks==2200){
					gpu.refresh();
					dispAdaptor.refresh();
					//trace("Vertical blank...");
				}
			}
			restartsafe = false;
			if (debugticks == 1200) {
				restartsafe = true;
				super.debugTick();
			}
			if (debugticks == 2400) {
				debugticks = 0;
				restartsafe = true;
				super.debugTick();
			}
			debugticks++;
			//super.debugTick();
		}
		
		/**
		 * Routing for normal operation 
		 * @param	address
		 * @return
		 */
		override public function selectTargetRegular(address:uint):proto_Device {
			if (address <= 0x7FFF) {
				return cartridge;
			}
			if (address<= 0xFFFF) {
				return sram
			}
			if (address <= 0x173FF) {
				return gpu;
			}
			if (address >= 0x20000 && address < 0x30000) {
				return lram;
			}
			if (address >= 0x30000 && address < 0x3A000) {
				return dispAdaptor;
			}
			if (address >= 0xFFFF0000 && address < 0xFFFF06C0) {
				return cartridge.info;
			}
			if (address >= 0xFFFFFF00) {
				if(address < 0xFFFFFF04){
					return keypad;
				}
				if (address < 0xFFFFFF14) {
					return tima;
				}
			}
			cpu.requestInterrupt(0x200); //crash, we're not supposed to be here.
			return oblivion;
		}
		
		override public function selectTargetUnsafe(address:uint):proto_Device {
			if (address <= 0x7FFF) {
				return cartridge;
			}
			if (address<= 0xFFFF) {
				return sram
			}
			if (address <= 0x173FF) {
				return gpu;
			}
			if (address >= 0x20000 && address < 0x30000) {
				return lram;
			}
			if (address >= 0x30000 && address < 0x3A000) {
				return dispAdaptor;
			}
			if (address >= 0xFFFF0000 && address < 0xFFFF06C0) {
				return cartridge.info;
			}
			if (address >= 0xFFFFFF00) {
				if(address < 0xFFFFFF04){
					return keypad;
				}
				if (address < 0xFFFFFF14) {
					return tima;
				}
			}
			
			return oblivion;
		}
		
		public function selectTargetExph(address:uint):proto_Device {
			if (address <= 0x7FFF) {
				return exph_memory;
			}
			if (address<= 0xFFFF) {
				return sram
			}
			if (address <= 0x173FF) {
				return gpu;
			}
			if (address >= 0x20000 && address < 0x30000) {
				return lram;
			}
			if (address >= 0x30000 && address < 0x3A000) {
				return dispAdaptor;
			}
			if (address >= 0xFFFF0000 && address < 0xFFFF06C0) {
				return cartridge.info;
			}
			if (address >= 0xFFFFFF00) {
				if(address < 0xFFFFFF04){
					return keypad;
				}
				if (address < 0xFFFFFF14) {
					return tima;
				}
			}
			return oblivion;
		
		}
		
		public static const TARGET_REGULAR:uint = 0;
		public static const TARGET_EXP:uint = 1;
		override public function switchTargetSelector(index:uint):void {
			switch(index) {
				case TARGET_REGULAR:
					selectTarget = selectTargetRegular;
				break;
				case TARGET_EXP:
					selectTarget = selectTargetExph;
				break;
			}
		}
		
		
		override public function reset():void {
			sram = new BA_RAM(0x8000, 0x7FFF);
			lram = new BA_RAM(0x20000, 0xFFFF);
			gpu.reset();
			debugticks = 0;
			tickcount = 0;
			cpu.init();
			cpu.setPC(cartridge.info.readWord(0x34));
			super.reset();
		}
	}

}