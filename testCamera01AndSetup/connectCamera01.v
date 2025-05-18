module connectCamera01(
	input						CLOCK_50,
	input						RST_N,
	input			[19:0]	dot,
	input 		[19:0]	y_count_in,

	input						VGA_V_SYNC,
	
	input						CAMERA_PCLK,
	input						CAMERA_V_SYNC,
	input						CAMERA_HREF,
	input			[7:0]		CAMERA_D,
	
	output					CAMERA_XCLK,

	output reg	[23:0]	debug_ramAddress 	= 24'd0,
	output reg	[15:0]	debug_ramData 		= 16'd0,
	output reg	[0:0]		debug_flagReadOK 	= 1'b0,

	output reg	[2:0]		r_val 		= 3'b0,
	output reg	[2:0]		g_val 		= 3'b0,
	output reg	[2:0]		b_val 		= 3'b0,
	output reg	[0:0]		flagOK 		= 1'b0
);

reg	[3:0]		clock_50_count 			= 4'd0;
reg	[7:0]		clock_50_48_count 		= 8'd0;

reg				flag_CAMERA_PCLK_old 	= 1'b0;
reg	[15:0]	count_CAMERA_PCLK 		= 16'd0;
reg	[15:0]	count_CAMERA_PCLK_max 	= 16'd0;

reg	[7:0]		dataFirstByte 				= 8'd0;
reg	[7:0]		dataSecondByte 			= 8'd0;
reg				flagDataSecondByte 		= 1'b0;

reg				flag_CAMERA_V_SYNC_old 	= 1'b0;
reg	[15:0]	count_CAMERA_V_SYNC 		= 16'd0;

reg				flag_CAMERA_HREF_old 	= 1'b0;
reg	[15:0]	count_CAMERA_HREF 		= 16'd0;
reg	[15:0]	count_CAMERA_HREF_max 	= 16'd0;

reg	[15:0]	count_VGA_VSYNC 			= 16'd0;

reg	[7:0]		sequence_debug_table 	= 8'd0;

wire	[10:0]	dotX;
wire	[10:0]	dotX_read;
assign			dotX[10:0] = dot[10:0] - 11'd320;
assign			dotX_read[10:0] = dotX[10:0] + 11'd1;

reg	[19:0]	y_count_45;
reg	[12:0]	y_double_buffer;
reg	[12:0]	recordForImage;

reg	[2:0]		tableImageR[1280];
reg	[2:0]		tableImageG[1280];
reg	[2:0]		tableImageB[1280];

wire	[15:0]	offsetImage;
assign 			offsetImage[15:0] = count_CAMERA_PCLK[15:1] + ((count_CAMERA_HREF[0:0]==1'b1) ? 640 : 0);

reg				flagCameraVSyncWait = 1'b0;
reg	[15:0]	old_sync_count_CAMERA_HREF = 16'd0;

initial begin
end

always @(posedge CLOCK_50, negedge RST_N)
begin
	if (RST_N == 1'b0) begin
		clock_50_count <= 4'd0;
		clock_50_48_count <= 8'd0;
		
		flag_CAMERA_PCLK_old <= 1'b0;
		count_CAMERA_PCLK <= 16'd0;
		
		flagDataSecondByte = 1'b0;
		
		count_CAMERA_HREF_max <= 16'd0;
		count_CAMERA_PCLK_max <= 16'd0;
		
		flagCameraVSyncWait <= 1'b0;
	
		debug_ramAddress <= 24'd0;
		debug_ramData    <= 16'd0;
		debug_flagReadOK <= 1'b0;

		r_val <= 3'd0;
		g_val <= 3'd0;
		b_val <= 3'd0;
		flagOK <= 1'b0;
	end else begin
		// ------------------------------------------------------------------------ camera clock seed.
		clock_50_count = clock_50_count + 4'd1;					// block.
		if (clock_50_48_count == 8'd100) begin
			clock_50_48_count = 8'd1;									// block.
		end else begin
			clock_50_48_count = clock_50_48_count + 8'd1;		// block.
		end
		
		// ------------------------------------------------------------------------ camera wide calc.
		if (flag_CAMERA_PCLK_old != CAMERA_PCLK) begin
			flag_CAMERA_PCLK_old <= CAMERA_PCLK;
			if (CAMERA_PCLK == 1'b1) begin
				count_CAMERA_PCLK <= count_CAMERA_PCLK + 16'd1;
				
				if (count_CAMERA_PCLK_max < count_CAMERA_PCLK + 16'd1) begin
					count_CAMERA_PCLK_max <= count_CAMERA_PCLK + 16'd1;
				end
			end
		end

		// ------------------------------------------------------------------------ camera height calc.
		if (flag_CAMERA_HREF_old != CAMERA_HREF) begin
			flag_CAMERA_HREF_old <= CAMERA_HREF;
			if (CAMERA_HREF == 1'b1) begin
				count_CAMERA_HREF <= count_CAMERA_HREF + 16'd1;
				
				if (count_CAMERA_HREF_max < count_CAMERA_HREF + 16'd1) begin
					count_CAMERA_HREF_max <= count_CAMERA_HREF + 16'd1;
				end
			end
		end
		
		// ------------------------------------------------------------------------ camera data calc.
		if (CAMERA_HREF == 1'b1) begin
			if (flagDataSecondByte == 1'b0) begin
				flagDataSecondByte = 1'b1;
				dataFirstByte <= CAMERA_D;
			end else begin
				flagDataSecondByte = 1'b0;
				dataSecondByte <= CAMERA_D;
			end
		end else begin
			flagDataSecondByte = 1'b0;
			dataFirstByte <= 8'd0;
			dataSecondByte <= 8'd0;
			count_CAMERA_PCLK <= 16'd0;
		end
		
		// ------------------------------------------------------------------------ camera V-Sync count calc.
		if (flag_CAMERA_V_SYNC_old != CAMERA_V_SYNC) begin
			flag_CAMERA_V_SYNC_old <= CAMERA_V_SYNC;
			if (CAMERA_V_SYNC == 1'b0) begin
				count_CAMERA_V_SYNC <= count_CAMERA_V_SYNC + 16'd1;
				count_CAMERA_HREF <= 16'd0;
			end
		end
		
		// ------------------------------------------------------------------------ camera V-Sync and VGA V-Sync synchronize.
		if (old_sync_count_CAMERA_HREF != count_CAMERA_HREF && count_CAMERA_HREF == 16'd100) begin
			flagCameraVSyncWait <= VGA_V_SYNC;
		end else if (flagCameraVSyncWait == 1'b1) begin
			flagCameraVSyncWait <= VGA_V_SYNC;
		end

		old_sync_count_CAMERA_HREF <= count_CAMERA_HREF;

		// ------------------------------------------------------------------------ VGA V-Sync calc.
		if (y_count_in == 20'd1 && dot == 20'd1) begin
			count_VGA_VSYNC <= count_VGA_VSYNC + 16'd1;
		end
		
		// ------------------------------------------------------------------------ debug display set.
		debug_ramAddress <= sequence_debug_table;
		
		case (sequence_debug_table)
			0 : debug_ramData <= count_CAMERA_PCLK;
			1 : debug_ramData <= dataFirstByte;
			2 : debug_ramData <= dataSecondByte;
			3 : debug_ramData <= count_CAMERA_HREF;
			4 : debug_ramData <= count_CAMERA_V_SYNC;
			5 : debug_ramData <= count_VGA_VSYNC;
			6 : debug_ramData <= count_CAMERA_PCLK_max;
			7 : debug_ramData <= count_CAMERA_HREF_max;
		endcase

		if (sequence_debug_table < 8'd7) begin
			sequence_debug_table <= sequence_debug_table + 8'd1;
		end else begin
			sequence_debug_table <= 8'd0;
		end
		
		debug_flagReadOK <= 1'b1;
		
		// ------------------------------------------------------------------------ image set to register tables.
		if (CAMERA_HREF == 1'b1 && count_CAMERA_HREF < 16'd480 && count_CAMERA_PCLK < 16'd1280 && flagDataSecondByte == 1'b0) begin
		
//			// gray scale.
//			tableImageR[offsetImage] <= dataFirstByte[7:7] | dataFirstByte[6:6];
//			tableImageG[offsetImage] <= dataFirstByte[7:7] | dataFirstByte[6:6] | dataFirstByte[5:5];
//			tableImageB[offsetImage] <= dataFirstByte[7:7] | dataFirstByte[6:6] | dataFirstByte[5:5] | dataFirstByte[4:4];
			
//			// RGB565
//			tableImageR[offsetImage] <= (dataFirstByte[7:3] >= 5'd12) ? 1'b1 : 1'b0;
//			tableImageG[offsetImage] <= ({dataFirstByte[2:0], dataSecondByte[7:5]} >= 6'd24) ? 1'b1 : 1'b0;
//			tableImageB[offsetImage] <= (dataSecondByte[4:0] >= 5'd12) ? 1'b1 : 1'b0;

			// RGB565
//			tableImageR[offsetImage][2:0] <= dataFirstByte[7:5];		// dataFirstByte[7:3]
//			tableImageG[offsetImage][2:0] <= dataFirstByte[2:0];		// {dataFirstByte[2:0], dataSecondByte[7:5]}
//			tableImageB[offsetImage][2:0] <= dataSecondByte[4:2];		// dataSecondByte[4:0] 

			tableImageR[offsetImage][2:0] <= dataSecondByte[7:5];		// dataFirstByte[7:3]
			tableImageG[offsetImage][2:0] <= dataSecondByte[2:0];		// {dataFirstByte[2:0], dataSecondByte[7:5]}
			tableImageB[offsetImage][2:0] <= dataFirstByte[4:2];		// dataSecondByte[4:0] 
	
		end

		// ------------------------------------------------------------------------ image tables record calc.
		if (dot[10:0] == 11'd0) begin																	// x = H-Blank.
			y_count_45[19:0] <= y_count_in[19:0] - 20'd45;										//
		end else if (dot[10:0] == 11'd1) begin														// x = H-Blank.
			y_double_buffer[12:0] <= (y_count_45[0:0]==1'b0) ? 12'd640 : 12'd0;			//
		end else begin																						//
			recordForImage[12:0] <= {3'b0, dotX_read[10:1]} + y_double_buffer[12:0];	// RGB table record.
		end

		// ------------------------------------------------------------------------ image tables to VGA output.
		if (y_count_in >= 20'd45 && y_count_in < 20'd525 && count_CAMERA_HREF >= 16'd120 && count_CAMERA_HREF < 16'd360) begin
			flagOK = 1'b1;
			if (dot >= 20'd320 && dot < 20'd1600) begin											// dot >= 320 && dot < 320 + 640*2
				r_val[2:0] <= tableImageR[recordForImage][2:0];
				g_val[2:0] <= tableImageG[recordForImage][2:0];
				b_val[2:0] <= tableImageB[recordForImage][2:0];
			end else begin
				r_val[2:0] <= 3'd0;
				g_val[2:0] <= 3'd0;
				b_val[2:0] <= 3'd0;
			end
		end else begin
			flagOK <= 1'b1;
			r_val[2:0] <= 3'd0;
			g_val[2:0] <= 3'd0;
			b_val[2:0] <= 3'd0;
		end
	end
end

assign	CAMERA_XCLK = (flagCameraVSyncWait == 1'b1) ? 1'b0 : (clock_50_48_count[7:0] < 8'd96) ? clock_50_count[0:0] : 1'b0;

endmodule
