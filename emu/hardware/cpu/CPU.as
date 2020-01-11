package emu.hardware.cpu
{
	import com.debug.Console;
	import emu.hardware.mainboard.MoBo_01;
	import flash.events.Event;
	import emu.hardware.mainboard.proto_Motherboard;
	import com.memory.StringManip;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	/**
	 * For now, we're publicing everything for debug purposes.
	 * @author Elliott Smith [voidSkipper]
	 */
	public class CPU
	{
		public var r:Array;
		public var PC:uint = 0;
		public var sr:Array;
		public var IR:uint = 0;
		public var PSW:uint = 1;
		public var XAR:uint = 2;
		public var XBR:uint = 3;
		//public var FPS:uint = 3;
		public var halt:Boolean;
		public var wait:Boolean;
		public var clock:uint = 6;
		
		public var timer_irq:uint = PSW_I0E|0x40;
		public var countdown_irq:uint = PSW_I1E|0x40;
		public var timer_mask:uint = 0xFFFF;
		
		public var IRQQueue:uint; 
		
		public var feswitch:Boolean; //true = fetch, false = execute
		
		private var bus:proto_Motherboard;
		
		public var tick:uint = 0;
		public var countdown:uint = 0x3000;
		/**
		 * OPCODE constants follow
		 */
		//These are 0x branch opcodes
		private const BRANCH_ALU:uint = 0x0;
		private const OP_ADD:uint = 	bin("100000");
		private const OP_ADDU:uint =	bin("100001");
		private const OP_AND:uint = 	bin("100100");
		private const OP_HALT:uint = 	bin("000001");
		private const OP_MOVI2S:uint = 	bin("110000");
		private const OP_MOVS2I:uint = 	bin("110001");
		private const OP_NOP:uint = 	bin("000000");
		private const OP_OR:uint = 		bin("100101");
		private const OP_SEQ:uint = 	bin("101000");
		private const OP_SEQU:uint =	bin("010000");
		private const OP_SGE:uint = 	bin("101101");
		private const OP_SGEU:uint = 	bin("010101");
		private const OP_SGT:uint = 	bin("101011");
		private const OP_SGTU:uint = 	bin("010011");
		private const OP_SLA:uint = 	bin("000100");
		private const OP_SLE:uint = 	bin("101100");
		private const OP_SLEU:uint = 	bin("010100");
		private const OP_SLL:uint = 	bin("000100");
		private const OP_SLT:uint = 	bin("101010");
		private const OP_SLTU:uint = 	bin("010010");
		private const OP_SNE:uint = 	bin("101001");
		private const OP_SNEU:uint = 	bin("010001");
		private const OP_SRA:uint = 	bin("000111");
		private const OP_SRL:uint = 	bin("000110");
		private const OP_SUB:uint = 	bin("100010");
		private const OP_SUBU:uint = 	bin("100011");
		private const OP_WAIT:uint = 	bin("000010");
		private const OP_XOR:uint = 	bin("100110");
		//These are high-branch opcodes
		private const OP_ADDI:uint = 	bin("00100000000000000000000000000000");
		private const OP_ADDUI:uint = 	bin("00100100000000000000000000000000");
		private const OP_ANDI:uint = 	bin("00110000000000000000000000000000");
		private const OP_BEQZ:uint = 	bin("00010000000000000000000000000000");
		private const OP_BNEZ:uint = 	bin("00010100000000000000000000000000");
		private const OP_J:uint = 		bin("00001000000000000000000000000000");
		private const OP_JAL:uint = 	bin("00001100000000000000000000000000");
		private const OP_JALR:uint = 	bin("01001100000000000000000000000000");
		private const OP_JR:uint = 		bin("01001000000000000000000000000000");
		private const OP_LB:uint = 		bin("10000000000000000000000000000000");
		private const OP_LBU:uint = 	bin("10010000000000000000000000000000");
		private const OP_LH:uint = 		bin("10000100000000000000000000000000");
		private const OP_LHI:uint = 	bin("00111100000000000000000000000000");
		private const OP_LHU:uint = 	bin("10010100000000000000000000000000");
		private const OP_LW:uint = 		bin("10001100000000000000000000000000");
		private const OP_ORI:uint = 	bin("00110100000000000000000000000000");
		private const OP_RFE:uint = 	bin("01000000000000000000000000000000");
		private const OP_SB:uint = 		bin("10100000000000000000000000000000");
		private const OP_SEQI:uint = 	bin("01100000000000000000000000000000");
		private const OP_SEQUI:uint = 	bin("11000000000000000000000000000000");
		private const OP_SGEI:uint = 	bin("01110100000000000000000000000000");
		private const OP_SGEUI:uint = 	bin("11010100000000000000000000000000");
		private const OP_SGTI:uint = 	bin("01101100000000000000000000000000");
		private const OP_SGTUI:uint = 	bin("11001100000000000000000000000000");
		private const OP_SH:uint = 		bin("10100100000000000000000000000000");
		private const OP_SLAI:uint = 	bin("01010000000000000000000000000000");
		private const OP_SLEI:uint = 	bin("01110000000000000000000000000000");
		private const OP_SLEUI:uint = 	bin("11010000000000000000000000000000");
		private const OP_SLLI:uint = 	bin("01010000000000000000000000000000");
		private const OP_SLTI:uint = 	bin("01101000000000000000000000000000");
		private const OP_SLTUI:uint = 	bin("11001000000000000000000000000000");
		private const OP_SNEI:uint = 	bin("01100100000000000000000000000000");
		private const OP_SNEUI:uint = 	bin("11000100000000000000000000000000");
		private const OP_SRAI:uint = 	bin("01011100000000000000000000000000");
		private const OP_SRLI:uint = 	bin("01011000000000000000000000000000");
		private const OP_SUBI:uint = 	bin("00101000000000000000000000000000");
		private const OP_SUBUI:uint = 	bin("00101100000000000000000000000000");
		private const OP_SW:uint = 		bin("10101100000000000000000000000000");
		private const OP_TRAP:uint = 	bin("01000100000000000000000000000000");
		private const OP_XORI:uint = 	bin("00111000000000000000000000000000"); 
		 
		 
		/////////////////////////
		//interrupt constants etc
		private const PSW_MXE:uint = 	bin("000000000000000000000001");
		private const PSW_UP:uint = 	bin("000000000000000000000100");
		private const PSW_UP_O:uint = 	2;
		private const PSW_U:uint = 		bin("000000000000000000001000");
		private const PSW_FIE:uint = 	bin("000000000000000000010000");
		private const PSW_IIE:uint = 	bin("000000000000000100000000");
		private const PSW_IME:uint = 	bin("000000000000001000000000");
		private const PSW_MPE:uint = 	bin("000000000000010000000000");
		private const PSW_OFE:uint = 	bin("000000000000100000000000");
		private const PSW_FPE:uint = 	bin("000000000001000000000000");
		private const PSW_UTE:uint = 	bin("000000001000000000000000");
		private const PSW_I0E:uint = 	bin("000000010000000000000000");
		private const PSW_I1E:uint = 	bin("000000100000000000000000");
		private const PSW_I2E:uint = 	bin("000001000000000000000000");
		private const PSW_I3E:uint = 	bin("000010000000000000000000");
		private const PSW_I4E:uint = 	bin("000100000000000000000000");
		private const PSW_I5E:uint = 	bin("001000000000000000000000");
		private const PSW_I6E:uint = 	bin("010000000000000000000000");
		private const PSW_I7E:uint = 	bin("100000000000000000000000");
		private const PSW_IXE_M:uint = 	bin("111111111000000000000000");
		private const PSW_TRAP_M:uint = bin("000000000100111110000000");
		private const PSW_MASKS:Array = [PSW_I7E, PSW_I6E, PSW_I5E, PSW_I4E, PSW_I3E, PSW_I2E, PSW_I1E, PSW_I0E, PSW_UTE, PSW_FPE, PSW_OFE, PSW_MPE, PSW_IME, PSW_IIE];
		private const IRQ_MASKS:Array = [PSW_I7E, PSW_I6E, PSW_I5E, PSW_I4E, PSW_I3E, PSW_I2E, PSW_I1E, PSW_I0E];
		private const EXP_MASKS:Array = [PSW_OFE, PSW_MPE, PSW_IME, PSW_IIE];
		private const PSW_MASKS_LENGTH:uint = 14;
		private const IRQ_MASKS_LENGTH:uint = 8;
		private const EXP_MASKS_LENGTH:uint = 4;
		
		{
		public static const PSW_MXE:uint =	parseInt("000000000000000000000001", 2);
		public static const PSW_UP:uint = 	parseInt("000000000000000000000100", 2);
		public static const PSW_UP_O:uint = 	2;
		public static const PSW_U:uint =    parseInt("000000000000000000001000", 2);
		public static const PSW_FIE:uint = 	parseInt("000000000000000000010000", 2);
		public static const PSW_IIE:uint = 	parseInt("000000000000000100000000", 2);
		public static const PSW_IME:uint = 	parseInt("000000000000001000000000", 2);
		public static const PSW_MPE:uint = 	parseInt("000000000000010000000000", 2);
		public static const PSW_OFE:uint = 	parseInt("000000000000100000000000", 2);
		public static const PSW_FPE:uint = 	parseInt("000000000001000000000000", 2);
		public static const PSW_UTE:uint = 	parseInt("000000001000000000000000", 2);
		public static const PSW_I0E:uint = 	parseInt("000000010000000000000000", 2);
		public static const PSW_I1E:uint = 	parseInt("000000100000000000000000", 2);
		public static const PSW_I2E:uint = 	parseInt("000001000000000000000000", 2);
		public static const PSW_I3E:uint = 	parseInt("000010000000000000000000", 2);
		public static const PSW_I4E:uint = 	parseInt("000100000000000000000000", 2);
		public static const PSW_I5E:uint = 	parseInt("001000000000000000000000", 2);
		public static const PSW_I6E:uint = 	parseInt("010000000000000000000000", 2);
		public static const PSW_I7E:uint = 	parseInt("100000000000000000000000", 2);
		public static const PSW_IXE_M:uint = 	parseInt("111111111000000000000000", 2);
		public static const PSW_TRAP_M:uint = 	parseInt("000000000100111110000000", 2);
		}
		//DEBUG CRAP
		
			public var breakpoints:Array = [];
			private var breakpoint_enable:Boolean = false;
			public var paused:Boolean = false;
		{
			public var dumpstr:String = "";
			public var oplabelshighbranch:Array = [["add", bin("100000"), "rk,ri,rj"],
									["addu", bin("100001"), "rk,ri,rj"],
									["and", bin("100100"), "rk,ri,rj"],
									["halt", bin("000001"), ""],
									["movi2s", bin("110000"), ""],
									["movs2i", bin("110001"), ""],
									["nop", bin("000000"), ""],
									["or", bin("100101"), "rk,ri,rj"],
									["seq", bin("101000"), "rk,ri,rj"],
									["sequ", bin("010000"), "rk,ri,rj"],
									["sge", bin("101101"), "rk,ri,rj"],
									["sgeu", bin("010101"), "rk,ri,rj"],
									["sgt", bin("101011"), "rk,ri,rj"],
									["sgtu", bin("010011"), "rk,ri,rj"],
									["sla", bin("000100"), "rk,ri,rj"],
									["sle", bin("101100"), "rk,ri,rj"],
									["sleu", bin("010100"), "rk,ri,rj"],
									["sll", bin("000100"), "rk,ri,rj"],
									["slt", bin("101010"), "rk,ri,rj"],
									["sltu", bin("010010"), "rk,ri,rj"],
									["sne", bin("101001"), "rk,ri,rj"],
									["sneu", bin("010001"), "rk,ri,rj"],
									["sra", bin("000111"), "rk,ri,rj"],
									["srl", bin("000110"), "rk,ri,rj"],
									["sub", bin("100010"), "rk,ri,rj"],
									["subu", bin("100011"), "rk,ri,rj"],
									["wait", bin("000010"), ""],
									["xor", bin("100110")], "rk,ri,rj"]
									
			public var oplabels0x:Array = [["addi", bin("001000"), "rj,ri,ksgn"],
			
									["addui", bin("001001"), "rj,ri,kuns"],
									["andi", bin("001100"), "rj,ri,kuns"],
									["beqz", bin("000100"), "ri,ksgn"],
									["bnez", bin("000101"), "ri,ksgn"],
									["j", bin("000010"), "lsgn"],
									["jal", bin("000011"), "lsgn"],
									["jalr", bin("010011"), "ri"],
									["jr", bin("010010"), "ri"],
									["lb", bin("100000"), "rj,ksgn(ri)"],
									["lbu", bin("100100"), "rj,ksgn(ri)"],
									["lh", bin("100001"), "rj,ksgn(ri)"],
									["lhi", bin("001111"), "rj,kuns"],
									["lhu", bin("100101"), "rj,ksgn(ri)"],
									["lw", bin("100011"), "rj,ksgn(ri)"],
									["ori", bin("001101"), "rj,ri,kuns"],
									["rfe", bin("010000"), ""],
									["sb", bin("101000"), "ksgn(ri),rj"],
									["seqi", bin("011000"), "rj,ri,ksgn"],
									["sequi", bin("110000"), "rj,ri,kuns"],
									["sgei", bin("011101"), "rj,ri,ksgn"],
									["sgeui", bin("110101"), "rj,ri,kuns"],
									["sgti", bin("011011"), "rj,ri,ksgn"],
									["sgtui", bin("110011"), "rj,ri,kuns"],
									["sh", bin("101001"), "ksgn(ri),rj"],
									["slai", bin("010100"), "rj,ri,kuns"],
									["slei", bin("011100"), "rj,ri,ksgn"],
									["sleui", bin("110100"), "rj,ri,kuns"],
									["slli", bin("010100"), "rj,ri,kuns"],
									["slti", bin("011010"), "rj,ri,ksgn"],
									["sltui", bin("110010"), "rj,ri,kuns"],
									["snei", bin("011001"), "rj,ri,ksgn"],
									["sneui", bin("110001"), "rj,ri,kuns"],
									["srai", bin("010111"), "rj,ri,kuns"],
									["srli", bin("010110"), "rj,ri,kuns"],
									["subi", bin("001010"), "rj,ri,ksgn"],
									["subui", bin("001011"), "rj,ri,kuns"],
									["sw", bin("101011"), "ksgn(ri),rj"],
									["trap", bin("010001"), "luns"],
									["xori", bin("001110"), "rj,ri,kuns"]];
		}
		
		public function CPU(bus:proto_Motherboard) 
		{
			this.bus = bus;
			Console.hook(com_breakpoint, "add_breakpoint", "Usage: add_breakpoint [at addr].", false);
			Console.hook(com_breakpoint, "remove_breakpoint", "Usage: remove_breakpoint [at addr].", false);
			Console.hook(com_breakpoint, "breakpoints", "Usage: breakpoints [on/off].", false);
			Console.hook(com_regwrite, "set_register", "Usage: set_register [regnum] [0xVALUE]", false);
			Console.hook(com_regwrite, "set_reg", "Usage: set_register [regnum] [0xVALUE]", false, true);
		}
		
		public function init():void {
			//DEBUG ONLY
			//breakpoints[0x0600] = true;
			////////////
			r = [];
			var i:uint = 0;
			while (i < 32) {
				r[i] = 0;
				i++;
			}
			sr = [0x0, 0x0, 0x0, 0x0];
			halt = false;
			wait = false;
			feswitch = true;
			paused = false;
			IRQQueue = 0x0;
			sr[PSW] = 0;
			//PC = 0;
		}
		
		/**
		 * TODO: Flag settings etc
		 * @param	to
		 * @param	value
		 */
		private function r_write(to:uint, value:uint):void {
			if (!to) { return; }
			r[to] = value;
		}
		
		/**
		 * this is only for static consts to make my life easier
		 * @param	input
		 * @return
		 */
		private function bin(input:String):uint {
			return parseInt(input, 2);
		}
		
		public function cycle(count:uint = 1):void {
			
			//var i:uint = clock;
			while (count > 0) {
				
				if (halt || paused) {
					//trace(count);
					//paused = false;
					return;
				}
				tick++;
				//0x40 is the IEN - it's not defined in CPU. 
				if ((timer_irq & 0x40) && !(tick & timer_mask)) {
					//Console.out("timer irq requested");
					requestInterrupt(timer_irq);
				}
				if (countdown != 0xFFFFFFFF) {
					countdown--;
					if ((countdown_irq & 0x40) && !countdown) {
						//Console.out("countdown irq requested");
						requestInterrupt(countdown_irq);
					}
				}
			//	if (feswitch) {
					//first, check for interrupts
					if (IRQQueue & PSW_TRAP_M) {
						handleException();
					}
					if (IRQQueue&&(sr[PSW]&PSW_MXE)&&(IRQQueue&(sr[PSW]&PSW_IXE_M))) {
						//if we're listening for exceptions AND
						//one or more exceptions enablers are on
						//trace(StringManip.pad(IRQQueue.toString(2), "0", 32));
						handleInterrupt();
						//trace(count);
					}
					if (wait) { 
						while (count) {
							tick++;
							//0x40 is the IEN - it's not defined in CPU. 
							if ((timer_irq & 0x40) && !(tick & timer_mask)) {
								//Console.out("timer irq requested");
								requestInterrupt(timer_irq);
							}
							if (countdown != 0xFFFFFFFF) {
								countdown--;
								if ((countdown_irq & 0x40) && !countdown) {
									//Console.out("countdown irq requested");
									requestInterrupt(countdown_irq);
								}
							}
							count--; 
						}	
						return; 
					};
		
					IR = bus.readWord(PC);
					PC += 4;
			//		feswitch = false;
			//	}
			//	else {
			//		feswitch = true;
			//		if (wait) { return };
					execute();
			//	}
				count--;
			}
		}
		
		private function execute():void {
			//decoding the opcode
			
			var opcode:uint = IR & 0xFC000000;
			if (!opcode) { opcode = IR & 0x3F };
			var args:uint = IR & 0x3FFFFFF;
			var a_i:uint = (args >> 21) & 0x1F;
			var a_j:uint = (args >> 16) & 0x1F;
			var a_k:uint = (args >> 11) & 0x1F;
			var a_isgn:int = int(r[a_i]);
			var a_jsgn:int = int(r[a_j]);
			var a_ksgn:int = int(r[a_k]);
			var a_Kuns:uint = args & 0xFFFF;
			var a_Ksgn:int = a_Kuns;
			//trace(a_Ksgn);
			if (a_Ksgn & 0x8000) {
				//trace("flip!");
				a_Ksgn = ((~a_Ksgn)&0xFFFF)+1;
			}
			var a_Luns:uint = args;
			var a_Lsgn:int = a_Luns;
			if (a_Lsgn & 0x2000000) {
				a_Lsgn = ((~a_Lsgn) & 0x3FFFFFF) + 1;
			}
			if ((a_Kuns & 0x8000) != 0) {
				a_Ksgn = -a_Ksgn;
			}
			if ((a_Luns & 0x2000000) != 0) {
				a_Lsgn = -a_Lsgn;
			}
			var temp:uint;
			
			//VERY SLOW
			if (breakpoint_enable) {
				debugTraceOP();
			}
			
			//sort by opcode
			switch(opcode) {
				case OP_ADD:
					r_write(a_k, r[a_i] + r[a_j]);
				break;
				case OP_ADDU:
					r_write(a_k, r[a_i] + r[a_j]);	
				break;
				case OP_AND:
					r_write(a_k, r[a_i] & r[a_j]);
				break;
				case OP_HALT:
					halt = true;
				break;
				case OP_MOVI2S:
					sr[a_k & 0x3] = r[a_i];
				break;
				case OP_MOVS2I:
					r_write(a_k, sr[a_i & 0x3]);
				break;
				case OP_NOP:
					//do nuffin'
				break;
				case OP_OR:
					r_write(a_k, r[a_i] | r[a_j]);
				break;
				case OP_SEQ:
					if (r[a_i] == r[a_j]) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SEQU:
					if (r[a_i] == r[a_j]) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SGE:
					if (a_isgn >= a_jsgn) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SGEU:
					if (r[a_i] >= r[a_j]) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SGT:
					if (a_isgn > a_jsgn) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SGTU:
					if (r[a_i] > r[a_j]) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SLA:
					r_write(a_k, r[a_i] >> r[a_j]);
				break;
				case OP_SLE:
					if (a_isgn <= a_jsgn) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SLEU:
					if (r[a_i] <= r[a_j]) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SLL:
					r_write(a_k, r[a_i] << r[a_j]);
				break;
				case OP_SLT:
					if (a_isgn < a_jsgn) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SLTU:
					if (r[a_i] < r[a_j]) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SNE:
					if (r[a_i] != r[a_j]) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);
					}
				break;
				case OP_SNEU:
					if (r[a_i] != r[a_j]) {
						r_write(a_k, 1);
					}
					else {
						r_write(a_k, 0);	
					}
				break;
				case OP_SRA:
					r_write(a_k, r[a_i] >> r[a_j]);
				break;
				case OP_SRL:
					r_write(a_k, r[a_i] >> r[a_j]);
				break;
				case OP_SUB:
					r_write(a_k, a_isgn - a_jsgn);
				break;
				case OP_SUBU:
					r_write(a_k, r[a_i] - r[a_j]);
				break;
				case OP_WAIT:
					wait = true;
				break;
				case OP_XOR:
					r_write(a_k, r[a_i] ^ r[a_j]);
				break;
				case OP_ADDI:
					r_write(a_j, r[a_i] + a_Ksgn);
				break;
				case OP_ADDUI:
					//Console.out("ADDUI: " + uint(r[a_i]).toString(2) + "+" + uint(a_Kuns).toString(2) + "=" + uint(r[a_i] + a_Kuns).toString(2));
					r_write(a_j, r[a_i] + a_Kuns);
				break;
				case OP_ANDI:
					r_write(a_j, r[a_i] & a_Kuns); 
				break;
				case OP_BEQZ:
					if (r[a_i] == 0) {
						//trace("Kuns:0x" + a_Kuns.toString(16) +", Ksgn:" + a_Ksgn);
						PC += a_Ksgn;
					}
				break;
				case OP_BNEZ:
					if (r[a_i] != 0) {
						PC += a_Ksgn;
					}
				break;
				case OP_J:
					PC += a_Lsgn;
				break;
				case OP_JAL:
					r[31] = PC;
					PC += a_Lsgn;
				break;
				case OP_JALR:
					r[31] = PC;
					PC = r[a_i];
				break;
				case OP_JR:
					PC = r[a_i];
				break;
				case OP_LB:
					temp = bus.readByte(a_Ksgn + r[a_i]);
					if (temp & 0x80) {
						temp = temp | 0xFFFFFF00;
					}
					r_write(a_j, temp);
				break;
				case OP_LBU:
					r_write(a_j, bus.readByte(a_Ksgn + r[a_i]));
				break;
				case OP_LH:
					temp = bus.readHalf(a_Ksgn + r[a_i]);
					if (temp & 0x8000) {
						temp = temp | 0xFFFF0000;
					}
					r_write(a_j, temp);
				break;
				case OP_LHI:
					r_write(a_j, (a_Kuns << 16));
				break;
				case OP_LHU:
					r_write(a_j, bus.readHalf(a_Ksgn + r[a_i]));
				break;
				case OP_LW:
					r_write(a_j, bus.readWord(r[a_i] + a_Ksgn));
				break;
				case OP_ORI:
					r_write(a_j, r[a_i] | a_Kuns);
				break;
				case OP_RFE:
					PC = sr[XAR];
					//sets psw.U to psw.Up, sets psw.Mxe to 1
					sr[PSW] = ((sr[PSW] & ~PSW_U) | (((sr[PSW] & PSW_UP)?1:0) << PSW_UP_O))|PSW_MXE;
					
				break;
				case OP_SB:
					bus.writeByte(r[a_i] + a_Ksgn, r[a_j]);
				break;
				case OP_SEQI:
					if (int(r[a_i]) == a_Ksgn) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SEQUI:
					if (r[a_i] == a_Kuns) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SGEI:
					if (int(r[a_i]) >= a_Ksgn) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SGEUI:
					if (r[a_i] >= a_Kuns) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SGTI:
					if (int(r[a_i]) > a_Ksgn) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SGTUI:
					if (r[a_i] > a_Kuns) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SH:
					bus.writeHalf(r[a_i] + a_Ksgn, r[a_j]);
				break; 
				case OP_SLAI:
					r_write(a_j, r[a_i] << a_Kuns);
				break;
				case OP_SLEI:
					if (int(r[a_i]) <= a_Ksgn) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SLEUI:
					if (r[a_i] <= a_Kuns) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SLLI:
					r_write(a_j, r[a_i] << a_Kuns);
				break;
				case OP_SLTI:
					if (int(r[a_i]) < a_Ksgn) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SLTUI:
					if (r[a_i] < a_Kuns) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SNEI:
					if (int(r[a_i]) != a_Ksgn) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SNEUI:
					if (r[a_i] != a_Kuns) {
						r_write(a_j, 1);
					}
					else {
						r_write(a_j, 0);
					}
				break;
				case OP_SRAI:
					r_write(a_j, r[a_i] >> a_Kuns);
				break;
				case OP_SRLI:
					r_write(a_j, r[a_i] >> a_Kuns);
				break;
				case OP_SUBI:
					r_write(a_j, r[a_i] - a_Ksgn);
				break;
				case OP_SUBUI:
					r_write(a_j, r[a_i] - a_Kuns);
				break;
				case OP_SW:
					bus.writeWord(r[a_i] + a_Ksgn, r[a_j]);
				break;
				case OP_TRAP:
					requestInterrupt(PSW_UTE);
				break;
				case OP_XORI:
					r_write(a_j, r[a_i] ^ a_Kuns);
				break;
				default:
					requestInterrupt(PSW_IIE);
				break;
			}
		}
		
		public function trap(e:Event = null):void {
			
		}
		
		public function setPC(to:uint):void {
			PC = to;
			//trace("PC set to: 0x" + StringManip.pad(to.toString(16), "0", 4) + " by external process.");
		}
		
		public function requestInterrupt(mask:uint):void {
			IRQQueue = IRQQueue | mask;
			//Console.out("Interrupt requested on priority: " + mask.toString(2));
		}
		
		public function cancelInterrupt(mask:uint):void {
			IRQQueue = IRQQueue & ~mask;
		}
		
		public function handleInterrupt():void {
			var i:uint = 0;
			while (!(IRQQueue & IRQ_MASKS[i])) {
				i++;
			}
			wait = false;
			IRQQueue = IRQQueue & ~PSW_MASKS[i];
			sr[XAR] = PC;
			sr[PSW] = sr[PSW] & ~PSW_MXE;
			PC = sr[XBR] + 4 * i; 
			//trace(i);
		}
		
		public function handleException():void {
			var i:uint = 10;
			while (!(IRQQueue & PSW_MASKS[i])) {
				i++;
			}
			wait = false;
			if (!(sr[PSW] & PSW_MXE) || !(sr[PSW] & PSW_MASKS[i])) {
				sr[XAR] = PC;
				sr[PSW] = sr[PSW] & ~PSW_MXE;
				switch(PSW_MASKS[i]) {
					case PSW_IIE:
						r[29] = 0
						PC = 0;
						bus.switchTargetSelector(MoBo_01.TARGET_EXP);
						IRQQueue = IRQQueue & ~PSW_MASKS[i];
					break;
					case PSW_IME:
						//trace("Handling IME exception!");
						r[29] = 1
						PC = 0;
						bus.switchTargetSelector(MoBo_01.TARGET_EXP);
						IRQQueue = IRQQueue & ~PSW_MASKS[i];
					break;
					case PSW_UTE:
						r[29] = 2
						PC = 0;
						bus.switchTargetSelector(MoBo_01.TARGET_EXP);
						IRQQueue = IRQQueue & ~PSW_MASKS[i];
					break;
					case PSW_OFE:
						
					break;
				}
				
			}
			else {
				IRQQueue = IRQQueue & ~PSW_MASKS[i];
				sr[XAR] = PC;
				sr[PSW] = sr[PSW] & ~PSW_MXE;
				PC = sr[XBR] + 4 * i;
			}
		}
		
		public function debugTraceOP():void {
			//var i:uint;
			if (breakpoints[PC - 4]) {
				paused = true;
				//trace(PC.toString(16));
				Console.command("pause");
			}
			
			//trace(translateOpcode(IR, PC, tick));
		}
		
		
		public function translateOpcode(op:uint, ref:uint=0, stamp:uint=0):String {
			var opcode:uint = (op >> 26) & 0x3F;
			var args:uint = op & 0x3FFFFFF;
			var a_i:uint = (args >> 21) & 0x1F;
			var a_j:uint = (args >> 16) & 0x1F;
			var a_k:uint = (args >> 11) & 0x1F;
			var a_m:uint = args & 0x3F;
			var a_Kuns:uint = args & 0xFFFF;
			var a_Ksgn:int = a_Kuns;
			var a_Luns:uint = args;
			var a_Lsgn:int = a_Luns;
			if ((a_Kuns & 0x8000) != 0) {
				a_Ksgn = -a_Ksgn;
			}
			if ((a_Luns & 0x2000000) != 0) {
				a_Lsgn = -a_Lsgn;
			}
			var i:uint = 0;
			//trace(opcode.toString(2), a_m.toString(2));
			var append:String = "["+stamp+"] PC:" + StringManip.pad(ref.toString(16)) + ", IR:" + StringManip.pad(op.toString(16))+"\n";
			var oplbl:Array = ["Undefined Opcode", 0, ""];
			if (opcode) {
				while (i < oplabels0x.length) {
					//trace(oplabels0x[i][1], opcode);
					//trace("non-alu", opcode, oplabels0x[i]);
					if(oplabels0x[i][1]==opcode){
						append = append + oplabels0x[i][0];
						oplbl = oplabels0x[i];
						break;
					}
					i++;
				}
			}
			else {
				while (i < oplabelshighbranch.length) {
					//trace(oplabelshighbranch[i][1], a_m);
					//trace("alu", opcode, oplabelshighbranch[i]);
					if(oplabelshighbranch[i][1] == (args & 0x3F)){
						append=append+oplabelshighbranch[i][0];
						oplbl = oplabelshighbranch[i];
						break;
					}
					i++;
				}
			}
			
			var als:Array = String(oplbl[2]).split(",");
			
			if (als.length > 0) {
				append = append+"    ";
				i = 0;
				while (i < als.length) {
					if (als[i] == "ri") {
						append = append + "r" + a_i;
					}
					else if (als[i] == "rj") {
						append = append + "r" + a_j;
					}
					else if (als[i] == "rk") {
						append = append + "r" + a_k;
					}
					else if (als[i] == "kuns") {
						append = append + "0x" + a_Kuns.toString(16);
					}
					else if (als[i] == "ksgn") {
						append = append + "0x" + a_Ksgn.toString(16);
					}
					else if (als[i] == "ksgn(ri)") {
						append = append + "0x" + a_Kuns.toString(16)+"(r"+a_i+")";
					}
					else if (als[i] == "luns") {
						append = append + "0x" + a_Luns.toString(16);
					}
					else if (als[i] == "lsgn") {
						append = append + "0x" + a_Lsgn.toString(16);
					}
					i++
					if (i < als.length) {
						append = append + ",";
					}
				}
			}
			return append;
		}
		
		public function com_breakpoint(args:Array):void {
			if (!args[1]) {
				Console.out("Argument expected...");
				return;
			}
			switch(args[0]) {
				case "add_breakpoint":
					if (!isNaN(parseInt(args[1], 16))) {
						breakpoints[parseInt(args[1], 16)] = 1;
					}
					else {
						Console.out("Expected hex value.");
					}
				break;
				case "remove_breakpoint":
					if (!isNaN(parseInt(args[1], 16))) {
						breakpoints[parseInt(args[1], 16)] = 0;
					}
					else {
						Console.out("Expected hex value.");
					}
				break;
				case "breakpoints":
					if (args[1] == "on" || args[1] == "1" || args[1] == "enable" || args[1] == "true") {
						breakpoint_enable = true;
						Console.out("Breakpoints enabled.");
					}
					else if (args[1] == "off" || args[1] == "0" || args[1] == "disable" || args[1] == "false") {
						breakpoint_enable = false;
						Console.out("Breakpoints disabled.");
					}
					else if (args[1] == "list") {
						var i:uint = 0;
						while (i < breakpoints.length) {
							if (breakpoints[i]) {
								Console.out(i.toString(16));
							}
							i++;
						}
					}
					else {
						Console.out("Expected enable/disable string.");
					}
				break;
			}
		}
		
		public function com_regwrite(args:Array):void {
			if (args.length != 3) {
				Console.out("Expected 2 arguments...");
				return;
			}
			Console.out("Setting r" + args[1] + " to 0x" + args[2]);
			r_write(parseInt(args[1], 10), parseInt(args[2], 16));
		}
		
		public function getTick():uint {
			return tick;
		}
	}

}