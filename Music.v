module Music ( //JAMES
	// Inputs
	CLOCK_50,
	KEY,

	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK,
	SW,
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B,   						//	VGA Blue[9:0]
	HEX1,
	HEX4
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input		[3:0]	KEY;
input		[9:0]	SW;

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				FPGA_I2C_SCLK;


// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	output [6:0] HEX1;
	output [6:0] HEX4;
	
/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

// Internal Registers

reg [18:0] delay_cnt;
wire [18:0] delay;

reg snd;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
	if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end else delay_cnt <= delay_cnt + 1;

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

reg [31:0] tone = 0;
reg [31:0] tone_counter = 0;
reg [31:0] tone_limited = 37593984; // 80 bpm

always@(posedge CLOCK_50) begin
	if (tone_counter == tone_limited) begin
		tone = tone + 1;
		tone_counter <= 0;
	end
	else if (tone == 615) begin
		tone = 0;
		tone_limited <= 37593984; // 80 bpm rudolph the red nosed reindeer
	end
	else begin
		tone_counter <= tone_counter + 1;
	end
	
	if (tone == 111) begin
		tone_limited <= 20000000; // 150 bpm all i want for christmas is you
	end
	else if (tone == 174) begin
		tone_limited <= 31645569; // 95 bpm its beginning to look a lot like christmas
	end
	else if (tone == 405) begin
		tone_limited <= 44247787; // 68 bpm - nat king cole roasted chestnuts
	end
	else if (tone == 552) begin
		tone_limited <= 20161290; // 149 bpm - feliz navidad
	end
end 

wire [7:0] note;

rom_memory read_note_from_read_only_memory(.CLOCK_50(CLOCK_50), .address(tone), .note(note));
 
assign delay = {note, 11'd3000};

wire [31:0] sound = (SW == 0) ? 0 : snd ? 32'd10000000 : -32'd10000000;

assign read_audio_in			= audio_in_available & audio_out_allowed;

assign left_channel_audio_out	= left_channel_audio_in+sound;
assign right_channel_audio_out	= right_channel_audio_in+sound;
assign write_audio_out			= audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(SW[8]),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~KEY[0])
);


part2 game(
		.CLOCK_50(CLOCK_50),						//	On Board 50 MHz
		// Your inputs and outputs here
		.KEY(KEY),							// On Board Keys
		// The ports below are for the VGA output.  Do not change.
		.VGA_CLK(VGA_CLK),   						//	VGA Clock
		.VGA_HS(VGA_HS),							//	VGA H_SYNC
		.VGA_VS(VGA_VS),							//	VGA V_SYNC
		.VGA_BLANK_N(VGA_BLANK_N),						//	VGA BLANK
		.VGA_SYNC_N(VGA_SYNC_N),						//	VGA SYNC
		.VGA_R(VGA_R),   						//	VGA Red[9:0]
		.VGA_G(VGA_G),	 						//	VGA Green[9:0]
		.VGA_B(VGA_B),   						//	VGA Blue[9:0]
		.SW(SW),
		.HEX1(HEX1),
		.HEX4(HEX4)
	);
endmodule

module rom_memory (input CLOCK_50, input [31:0] address, output reg [7:0] note);
	always@(posedge CLOCK_50) begin
		case (address)
			// rudolph the red nose reindeer
			0: note <= 8'd17; // G
			1: note <= 8'd15; // A
			2: note <= 8'd17; // G
			3: note <= 8'd20; // E
			4: note <= 8'd12;
			5: note <= 8'd15;
			6: note <= 8'd17;	//F
			
			7: note <= 8'd17;
			8: note <= 8'd15;
			9: note <= 8'd17;
			10: note <= 8'd15;
			11: note <= 8'd17;
			12: note <= 8'd12;
			13: note <= 8'd13;
		  
			14: note <= 8'd19;
			15: note <= 8'd17;
			16: note <= 8'd19;
			17: note <= 8'd22;
			18: note <= 8'd13;
			19: note <= 8'd15;
			20: note <= 8'd17;
		  
			21: note <= 8'd17;
			22: note <= 8'd15;
			23: note <= 8'd17;
			24: note <= 8'd15;
			25: note <= 8'd17;
			26: note <= 8'd15;
			27: note <= 8'd20;
			
			28: note <= 8'd17;
			29: note <= 8'd15;
			30: note <= 8'd17;
			31: note <= 8'd20;
			32: note <= 8'd12;
			33: note <= 8'd15;
			34: note <= 8'd17;
			
			35: note <= 8'd17;
			36: note <= 8'd15;
			37: note <= 8'd17;
			38: note <= 8'd15;
			39: note <= 8'd17;
			40: note <= 8'd12;
			41: note <= 8'd13;
			
			42: note <= 8'd19;
			43: note <= 8'd17;
			44: note <= 8'd19;
			45: note <= 8'd22;
			46: note <= 8'd13;
			47: note <= 8'd15;
			48: note <= 8'd17;
			
			49: note <= 8'd17;
			50: note <= 8'd15;
			51: note <= 8'd17;
			52: note <= 8'd15;
			53: note <= 8'd17;
			54: note <= 8'd10;
			55: note <= 8'd12;
			
			56: note <= 8'd15;
			57: note <= 8'd15;
			58: note <= 8'd12;
			59: note <= 8'd15;
			60: note <= 8'd17;
			61: note <= 8'd20;
			62: note <= 8'd17;
			
			63: note <= 8'd19;
			64: note <= 8'd15;
			65: note <= 8'd17;
			66: note <= 8'd19;
			67: note <= 8'd20;
			68: note <= 8'd22;

			70: note <= 8'd22;
			71: note <= 8'd17;
			72: note <= 8'd15;
			73: note <= 8'd13;
			74: note <= 8'd13;
			75: note <= 8'd13;
			
			76: note <= 8'd12;
			77: note <= 8'd12;
			78: note <= 8'd13;
			79: note <= 8'd15;
			80: note <= 8'd17;
			81: note <= 8'd19;
			82: note <= 8'd22;
			
			83: note <= 8'd17;
			84: note <= 8'd15;
			85: note <= 8'd17;
			86: note <= 8'd20;
			87: note <= 8'd12;
			88: note <= 8'd15;
			89: note <= 8'd17;
			
			91: note <= 8'd17;
			92: note <= 8'd15;
			93: note <= 8'd17;
			94: note <= 8'd15;
			95: note <= 8'd17;
			96: note <= 8'd12;
			96: note <= 8'd13;
			
			97: note <= 8'd19;
			98: note <= 8'd17;
			99: note <= 8'd19;
			100: note <= 8'd22;
			101: note <= 8'd13;
			102: note <= 8'd15;
			103: note <= 8'd17;
			
			104: note <= 8'd17;
			105: note <= 8'd15;
			106: note <= 8'd17;
			107: note <= 8'd15;
			108: note <= 8'd17;
			109: note <= 8'd10;
			110: note <= 8'd12;
			
			
			// all i want for christmas is you
			
			111: note <= 8'd29;
			112: note <= 8'd25;
			113: note <= 8'd22;
			114: note <= 8'd18;
			115: note <= 8'd17;
			116: note <= 8'd18;
			117: note <= 8'd20;
			118: note <= 8'd22;
			
			119: note <= 8'd25;
			120: note <= 8'd24;
			121: note <= 8'd27;
			122: note <= 8'd28;
			123: note <= 8'd27;
			124: note <= 8'd28;
			125: note <= 8'd20;
			126: note <= 8'd22;
			
			127: note <= 8'd24;
			128: note <= 8'd20;
			129: note <= 8'd17;
			130: note <= 8'd15;
			131: note <= 8'd14;
			132: note <= 8'd15;
			133: note <= 8'd17;
			134: note <= 8'd20;
			
			135: note <= 8'd24;
			136: note <= 8'd21;
			137: note <= 8'd17;
			138: note <= 8'd15;
			139: note <= 8'd14;
			140: note <= 8'd15;
			141: note <= 8'd19;
			142: note <= 8'd21;
			
			143: note <= 8'd17;
			144: note <= 8'd15;
			145: note <= 8'd18;
			146: note <= 8'd17;
			147: note <= 8'd20;
			148: note <= 8'd18;
			149: note <= 8'd20;
			150: note <= 8'd21;
			
			151: note <= 8'd13;
			152: note <= 8'd15;
			153: note <= 8'd17;
			154: note <= 8'd18;
			155: note <= 8'd20;
			156: note <= 8'd18;
			157: note <= 8'd20;
			158: note <= 8'd21;
			
			159: note <= 8'd22;
			160: note <= 8'd20;
			161: note <= 8'd17;
			162: note <= 8'd10;
			163: note <= 8'd12;
			
			164: note <= 8'd13;
			165: note <= 8'd15;
			167: note <= 8'd17;
			168: note <= 8'd20;
			169: note <= 8'd21;
			170: note <= 8'd15;
			171: note <= 8'd13;
			172: note <= 8'd15;
			173: note <= 8'd17;
			
			// its beginning to look a lot like christmas
			174: note <= 8'd13;
			175: note <= 8'd24;
			176: note <= 8'd22;
			177: note <= 8'd20;
			178: note <= 8'd22;
			179: note <= 8'd23;
			180: note <= 8'd22;
			181: note <= 8'd20;
			182: note <= 8'd17;
			183: note <= 8'd13;
			184: note <= 8'd22;
			
			185: note <= 8'd13;
			186: note <= 8'd13;
			187: note <= 8'd15;
			188: note <= 8'd17;
			189: note <= 8'd20;
			
			190: note <= 8'd20;
			191: note <= 8'd18;
			192: note <= 8'd17;
			193: note <= 8'd15;
			194: note <= 8'd17;
			195: note <= 8'd20;
			196: note <= 8'd19;
			197: note <= 8'd18;
			
			198: note <= 8'd18;
			199: note <= 8'd17;
			200: note <= 8'd18;
			201: note <= 8'd22;
			202: note <= 8'd21;
			203: note <= 8'd20;
			
			204: note <= 8'd19;
			205: note <= 8'd18;
			206: note <= 8'd17;
			207: note <= 8'd15;
			208: note <= 8'd13;
			209: note <= 8'd15;
			210: note <= 8'd17;
			211: note <= 8'd18;
			212: note <= 8'd20;
			213: note <= 8'd15;
			
			214: note <= 8'd13;
			215: note <= 8'd24;
			216: note <= 8'd22;
			217: note <= 8'd20;
			218: note <= 8'd22;
			219: note <= 8'd23;
			220: note <= 8'd22;
			221: note <= 8'd20;
			222: note <= 8'd17;
			223: note <= 8'd13;
			224: note <= 8'd22;
			
			225: note <= 8'd13;
			226: note <= 8'd13;
			227: note <= 8'd15;
			228: note <= 8'd17;
			229: note <= 8'd20;
			
			230: note <= 8'd20;
			231: note <= 8'd18;
			232: note <= 8'd17;
			233: note <= 8'd15;
			234: note <= 8'd17;
			235: note <= 8'd18;
			236: note <= 8'd17;
			237: note <= 8'd18;
			238: note <= 8'd20;
			239: note <= 8'd21;
			240: note <= 8'd22;
			241: note <= 8'd20;
			242: note <= 8'd17;
			243: note <= 8'd13;
			244: note <= 8'd22;
			
			245: note <= 8'd21;
			246: note <= 8'd20;
			247: note <= 8'd24;
			248: note <= 8'd18;
			249: note <= 8'd17;
			
			250: note <= 8'd18;
			251: note <= 8'd17;
			252: note <= 8'd15;
			253: note <= 8'd13;
			254: note <= 8'd24;
			255: note <= 8'd13;
			256: note <= 8'd15;
			257: note <= 8'd13;
			258: note <= 8'd15;
			259: note <= 8'd17;
			260: note <= 8'd15;
			261: note <= 8'd17;
			262: note <= 8'd18;
			
			263: note <= 8'd17;
			264: note <= 8'd15;
			265: note <= 8'd13;
			266: note <= 8'd13;
			267: note <= 8'd15;
			268: note <= 8'd17;
			269: note <= 8'd18;
			270: note <= 8'd20;
			
			271: note <= 8'd15;
			272: note <= 8'd13;
			273: note <= 8'd15;
			274: note <= 8'd17;
			275: note <= 8'd15;
			276: note <= 8'd17;
			277: note <= 8'd18;
			278: note <= 8'd17;
			279: note <= 8'd18;
			280: note <= 8'd20;
			
			281: note <= 8'd18;
			282: note <= 8'd17;
			283: note <= 8'd15;
			284: note <= 8'd15;
			285: note <= 8'd17;
			286: note <= 8'd18;
			287: note <= 8'd20;
			288: note <= 8'd22;
			
			289: note <= 8'd22;
			290: note <= 8'd10;
			291: note <= 8'd23;
			292: note <= 8'd24;
			293: note <= 8'd13;
			294: note <= 8'd15;
			295: note <= 8'd17;
			296: note <= 8'd18;
			297: note <= 8'd20;
			298: note <= 8'd22;
			299: note <= 8'd23;
			300: note <= 8'd22;
			301: note <= 8'd20;
			302: note <= 8'd22;
			
			303: note <= 8'd13;
			304: note <= 8'd24;
			305: note <= 8'd22;
			306: note <= 8'd20;
			307: note <= 8'd22;
			308: note <= 8'd23;
			309: note <= 8'd22;
			310: note <= 8'd20;
			311: note <= 8'd17;
			312: note <= 8'd13;
			313: note <= 8'd22;
			
			314: note <= 8'd13;
			315: note <= 8'd13;
			316: note <= 8'd15;
			317: note <= 8'd17;
			318: note <= 8'd20;
			
			// next line is there's a tree in the Grand hotel, one in the park as well
			
			319: note <= 8'd20;
			320: note <= 8'd18;
			321: note <= 8'd17;
			322: note <= 8'd15;
			323: note <= 8'd17;
			324: note <= 8'd20;
			325: note <= 8'd19;
			326: note <= 8'd18;
			327: note <= 8'd18;
			328: note <= 8'd17;
			329: note <= 8'd18;
			330: note <= 8'd22;
			331: note <= 8'd21;
			332: note <= 8'd20;
			
			333: note <= 8'd13;
			334: note <= 8'd24;
			335: note <= 8'd22;
			336: note <= 8'd20;
			337: note <= 8'd22;
			338: note <= 8'd23;
			339: note <= 8'd22;
			340: note <= 8'd20;
			341: note <= 8'd17;
			342: note <= 8'd13;
			343: note <= 8'd22;
			
			344: note <= 8'd13;
			345: note <= 8'd13;
			346: note <= 8'd15;
			347: note <= 8'd17;
			348: note <= 8'd20;
			
			349: note <= 8'd20;
			350: note <= 8'd18;
			351: note <= 8'd17;
			352: note <= 8'd15;
			353: note <= 8'd17;
			354: note <= 8'd18;
			355: note <= 8'd17;
			356: note <= 8'd18;
			357: note <= 8'd20;
			358: note <= 8'd21;
			359: note <= 8'd22;
			360: note <= 8'd20;
			361: note <= 8'd17;
			362: note <= 8'd13;
			363: note <= 8'd22;
			
			364: note <= 8'd21;
			365: note <= 8'd20;
			366: note <= 8'd24;
			367: note <= 8'd18;
			368: note <= 8'd17;
			
			369: note <= 8'd13;
			370: note <= 8'd24;
			371: note <= 8'd22;
			372: note <= 8'd20;
			373: note <= 8'd22;
			374: note <= 8'd23;
			375: note <= 8'd22;
			376: note <= 8'd20;
			377: note <= 8'd17;
			378: note <= 8'd13;
			379: note <= 8'd22;
			
			380: note <= 8'd13;
			381: note <= 8'd13;
			382: note <= 8'd15;
			383: note <= 8'd17;
			384: note <= 8'd20;
			
			385: note <= 8'd20;
			386: note <= 8'd18;
			387: note <= 8'd17;
			388: note <= 8'd15;
			389: note <= 8'd17;
			390: note <= 8'd18;
			391: note <= 8'd17;
			392: note <= 8'd18;
			393: note <= 8'd20;
			394: note <= 8'd21;
			395: note <= 8'd22;
			396: note <= 8'd20;
			397: note <= 8'd17;
			398: note <= 8'd13;
			399: note <= 8'd22;
			
			400: note <= 8'd21;
			401: note <= 8'd20;
			402: note <= 8'd24;
			403: note <= 8'd18;
			404: note <= 8'd17;
			
			// nat king cole - the christmas song (chestnuts roasting on an open fire)
			
			405: note <= 8'd24;
			406: note <= 8'd12;
			407: note <= 8'd13;
			408: note <= 8'd15;
			409: note <= 8'd17;
			410: note <= 8'd19;
			411: note <= 8'd20;
			412: note <= 8'd20;
			413: note <= 8'd20;
			
			414: note <= 8'd24;
			415: note <= 8'd15;
			416: note <= 8'd17;
			417: note <= 8'd19;
			418: note <= 8'd20;
			419: note <= 8'd22;
			420: note <= 8'd24;
			
			421: note <= 8'd24;
			422: note <= 8'd24;
			423: note <= 8'd22;
			424: note <= 8'd22;
			425: note <= 8'd24;
			426: note <= 8'd22;
			427: note <= 8'd20;
			428: note <= 8'd17;
			429: note <= 8'd15;
			430: note <= 8'd13;
			
			431: note <= 8'd15;
			432: note <= 8'd16;
			433: note <= 8'd16;
			434: note <= 8'd14;
			435: note <= 8'd16;
			436: note <= 8'd17;
			437: note <= 8'd19;
			438: note <= 8'd17;
			
			439: note <= 8'd17;
			440: note <= 8'd19;
			441: note <= 8'd20;
			442: note <= 8'd22;
			443: note <= 8'd24;
			
			444: note <= 8'd12;
			445: note <= 8'd13;
			446: note <= 8'd15;
			447: note <= 8'd17;
			448: note <= 8'd19;
			449: note <= 8'd20;
			450: note <= 8'd20;
			451: note <= 8'd20;
			
			452: note <= 8'd24;
			453: note <= 8'd15;
			454: note <= 8'd17;
			455: note <= 8'd19;
			456: note <= 8'd20;
			457: note <= 8'd22;
			458: note <= 8'd24;
			
			459: note <= 8'd24;
			460: note <= 8'd24;
			461: note <= 8'd22;
			462: note <= 8'd24;
			463: note <= 8'd22;
			464: note <= 8'd20;
			465: note <= 8'd17;
			466: note <= 8'd15;
			467: note <= 8'd13;
			
			468: note <= 8'd15;
			469: note <= 8'd17;
			470: note <= 8'd20;
			471: note <= 8'd15;
			472: note <= 8'd17;
			473: note <= 8'd19;
			474: note <= 8'd25;
			475: note <= 8'd24;
			
			476: note <= 8'd24;
			477: note <= 8'd25;
			478: note <= 8'd24;
			479: note <= 8'd14;
			480: note <= 8'd15;
			481: note <= 8'd17;
			482: note <= 8'd18;
			483: note <= 8'd17;
			
			484: note <= 8'd24;
			485: note <= 8'd25;
			486: note <= 8'd24;
			487: note <= 8'd14;
			488: note <= 8'd15;
			489: note <= 8'd13;
			
			490: note <= 8'd15;
			491: note <= 8'd13;
			492: note <= 8'd15;
			493: note <= 8'd17;
			494: note <= 8'd19;
			495: note <= 8'd17;
			
			496: note <= 8'd24;
			497: note <= 8'd25;
			498: note <= 8'd24;
			499: note <= 8'd16;
			500: note <= 8'd17;
			501: note <= 8'd16;
			502: note <= 8'd17;
			503: note <= 8'd19;
			504: note <= 8'd21;
			505: note <= 8'd19;
			
			506: note <= 8'd21;
			507: note <= 8'd19;
			508: note <= 8'd21;
			509: note <= 8'd22;
			510: note <= 8'd22;
			511: note <= 8'd22;
			512: note <= 8'd22;
			513: note <= 8'd22;
			514: note <= 8'd22;
			515: note <= 8'd22;
			516: note <= 8'd22;
			
			517: note <= 8'd20;
			518: note <= 8'd24;
			519: note <= 8'd12;
			520: note <= 8'd13;
			521: note <= 8'd15;
			522: note <= 8'd17;
			523: note <= 8'd19;
			524: note <= 8'd20;
			525: note <= 8'd20;
			526: note <= 8'd20;
			
			527: note <= 8'd20;
			528: note <= 8'd24;
			529: note <= 8'd15;
			530: note <= 8'd17;
			531: note <= 8'd19;
			532: note <= 8'd20;
			533: note <= 8'd22;
			534: note <= 8'd24;
			
			535: note <= 8'd25;
			536: note <= 8'd24;
			537: note <= 8'd25;
			538: note <= 8'd24;
			539: note <= 8'd22;
			540: note <= 8'd24;
			541: note <= 8'd22;
			542: note <= 8'd20;
			
			543: note <= 8'd17;
			544: note <= 8'd15;
			545: note <= 8'd13;
			
			546: note <= 8'd12;
			547: note <= 8'd15;
			548: note <= 8'd17;
			549: note <= 8'd24;
			550: note <= 8'd22;
			551: note <= 8'd24;
			
			// Feliz Navidad
			552: note <= 8'd17; // G
			553: note <= 8'd12; // ^C
			554: note <= 8'd13; // B
			555: note <= 8'd12; // ^C
			556: note <= 8'd15; // A

			557: note <= 8'd15; // A
			558: note <= 8'd10; // ^D
			559: note <= 8'd12; // ^C
			560: note <= 8'd15; // A
			561: note <= 8'd17; // G

			562: note <= 8'd17; // G
			563: note <= 8'd12; // ^C
			563: note <= 8'd13; // B
			564: note <= 8'd12; // ^C
			565: note <= 8'd15; // A
			
			566: note <= 8'd19; // F
			567: note <= 8'd15; // A
			568: note <= 8'd15; // A
			569: note <= 8'd17; // G
			570: note <= 8'd17; // G
			571: note <= 8'd15; // A
			572: note <= 8'd17; // G
			573: note <= 8'd19; // F
			574: note <= 8'd19; // F
			575: note <= 8'd20; // E

			576: note <= 8'd8; // ^E
			577: note <= 8'd8; // ^E
			578: note <= 8'd8; // ^E
			579: note <= 8'd8; // ^E
			580: note <= 8'd10; // ^D
			581: note <= 8'd12; // ^C
			582: note <= 8'd12; // ^C
			583: note <= 8'd15; // A
			584: note <= 8'd15; // A
			585: note <= 8'd12; // ^C
			
			586: note <= 8'd10;
			587: note <= 8'd10;
			588: note <= 8'd10;
			589: note <= 8'd10;
			590: note <= 8'd12;
			591: note <= 8'd15;
			592: note <= 8'd15;
			593: note <= 8'd17;
			594: note <= 8'd18;
			595: note <= 8'd17;
			
			596: note <= 8'd8; // ^E
			597: note <= 8'd8; // ^E
			598: note <= 8'd8; // ^E
			599: note <= 8'd8; // ^E
			600: note <= 8'd10; // ^D
			601: note <= 8'd12; // ^C
			602: note <= 8'd12; // ^C
			603: note <= 8'd15; // A
			604: note <= 8'd15; // A
			605: note <= 8'd15; // A

			606: note <= 8'd10;
			607: note <= 8'd12;
			608: note <= 8'd13;
			609: note <= 8'd13;
			610: note <= 8'd12;
			611: note <= 8'd10;
			612: note <= 8'd10;
			613: note <= 8'd8;
			614: note <= 8'd10;
			615: note <= 8'd12;
			
		default: note <= 8'd0;
		endcase
	end
endmodule
