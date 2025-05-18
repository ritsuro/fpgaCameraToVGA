// EP4CE22F17C6N FPGA
module testCamera01 (
	input					CLOCK_50,
	input					RST_N,
	output	[7:0]		LED,
	input					BUTTON01,

	inout					CAMERA_SIO_D,
	inout					CAMERA_SIO_C,
	input					CAMERA_PCLK,
	input					CAMERA_V_SYNC,
	input					CAMERA_HREF,
	output				CAMERA_XCLK,
	input		[7:0]		CAMERA_D,
	
	output	[2:0]		VGA_R,
	output	[2:0]		VGA_G,
	output	[2:0]		VGA_B,
	output				VGA_V_SYNC,
	output				VGA_H_SYNC
);

assign	LED[7:0] = RECV_DATA[7:0];

wire	[2:0]		r_val;
wire	[2:0]		g_val;
wire	[2:0]		b_val;

reg	[2:0]		r_val_bg = 3'b111;
reg	[2:0]		g_val_bg = 3'b111;
reg	[2:0]		b_val_bg = 3'b111;

reg	[2:0]		r_val_bg2 = 3'd0;
reg	[2:0]		g_val_bg2 = 3'd0;
reg	[2:0]		b_val_bg2 = 3'd0;

reg	[3:0]		r_val_bg3 = 4'd0;
reg	[3:0]		g_val_bg3 = 4'd0;
reg	[3:0]		b_val_bg3 = 4'd0;

// GPIO VGA.
wire	[19:0]	dot;
wire	[19:0]	y_count;

wire	[2:0]		VGA_R_w;
wire	[2:0]		VGA_G_w;
wire	[2:0]		VGA_B_w;
wire				VGA_V_SYNC_w;
wire				VGA_H_SYNC_w;

connectVGA connectVGA (
		.CLOCK_50(CLOCK_50),
		.r_val(r_val),
		.g_val(g_val),
		.b_val(b_val),
		.dot_out(dot),
		.y_count_out(y_count),
		.VGA_R(VGA_R_w),
		.VGA_G(VGA_G_w),
		.VGA_B(VGA_B_w),
		.VGA_V_SYNC(VGA_V_SYNC_w),
		.VGA_H_SYNC(VGA_H_SYNC_w)
	);

	
wire		[2:0]		r_val_cam1;
wire		[2:0]		g_val_cam1;
wire		[2:0]		b_val_cam1;
wire					flagOK_cam1;
	
connectCamera01 connectCamera01 (
		.CLOCK_50(CLOCK_50),
		.RST_N(RST_N),
		.dot(dot),
		.y_count_in(y_count),
		
		.VGA_V_SYNC(VGA_V_SYNC_w),

		.CAMERA_PCLK(CAMERA_PCLK),
		.CAMERA_V_SYNC(CAMERA_V_SYNC),
		.CAMERA_HREF(CAMERA_HREF),
		.CAMERA_D(CAMERA_D),

		.CAMERA_XCLK(CAMERA_XCLK),

		.debug_ramAddress(ramAddress),
		.debug_ramData(ramData),
		.debug_flagReadOK(flagReadOK),
		
		.r_val(r_val_cam1),
		.g_val(g_val_cam1),
		.b_val(b_val_cam1),
		.flagOK(flagOK_cam1)
	);


reg		[7:0]		SLAVE_ADDRESS = 8'h42;		// 42h=OV7670, 3Ah=ADXL345, A0h=EEPROM
reg		[7:0]		DATA_ADDRESS = 8'h00; 		//
reg		[7:0]		DATA_IMAGE = 8'b0000_0000; //
wire		[7:0]		RECV_DATA;
wire		[7:0]		RECV_DATA02;
wire		[7:0]		RECV_DATA03;
wire		[7:0]		RECV_DATA04;
wire		[7:0]		RECV_DATA05;
wire		[7:0]		RECV_DATA06;

reg					flagRequest = 1'b0;
reg					flagReadMode = 1'b1;			// 1=read,0=write.
reg					flagMultiByteMode = 1'b1;	// multi byte mode flag. <===================
reg		[3:0]		countMultiByte = 4'd0;		// multi byte byte count.(2~6)
wire					flagBusy;
wire					flagReady;

connectI2C connectI2C (
	.CLOCK_50(CLOCK_50),
	.RST_N(RST_N),
	.I2C_SCLK(CAMERA_SIO_C),
	.I2C_SDAT(CAMERA_SIO_D),
	
	.SLAVE_ADDRESS(SLAVE_ADDRESS),
	.DATA_ADDRESS(DATA_ADDRESS),
	.DATA_IMAGE(DATA_IMAGE),
	.RECV_DATA(RECV_DATA),
	.RECV_DATA02(RECV_DATA02),
	.RECV_DATA03(RECV_DATA03),
	.RECV_DATA04(RECV_DATA04),
	.RECV_DATA05(RECV_DATA05),
	.RECV_DATA06(RECV_DATA06),
	
	.flagRequest(flagRequest),
	.flagReadMode(flagReadMode),
	.flagMultiByteMode(flagMultiByteMode),
	.countMultiByte(countMultiByte),
	
	.flagBusy(flagBusy),
	.flagReady(flagReady)
);

	
reg				resetMode = 1'b0;

wire	[23:0]	ramAddress;
wire	[15:0]	ramData;
wire				flagReadOK;

wire				r_val_tx1;
wire				g_val_tx1;
wire				b_val_tx1;
wire				flagOK_tx1;

textDraw02 textDraw02(
		.CLOCK_50(CLOCK_50),
		.RST_N(RST_N),
		.dot(dot),
		.y_count_in(y_count),
		
		.resetMode(resetMode),
		
		.ramAddress(ramAddress),
		.ramData(ramData),
		.flagReadOK(flagReadOK),
		
		.ramAddress02(ramAddress02),
		.ramData02(ramData02),
		.flagReadOK02(flagReadOK02),
		
		.r_val(r_val_tx1),
		.g_val(g_val_tx1),
		.b_val(b_val_tx1),
		.flagOK(flagOK_tx1)
	);
	
	
reg	[10:0]	box1_x1 = 10'd200;
reg	[10:0]	box1_y1 = 10'd100;
reg	[10:0]	box1_x2 = 10'd560;
reg	[10:0]	box1_y2 = 10'd300;
reg	[0:0]		box1_r_color = 1'b1;
reg	[0:0]		box1_g_color = 1'b0;
reg	[0:0]		box1_b_color = 1'b1;
	
wire				r_val_box1;
wire				g_val_box1;
wire				b_val_box1;
wire				flagOK_box1;

drawBox01 drawBox01(
		.dot(dot),
		.y_count_in(y_count),
	
		.x1(box1_x1),
		.y1(box1_y1),
		.x2(box1_x2),
		.y2(box1_y2),
		.r_color(box1_r_color),
		.g_color(box1_g_color),
		.b_color(box1_b_color),
	
		.r_val(r_val_box1),
		.g_val(g_val_box1),
		.b_val(b_val_box1),
		.flagOK(flagOK_box1)
	);

	
reg	[10:0]	box2_x1 = 10'd640;
reg	[10:0]	box2_y1 = 10'd120;
reg	[10:0]	box2_x2 = 10'd1000;
reg	[10:0]	box2_y2 = 10'd320;
reg	[0:0]		box2_r_color = 1'b0;
reg	[0:0]		box2_g_color = 1'b1;
reg	[0:0]		box2_b_color = 1'b1;
	
wire				r_val_box2;
wire				g_val_box2;
wire				b_val_box2;
wire				flagOK_box2;

drawBox01 drawBox02(
		.dot(dot),
		.y_count_in(y_count),
	
		.x1(box2_x1),
		.y1(box2_y1),
		.x2(box2_x2),
		.y2(box2_y2),
		.r_color(box2_r_color),
		.g_color(box2_g_color),
		.b_color(box2_b_color),
	
		.r_val(r_val_box2),
		.g_val(g_val_box2),
		.b_val(b_val_box2),
		.flagOK(flagOK_box2)
	);

/*	
reg	[10:0]	line1_x1 = 10'd400;
reg	[10:0]	line1_y1 = 10'd400;
reg	[10:0]	line1_x2 = 10'd800;
reg	[10:0]	line1_y2 = 10'd400;
reg	[0:0]		line1_r_color = 1'b0;
reg	[0:0]		line1_g_color = 1'b1;
reg	[0:0]		line1_b_color = 1'b0;
	
wire				r_val_line1;
wire				g_val_line1;
wire				b_val_line1;
wire				flagOK_line1;

drawLine01 drawLine01(
		.CLOCK_50(CLOCK_50),
		.dot(dot),
		.y_count_in(y_count),
	
		.x1(line1_x1),
		.y1(line1_y1),
		.x2(line1_x2),
		.y2(line1_y2),
		.r_color(line1_r_color),
		.g_color(line1_g_color),
		.b_color(line1_b_color),
	
		.r_val(r_val_line1),
		.g_val(g_val_line1),
		.b_val(b_val_line1),
		.flagOK(flagOK_line1)
	);

	
reg	[10:0]	line2_x1 = 10'd600;
reg	[10:0]	line2_y1 = 10'd360;
reg	[10:0]	line2_x2 = 10'd600;
reg	[10:0]	line2_y2 = 10'd450;
reg	[0:0]		line2_r_color = 1'b1;
reg	[0:0]		line2_g_color = 1'b0;
reg	[0:0]		line2_b_color = 1'b0;
	
wire				r_val_line2;
wire				g_val_line2;
wire				b_val_line2;
wire				flagOK_line2;

drawLine01 drawLine02(
		.CLOCK_50(CLOCK_50),
		.dot(dot),
		.y_count_in(y_count),
	
		.x1(line2_x1),
		.y1(line2_y1),
		.x2(line2_x2),
		.y2(line2_y2),
		.r_color(line2_r_color),
		.g_color(line2_g_color),
		.b_color(line2_b_color),
	
		.r_val(r_val_line2),
		.g_val(g_val_line2),
		.b_val(b_val_line2),
		.flagOK(flagOK_line2)
	);


reg	[10:0]	line3_x1 = 10'd0;
reg	[10:0]	line3_y1 = 10'd0;
reg	[10:0]	line3_x2 = 10'd100;
reg	[10:0]	line3_y2 = 10'd100;
reg	[0:0]		line3_r_color = 1'b0;
reg	[0:0]		line3_g_color = 1'b0;
reg	[0:0]		line3_b_color = 1'b1;
	
wire				r_val_line3;
wire				g_val_line3;
wire				b_val_line3;
wire				flagOK_line3;

drawLine01 drawLine03(
		.CLOCK_50(CLOCK_50),
		.dot(dot),
		.y_count_in(y_count),
	
		.x1(line3_x1),
		.y1(line3_y1),
		.x2(line3_x2),
		.y2(line3_y2),
		.r_color(line3_r_color),
		.g_color(line3_g_color),
		.b_color(line3_b_color),
	
		.r_val(r_val_line3),
		.g_val(g_val_line3),
		.b_val(b_val_line3),
		.flagOK(flagOK_line3)
	);


reg	[10:0]	line4_x1 = 10'd0;
reg	[10:0]	line4_y1 = 10'd240;
reg	[10:0]	line4_x2 = 10'd1279;
reg	[10:0]	line4_y2 = 10'd240;
reg	[0:0]		line4_r_color = 1'b1;
reg	[0:0]		line4_g_color = 1'b1;
reg	[0:0]		line4_b_color = 1'b0;
	
wire				r_val_line4;
wire				g_val_line4;
wire				b_val_line4;
wire				flagOK_line4;

drawLine01 drawLine04(
		.CLOCK_50(CLOCK_50),
		.dot(dot),
		.y_count_in(y_count),
	
		.x1(line4_x1),
		.y1(line4_y1),
		.x2(line4_x2),
		.y2(line4_y2),
		.r_color(line4_r_color),
		.g_color(line4_g_color),
		.b_color(line4_b_color),
	
		.r_val(r_val_line4),
		.g_val(g_val_line4),
		.b_val(b_val_line4),
		.flagOK(flagOK_line4)
	);


reg	[10:0]	line5_x1 = 10'd0;
reg	[10:0]	line5_y1 = 10'd240;
reg	[10:0]	line5_x2 = 10'd1279;
reg	[10:0]	line5_y2 = 10'd240;
reg	[0:0]		line5_r_color = 1'b0;
reg	[0:0]		line5_g_color = 1'b1;
reg	[0:0]		line5_b_color = 1'b0;
	
wire				r_val_line5;
wire				g_val_line5;
wire				b_val_line5;
wire				flagOK_line5;

drawLine01 drawLine05(
		.CLOCK_50(CLOCK_50),
		.dot(dot),
		.y_count_in(y_count),
	
		.x1(line5_x1),
		.y1(line5_y1),
		.x2(line5_x2),
		.y2(line5_y2),
		.r_color(line5_r_color),
		.g_color(line5_g_color),
		.b_color(line5_b_color),
	
		.r_val(r_val_line5),
		.g_val(g_val_line5),
		.b_val(b_val_line5),
		.flagOK(flagOK_line5)
	);
*/

reg 			flag_box1 = 1'b0;
reg [23:0]	timeInterval_box1 = 24'd0;

reg 			flag_box2 = 1'b0;
reg [23:0]	timeInterval_box2 = 24'd0;

reg [23:0]	timeInterval_line3 = 24'd0;
reg [23:0]	timeInterval_line4 = 24'd0;
reg [23:0]	timeInterval_line5 = 24'd0;


reg [31:0]	timeInterval_cameraSetup = 32'd0;

reg [9:0]	sequenceNumber = 10'd0;
reg [7:0]	functionNumber = 8'd0;
reg [0:0]	flagRUN = 1'b0;

reg [23:0]	ramAddress02 = 24'd10;
reg [15:0]	ramData02 = 16'd0;
reg [0:0]	flagReadOK02 = 1'b0;

//reg	[0:0]		CAMERA_XCLK_w;					// debug.
//assign	CAMERA_XCLK = CAMERA_XCLK_w;

parameter		TABLE_OV7670_MAX = 218;		// "ov7670.txt"
//parameter		TABLE_OV7670_MAX = 18;		// "ov7670_simple.txt"

reg	[7:0]		table_OV7670[TABLE_OV7670_MAX*2];

integer	i;

initial begin
	$readmemh("ov7670.txt",table_OV7670);
//	$readmemh("ov7670_simple.txt",table_OV7670);
end

wire	[9:0]	recordsetup_a;
wire	[9:0]	recordsetup_d;
wire			check_recordsetup_end;

assign	recordsetup_a[9:0] = (sequenceNumber - 10'd2) << 1;
assign	recordsetup_d[9:0] = ((sequenceNumber - 10'd2) << 1) + 10'd1;
assign	check_recordsetup_end = ((sequenceNumber - 10'd2) == TABLE_OV7670_MAX);

reg	[23:0]	timeInterval_setup = 24'd0;

always @(posedge CLOCK_50, negedge RST_N)
begin
	if (RST_N == 1'b0) begin
	
		functionNumber = 8'd0;
		sequenceNumber <= 10'd0;
		timeInterval_cameraSetup <= 24'd0;
		flagRUN <= 1'b0;
		
	end else begin
		//CAMERA_XCLK_w <= CAMERA_XCLK_w + 1'b1;		// debug.
	
		//----------------------------------------------------------------------------
		//	camera setup.
		//----------------------------------------------------------------------------
		if (functionNumber == 0) begin
			//	if (BUTTON01 == 1'b0) flagRUN <= 1'b1;	// debug trig button.
			if (timeInterval_cameraSetup == 32'd50000000) begin		// (32'd50000000=1sec)
				flagRUN <= 1'b1;
			end else begin
				timeInterval_cameraSetup <= timeInterval_cameraSetup + 24'd1;
			end

			if (flagRUN == 1'b1) begin
				flagRequest <= 1'b1;
				
				if (sequenceNumber>=10'd2 && sequenceNumber <=10'd999) begin
				
//					if (timeInterval_setup==24'd0) begin
//					
//						timeInterval_setup <= 24'd3;

						if (check_recordsetup_end) begin
							sequenceNumber <= 10'd888;
						end else begin
						
							DATA_ADDRESS[7:0] <= table_OV7670[recordsetup_a][7:0];
							DATA_IMAGE[7:0]   <= table_OV7670[recordsetup_d][7:0];
							flagReadMode      <= 1'b0;				// 0=write.
							flagMultiByteMode <= 1'b0;				// multi byte mode flag.
							
							sequenceNumber <= sequenceNumber + 10'd1;
						end
//					end else begin
//						timeInterval_setup <= timeInterval_setup - 24'd1;
//					end
				end

				
				case (sequenceNumber)
				0 : begin
						DATA_ADDRESS      <= 8'h0a;			// 0ah=product ID number PID.
						flagReadMode      <= 1'b1;				// 1=read.
						flagMultiByteMode <= 1'b0;				// multi byte mode flag.
						
						sequenceNumber    <= 10'd1;
					end
				1 : begin
						DATA_ADDRESS      <= 8'h0b;			// 0bh=product ID number VER.
						flagReadMode      <= 1'b1;				// 1=read.
						flagMultiByteMode <= 1'b0;				// multi byte mode flag.
						
						sequenceNumber    <= 10'd2;
					end
					
				888 : begin
						sequenceNumber    <= 10'd999;
					end
				endcase
				
				functionNumber <= 8'd1;
			end
			
		end else if (functionNumber == 8'd1) begin
			if (flagBusy == 1'b1) begin
				flagRequest <= 1'b0;
			end else if (flagReady == 1'b1) begin
				flagRequest <= 1'b0;
				functionNumber <= 8'd2;
			end
		end else if (functionNumber == 8'd2) begin
			case (sequenceNumber)
			1 : ramAddress02[23:0] = 24'd10;
			2 : ramAddress02[23:0] = 24'd11;
			endcase
			if (sequenceNumber == 10'd1 || sequenceNumber == 10'd2) begin
				ramData02[7:0] = RECV_DATA[7:0];
				flagReadOK02 = 1'b1;
			end
			functionNumber <= 8'd3;
		end else if (functionNumber == 8'd3) begin
			flagReadOK02 = 1'b0;
			functionNumber <= 8'd4;
		end else if (functionNumber == 8'd4) begin
			if (sequenceNumber != 10'd999) begin
				functionNumber <= 8'd0;
			end
		end
	
		//----------------------------------------------------------------------------
		//	draw.
		//----------------------------------------------------------------------------
		if (y_count < 20'd45 || dot < 20'd320) begin
			r_val_bg[2:0] <= 3'b000;
			g_val_bg[2:0] <= 3'b000;
			b_val_bg[2:0] <= 3'b000;
		end else begin
			r_val_bg2[2:0] = (y_count[5:5] == 1'b1) ? {y_count[4:4], y_count[3:3], y_count[2:2]} : 3'b000;
			g_val_bg2[2:0] = (y_count[6:6] == 1'b1) ? {y_count[4:4], y_count[3:3], y_count[2:2]} : 3'b000;
			b_val_bg2[2:0] = (y_count[7:7] == 1'b1) ? {y_count[4:4], y_count[3:3], y_count[2:2]} : 3'b000;

			r_val_bg3[2:0] = (dot[6:6] == 1'b1) ? {dot[5:5], dot[4:4], dot[3:3]} : 3'b000;
			g_val_bg3[2:0] = (dot[7:7] == 1'b1) ? {dot[5:5], dot[4:4], dot[3:3]} : 3'b000;
			b_val_bg3[2:0] = (dot[8:8] == 1'b1) ? {dot[5:5], dot[4:4], dot[3:3]} : 3'b000;

			r_val_bg3[3:0] = {1'b0, r_val_bg3[2:0]} + r_val_bg2[2:0];
			g_val_bg3[3:0] = {1'b0, g_val_bg3[2:0]} + g_val_bg2[2:0];
			b_val_bg3[3:0] = {1'b0, b_val_bg3[2:0]} + b_val_bg2[2:0];
			
			r_val_bg[2:0] <= (r_val_bg3[3:3]) ? 3'b111 : r_val_bg3[2:0];
			g_val_bg[2:0] <= (g_val_bg3[3:3]) ? 3'b111 : g_val_bg3[2:0];
			b_val_bg[2:0] <= (b_val_bg3[3:3]) ? 3'b111 : b_val_bg3[2:0];

		end
		
		if (timeInterval_box1 == 24'd4000000) begin
			if (flag_box1 == 1'b0) begin
				flag_box1 <= 1'b1;
				box1_x1 <= 10'd204;
				box1_y1 <= 10'd102;
				box1_x2 <= 10'd564;
				box1_y2 <= 10'd302;
			end else begin
				flag_box1 <= 1'b0;
				box1_x1 <= 10'd200;
				box1_y1 <= 10'd100;
				box1_x2 <= 10'd560;
				box1_y2 <= 10'd300;
			end
			timeInterval_box1 <= 24'd0;
		end else begin
			timeInterval_box1 <= timeInterval_box1 + 24'd1;
		end
		
		if (timeInterval_box2 == 24'd3000000) begin
			if (flag_box2 == 1'b0) begin
				flag_box2 <= 1'b1;
				box2_x1 <= 10'd644;
				box2_y1 <= 10'd122;
				box2_x2 <= 10'd1004;
				box2_y2 <= 10'd322;
			end else begin
				flag_box2 <= 1'b0;
				box2_x1 <= 10'd640;
				box2_y1 <= 10'd120;
				box2_x2 <= 10'd1000;
				box2_y2 <= 10'd320;
			end
			timeInterval_box2 <= 24'd0;
		end else begin
			timeInterval_box2 <= timeInterval_box2 + 24'd1;
		end
/*		
		// 320,280
		if (timeInterval_line3 == 24'd100000) begin
			if (line3_y1 == 11'd100) begin
				if (line3_x1 < 11'd319) begin
					line3_x1 <= line3_x1 + 11'd1;
					line3_x2 <= line3_x2 - 11'd1;
					line3_y1 <= 11'd100;
					line3_y2 <= 11'd279;
				end else begin
					line3_x1 <= 11'd319;
					line3_x2 <= 11'd0;
					line3_y1 <= 11'd101;
					line3_y2 <= 11'd278;
				end
			end else if (line3_y1 < 11'd279) begin
				if (line3_x1 == 11'd319) begin
					line3_y1 <= line3_y1 + 11'd1;
					line3_y2 <= line3_y2 - 11'd1;
					line3_x1 <= 11'd319;
					line3_x2 <= 11'd0;
				end else begin
					line3_y1 <= line3_y1 - 11'd1;
					line3_y2 <= line3_y2 + 11'd1;
					line3_x1 <= 11'd0;
					line3_x2 <= 11'd319;
				end
			end else begin // if (line4_y1 == 11'd279) begin
				if (line3_x1 > 11'd0) begin
					line3_x1 <= line3_x1 - 11'd1;
					line3_x2 <= line3_x2 + 11'd1;
					line3_y1 <= 11'd279;
					line3_y2 <= 11'd100;
				end else begin
					line3_x1 <= 11'd0;
					line3_x2 <= 11'd319;
					line3_y1 <= 11'd278;
					line3_y2 <= 11'd101;
				end
			end
			timeInterval_line3 <= 24'd0;
		end else begin
			timeInterval_line3 <= timeInterval_line3 + 24'd1;
		end
		
		
		if (timeInterval_line4 == 24'd100000) begin
			if (line4_y1 == 11'd0) begin
				if (line4_x1 < 11'd1279) begin
					line4_x1 <= line4_x1 + 11'd1;
					line4_x2 <= line4_x2 - 11'd1;
					line4_y1 <= 11'd0;
					line4_y2 <= 11'd479;
				end else begin
					line4_x1 <= 11'd1279;
					line4_x2 <= 11'd0;
					line4_y1 <= 11'd1;
					line4_y2 <= 11'd478;
				end
			end else if (line4_y1 < 11'd479) begin
				if (line4_x1 == 11'd1279) begin
					line4_y1 <= line4_y1 + 11'd1;
					line4_y2 <= line4_y2 - 11'd1;
					line4_x1 <= 11'd1279;
					line4_x2 <= 11'd0;
				end else begin
					line4_y1 <= line4_y1 - 11'd1;
					line4_y2 <= line4_y2 + 11'd1;
					line4_x1 <= 11'd0;
					line4_x2 <= 11'd1279;
				end
			end else if (line4_y1 == 11'd479) begin
				if (line4_x1 > 11'd0) begin
					line4_x1 <= line4_x1 - 11'd1;
					line4_x2 <= line4_x2 + 11'd1;
					line4_y1 <= 11'd479;
					line4_y2 <= 11'd0;
				end else begin
					line4_x1 <= 11'd0;
					line4_x2 <= 11'd1279;
					line4_y1 <= 11'd478;
					line4_y2 <= 11'd1;
				end
			end
			timeInterval_line4 <= 24'd0;
		end else begin
			timeInterval_line4 <= timeInterval_line4 + 24'd1;
		end
		
		
		if (timeInterval_line5 == 24'd200000) begin
			if (line5_y1 == 11'd0) begin
				if (line5_x1 < 11'd1279) begin
					line5_x1 <= line5_x1 + 11'd1;
					line5_x2 <= line5_x2 - 11'd1;
					line5_y1 <= 11'd0;
					line5_y2 <= 11'd479;
				end else begin
					line5_x1 <= 11'd1279;
					line5_x2 <= 11'd0;
					line5_y1 <= 11'd1;
					line5_y2 <= 11'd478;
				end
			end else if (line5_y1 < 11'd479) begin
				if (line5_x1 == 11'd1279) begin
					line5_y1 <= line5_y1 + 11'd1;
					line5_y2 <= line5_y2 - 11'd1;
					line5_x1 <= 11'd1279;
					line5_x2 <= 11'd0;
				end else begin
					line5_y1 <= line5_y1 - 11'd1;
					line5_y2 <= line5_y2 + 11'd1;
					line5_x1 <= 11'd0;
					line5_x2 <= 11'd1279;
				end
			end else if (line5_y1 == 11'd479) begin
				if (line5_x1 > 11'd0) begin
					line5_x1 <= line5_x1 - 11'd1;
					line5_x2 <= line5_x2 + 11'd1;
					line5_y1 <= 11'd479;
					line5_y2 <= 11'd0;
				end else begin
					line5_x1 <= 11'd0;
					line5_x2 <= 11'd1279;
					line5_y1 <= 11'd478;
					line5_y2 <= 11'd1;
				end
			end
			timeInterval_line5 <= 24'd0;
		end else begin
			timeInterval_line5 <= timeInterval_line5 + 24'd1;
		end
*/
	end
end

assign	VGA_R[2:0] = VGA_R_w[2:0];
assign	VGA_G[2:0] = VGA_G_w[2:0];
assign	VGA_B[2:0] = VGA_B_w[2:0];
assign	VGA_V_SYNC = VGA_V_SYNC_w;
assign	VGA_H_SYNC = VGA_H_SYNC_w;

assign r_val[2:0] = (flagOK_tx1) ? {r_val_tx1,r_val_tx1,r_val_tx1}  : 
//					(flagOK_line1) ? r_val_line1 : 
//					(flagOK_line2) ? r_val_line2 : 
//					(flagOK_line3) ? r_val_line3 : 
//					(flagOK_line4) ? r_val_line4 : 
//					(flagOK_line5) ? r_val_line5 : 
					(flagOK_box1) ? {r_val_box1,r_val_box1,r_val_box1} : 
					(flagOK_box2) ? {r_val_box2,r_val_box2,r_val_box2} : 
					(flagOK_cam1) ? r_val_cam1[2:0] : 
					r_val_bg[2:0];
					
assign g_val[2:0] = (flagOK_tx1) ? {g_val_tx1,g_val_tx1,g_val_tx1} : 
//					(flagOK_line1) ? g_val_line1 : 
//					(flagOK_line2) ? g_val_line2 : 
//					(flagOK_line3) ? g_val_line3 : 
//					(flagOK_line4) ? g_val_line4 : 
//					(flagOK_line5) ? g_val_line5 : 
					(flagOK_box1) ? {g_val_box1,g_val_box1,g_val_box1} : 
					(flagOK_box2) ? {g_val_box2,g_val_box1,g_val_box1} : 
					(flagOK_cam1) ? g_val_cam1[2:0] : 
					g_val_bg;
					
assign b_val[2:0] = (flagOK_tx1) ? {b_val_tx1,b_val_tx1,b_val_tx1} : 
//					(flagOK_line1) ? b_val_line1 : 
//					(flagOK_line2) ? b_val_line2 : 
//					(flagOK_line3) ? b_val_line3 : 
//					(flagOK_line4) ? b_val_line4 : 
//					(flagOK_line5) ? b_val_line5 : 
					(flagOK_box1) ? {b_val_box1,b_val_box1,b_val_box1} : 
					(flagOK_box2) ? {b_val_box2,b_val_box1,b_val_box1} : 
					(flagOK_cam1) ? b_val_cam1[2:0] : 
					b_val_bg;

endmodule
