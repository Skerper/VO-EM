package emu.hardware.input
{
	import com.debug.Console;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import emu.hardware.proto_Device;
	import emu.hardware.mainboard.proto_Motherboard;
	import com.memory.StringManip;
	import com.input.KeyCodes;
	import com.input.KeyPoll;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class GamePad extends proto_Device
	{
		public const OS_HORI:uint = 0;
		public const OS_VERT:uint = 1;
		public const OS_ABBB:uint = 2;
		public const OS_STSL:uint = 3;
		private var value:uint = 0;
		private var irq_value:uint = CTRL_IPR2|CTRL_IEN;
		
		private const MASK32_PADR:uint = parseInt("00000001000000000000000000000000", 2);
		private const MASK32_PADL:uint = parseInt("11111111000000000000000000000000", 2);
		private const MASK32_PADD:uint = parseInt("00000000000000010000000000000000", 2);
		private const MASK32_PADU:uint = parseInt("00000000111111110000000000000000", 2);
		private const MASK32_BUTA:uint = parseInt("00000000000000000000000100000000", 2);
		private const MASK32_BUTB:uint = parseInt("00000000000000000000001000000000", 2);
		private const MASK32_STAR:uint = parseInt("00000000000000000000000000000001", 2);
		private const MASK32_SELE:uint = parseInt("00000000000000000000000000000010", 2);
		
		private const MASK16_PADR:uint = parseInt("0000000100000000", 2);
		private const MASK16_PADL:uint = parseInt("1111111100000000", 2);
		private const MASK16_PADD:uint = parseInt("0000000000000001", 2);
		private const MASK16_PADU:uint = parseInt("0000000011111111", 2);
		private const MASK16_BUTA:uint = parseInt("0000000100000000", 2);
		private const MASK16_BUTB:uint = parseInt("0000001000000000", 2);
		private const MASK16_STAR:uint = parseInt("0000000000000001", 2);
		private const MASK16_SELE:uint = parseInt("0000000000000010", 2);
		
		
		private const MASK8_PADR:uint = parseInt("00000001", 2);
		private const MASK8_PADL:uint = parseInt("11111111", 2);
		private const MASK8_PADD:uint = parseInt("00000001", 2);
		private const MASK8_PADU:uint = parseInt("11111111", 2);
		private const MASK8_BUTA:uint = parseInt("00000001", 2);
		private const MASK8_BUTB:uint = parseInt("00000010", 2);
		private const MASK8_STAR:uint = parseInt("00000001", 2);
		private const MASK8_SELE:uint = parseInt("00000010", 2);
		
		private const K_RIGHT:uint = 0;
		private const K_LEFT:uint = 1;
		private const K_DOWN:uint = 2
		private const K_UP:uint = 3;
		private const K_A:uint = 4;
		private const K_B:uint = 5;
		private const K_START:uint = 6;
		private const K_SELECT:uint = 7;
		
		
		private var Key:KeyPoll;
		
		private var KEY:Array = [	KeyCodes.RIGHT, 
									KeyCodes.LEFT, 
									KeyCodes.DOWN, 
									KeyCodes.UP,
									KeyCodes.Z,
									KeyCodes.X,
									KeyCodes.SPACE,
									KeyCodes.S];
		
		public function GamePad(location:uint = 0x0, bus:proto_Motherboard = null) 
		{
			super(location, bus);
			this.irq_value = CTRL_IPR2|CTRL_IEN;
		}
		
		public function hook(s:Stage):void {
			this.Key = new KeyPoll(s);
			s.addEventListener(KeyboardEvent.KEY_DOWN, KeyHandle);
		}
		
		private function KeyHandle(e:KeyboardEvent):void {
			if (!irq_value) {
				return;
			}
			var i:uint = 0;
			while (i < KEY.length) {
				if (KEY[i] == e.keyCode) {
					IRQ(irq_value);
				}
				i++;
			}
		}
	
		override public function read(from:uint):uint {
			switch(from) {
				case 0:
					return b0();
				break;
				case 1:
					return b1();
				break;
				case 2:
					return b2();
				break;
				case 3:
					return b3();
				break;
			}
			return 0;
		}
		
		override public function readHalf(from:uint):uint {
			if (!from) {
				return (b0() << 8) | b1();
			}
			return (b2() << 8) | b3();
		}
		
		override public function readWord(from:uint):uint {
			return (b3() << 24) | (b2() << 16) | (b1() << 8) | b0();
		}
		
		override public function writeWord(to:uint, values:uint):void {
			this.irq_value = values;
			Console.out("Something wrote to GP");
		}
		
		/**
		 * HORIZONTAL
		 * @return
		 */
		private function b0():uint {
			if (Key.isDown(KEY[K_RIGHT])) {
				return MASK8_PADR;
			}
			else if (Key.isDown(KEY[K_LEFT])) {
				return MASK8_PADL;
			}
			return 0;
		}
		
		/**
		 * VERTICAL
		 * @return
		 */
		private function b1():uint {
			if (Key.isDown(KEY[K_DOWN])) {
				return MASK8_PADD;
			}
			else if (Key.isDown(KEY[K_UP])) {
				return MASK8_PADU;
			}
			return 0;	
		}
		
		/**
		 * AB
		 * @return
		 */
		private function b2():uint {
			var c:uint = 0;
			if (Key.isDown(KEY[K_A])) {
				c = c | MASK8_BUTA;
			}
			if (Key.isDown(KEY[K_B])) {
				c = c | MASK8_BUTB;
			}
			return c;
		}
		
		/**
		 * STARTSELECT
		 * @return
		 */
		private function b3():uint {
			var c:uint = 0;
			if (Key.isDown(KEY[K_START])) {
				c = c | MASK8_STAR;
			}
			if (Key.isDown(KEY[K_SELECT])) {
				c = c | MASK8_SELE;
			}
			return c;
		}
	}

}