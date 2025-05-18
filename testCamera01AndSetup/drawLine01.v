module drawLine01(
	input						CLOCK_50,
	input		[19:0]		dot,
	input 	[19:0]		y_count_in,
	
	input		[10:0]		x1,
	input		[10:0]		y1,
	input		[10:0]		x2,
	input		[10:0]		y2,
	input						r_color,
	input						g_color,
	input						b_color,
	
	output 	[0:0]			r_val,
	output  	[0:0]			g_val,
	output  	[0:0]			b_val,
	output 	[0:0]			flagOK
);

assign			flagOK = (compareDrawArea == 1'b0) ? 1'b0 : (x1[10:1]==x2[10:1]||y1==y2) ? 1'b1 : (compareXorY == 1'b0) ? compareX :  compareY;
assign			r_val = r_color;
assign			g_val = g_color;
assign			b_val = b_color;

wire	[10:0]	dotX;
assign			dotX[10:0] = dot[10:0] - 11'd320;

wire	[10:0]	y_count_45;
assign 			y_count_45[10:0] = y_count_in[10:0] - 11'd45;

reg	[0:0]		compareXorY = 1'b0;
reg	[21:0]	deltaStepX  = 22'd0;
reg	[21:0]	deltaStepY  = 22'd0;

reg	[0:0]		compareDrawArea = 1'b0;
reg	[10:0]	width  = 11'd0;
reg	[10:0]	height = 11'd0;

reg	[10:0]	deltaX   = 11'd0;
reg	[10:0]	deltaXX  = 11'd0;
reg	[0:0]		compareX = 1'b0;
reg	[10:0]	deltaY   = 11'd0;
reg	[0:0]		compareY = 1'b0;

reg	[3:0]		quadrant = 4'd0;

reg	[21:0]	baseX = 22'd0;
reg	[21:0]	baseY = 22'd0;

always @(posedge CLOCK_50)
begin
	if (dot[10:0] == 11'd0) begin									// x = H-Blank.
	
		if (x1 < x2) begin
			if (y1 < y2) begin
				quadrant <= 4'd0;
				width <= x2 - x1;
				height <= y2 - y1;
			end else begin
				quadrant <= 4'd1;
				width <= x2 - x1;
				height <= y1 - y2;
			end
		end else begin
			if (y1 < y2) begin
				quadrant <= 4'd2;
				width <= x1 - x2;
				height <= y2 - y1;
			end else begin
				quadrant <= 4'd3;
				width <= x1 - x2;
				height <= y1 - y2;
			end
		end
		
	end else if (dot[10:0] == 11'd1) begin						// x = H-Blank.
		compareXorY <= (width < height) ? 1'b0 : 1'b1;

	end else if(dot[10:0] < 11'd70) begin
		devide_deltaStepX();
		devide_deltaStepY();
		
	end else begin
	
		case (quadrant)
		0 : compareDrawArea <= (dotX[10:1] >= x1[10:1] && dotX[10:1] <= x2[10:1] && y_count_45 >= y1 && y_count_45 <= y2);
		1 : compareDrawArea <= (dotX[10:1] >= x1[10:1] && dotX[10:1] <= x2[10:1] && y_count_45 >= y2 && y_count_45 <= y1);
		2 : compareDrawArea <= (dotX[10:1] >= x2[10:1] && dotX[10:1] <= x1[10:1] && y_count_45 >= y1 && y_count_45 <= y2);
		3 : compareDrawArea <= (dotX[10:1] >= x2[10:1] && dotX[10:1] <= x1[10:1] && y_count_45 >= y2 && y_count_45 <= y1);
		endcase
		
		case (quadrant)
		0 : begin
				deltaX[10:0]	<= (deltaStepX * (y_count_45 - y1)) >> 11;
				deltaXX[10:0]	<= x1 + deltaX;
				compareX			<= (deltaXX[10:1] == dotX[10:1]) ? 1'b1 : 1'b0;
				deltaY[10:0]	<= (deltaStepY * (dotX - x1)) >> 11;
				compareY			<= (y1 + deltaY == y_count_45) ? 1'b1 : 1'b0;
			end
		1 : begin
				deltaX[10:0]	<= (deltaStepX * (y1 - y_count_45)) >> 11;
				deltaXX[10:0]	<= x1 + deltaX;
				compareX			<= (deltaXX[10:1] == dotX[10:1]) ? 1'b1 : 1'b0;
				deltaY[10:0]	<= (deltaStepY * (dotX - x1)) >> 11;
				compareY			<= (y1 - deltaY == y_count_45) ? 1'b1 : 1'b0;
			end
		2 : begin
				deltaX[10:0]	<= (deltaStepX * (y_count_45 - y1)) >> 11;
				deltaXX[10:0]	<= x1 - deltaX;
				compareX			<= (deltaXX[10:1] == dotX[10:1]) ? 1'b1 : 1'b0;
				deltaY[10:0]	<= (deltaStepY * (x1 - dotX)) >> 11;
				compareY			<= (y1 + deltaY == y_count_45) ? 1'b1 : 1'b0;
			end
		3 : begin
				deltaX[10:0]   <= (deltaStepX * (y1 - y_count_45)) >> 11;
				deltaXX[10:0]  <= x1 - deltaX;
				compareX			<= (deltaXX[10:1] == dotX[10:1]) ? 1'b1 : 1'b0;
				deltaY[10:0]   <= (deltaStepY * (x1 - dotX)) >> 11;
				compareY			<= (y1 - deltaY == y_count_45) ? 1'b1 : 1'b0;
			end
		endcase
	end
end

// ----------------------------------------------------------------------------------
//	division when multi clocks for X.
//
//	-i- height,height : square size.
//	-o- deltaStepX   : slope (fixed decimal point 11bits)
//
// equivalence this.
// 	deltaStepX <= {height, 11'd0} / {11'd0, height};
//
// ----------------------------------------------------------------------------------
task	devide_deltaStepX;
begin
	if (dot[10:0] == 11'd11) begin										// x = H-Blank.
		deltaStepX <= 22'd0;											// equivalence : deltaStepX <= {height, 11'd0} / {11'd0, height};
		baseX <= {width, 11'd0};

	end else if (dot[10:0] == 11'd12) begin							// x = H-Blank.
		if ({10'd0,baseX[21:0]} >= {height[10:0],21'd0}) begin
			baseX <= baseX - {height[0:0], 21'd0};
			deltaStepX <= deltaStepX + {1'b1, 21'd0};
		end

	end else if (dot[10:0] == 11'd13) begin							// x = H-Blank.
		if ({9'd0,baseX[21:0]} >= {height[10:0],20'd0}) begin
			baseX <= baseX - {height[1:0], 20'd0};
			deltaStepX <= deltaStepX + {2'b1, 20'd0};
		end

	end else if (dot[10:0] == 11'd14) begin							// x = H-Blank.
		if ({8'd0,baseX[21:0]} >= {height[10:0],19'd0}) begin
			baseX <= baseX - {height[2:0], 19'd0};
			deltaStepX <= deltaStepX + {3'b1, 19'd0};
		end

	end else if (dot[10:0] == 11'd15) begin							// x = H-Blank.
		if ({7'd0,baseX[21:0]} >= {height[10:0],18'd0}) begin
			baseX <= baseX - {height[3:0], 18'd0};
			deltaStepX <= deltaStepX + {4'b1, 18'd0};
		end

	end else if (dot[10:0] == 11'd16) begin							// x = H-Blank.
		if ({6'd0,baseX[21:0]} >= {height[10:0],17'd0}) begin
			baseX <= baseX - {height[4:0], 17'd0};
			deltaStepX <= deltaStepX + {5'b1, 17'd0};
		end

	end else if (dot[10:0] == 11'd17) begin							// x = H-Blank.
		if ({5'd0,baseX[21:0]} >= {height[10:0],16'd0}) begin
			baseX <= baseX - {height[5:0], 16'd0};
			deltaStepX <= deltaStepX + {6'b1, 16'd0};
		end

	end else if (dot[10:0] == 11'd18) begin							// x = H-Blank.
		if ({4'd0,baseX[21:0]} >= {height[10:0],15'd0}) begin
			baseX <= baseX - {height[6:0], 15'd0};
			deltaStepX <= deltaStepX + {7'b1, 15'd0};
		end

	end else if (dot[10:0] == 11'd19) begin							// x = H-Blank.
		if ({3'd0,baseX[21:0]} >= {height[10:0],14'd0}) begin		// 25'b0_00yy_yyyy_yyyy_yyyy_yyyy_yyyy >= 25'bo_ooxx_xxxx_xx00_0000_0000_0000  <= compare 8bit upper bit. 
			baseX <= baseX - {height[7:0], 14'd0};
			deltaStepX <= deltaStepX + {8'b1, 14'd0};
		end

	end else if (dot[10:0] == 11'd20) begin							// x = H-Blank.
		if ({2'd0,baseX[21:0]} >= {height[10:0],13'd0}) begin		// 24'b00yy_yyyy_yyyy_yyyy_yyyy_yyyy >= 24'booxx_xxxx_xxx0_0000_0000_0000  <= compare 9bit upper bit. 
			baseX <= baseX - {height[8:0], 13'd0};
			deltaStepX <= deltaStepX + {9'b1, 13'd0};
		end

	end else if (dot[10:0] == 11'd21) begin							// x = H-Blank.
		if ({1'd0,baseX[21:0]} >= {height[10:0],12'd0}) begin		// 23'b0yy_yyyy_yyyy_yyyy_yyyy_yyyy >= 23'boxx_xxxx_xxxx_0000_0000_0000  <= compare 10bit upper bit. 
			baseX <= baseX - {height[9:0], 12'd0};
			deltaStepX <= deltaStepX + {10'b1, 12'd0};
		end

	end else if (dot[10:0] == 11'd22) begin							// x = H-Blank.
		if (baseX[21:0] >= {height[10:0],11'd0}) begin				// 22'byy_yyyy_yyyy_yyyy_yyyy_yyyy  >= 22'bxx_xxxx_xxxx_x000_0000_0000  <= **** just 22bit length value ****
			baseX <= baseX - {height[10:0], 11'd0};
			deltaStepX <= deltaStepX + {11'b1, 11'd0};
		end

	end else if (dot[10:0] == 11'd23) begin							// x = H-Blank.
		if (baseX[21:0] >= {1'd0, height[10:0],10'd0}) begin		// 22'byy_yyyy_yyyy_yyyy_yyyy_yyyy  >= 22'b0x_xxxx_xxxx_xx00_0000_0000  <= compare 22bit value and 21bit value (from first digit)
			baseX <= baseX - {1'd0, height[10:0], 10'd0};
			deltaStepX <= deltaStepX + {12'b1, 10'd0};
		end

	end else if (dot[10:0] == 11'd24) begin							// x = H-Blank.
		if (baseX[20:0] >= {2'd0, height[10:0],9'd0}) begin		// 21'by_yyyy_yyyy_yyyy_yyyy_yyyy  >= 21'b0_xxxx_xxxx_xxx0_0000_0000  <= compare 21bit value and 20bit value. 
			baseX <= baseX - {2'd0, height[10:0], 9'd0};
			deltaStepX <= deltaStepX + {13'b1, 9'd0};
		end
		
	end else if (dot[10:0] == 11'd25) begin							// x = H-Blank.
		if (baseX[19:0] >= {3'd0, height[10:0],8'd0}) begin		// 20'byyyy_yyyy_yyyy_yyyy_yyyy  >= 20'b0xxx_xxxx_xxxx_0000_0000  <= compare 20bit value and 19bit value. 
			baseX <= baseX - {3'd0, height[10:0], 8'd0};
			deltaStepX <= deltaStepX + {14'b1, 8'd0};
		end

	end else if (dot[10:0] == 11'd26) begin						// x = H-Blank.
		if (baseX[18:0] >= {4'd0, height[10:0],7'd0}) begin
			baseX <= baseX - {4'd0, height[10:0], 7'd0};
			deltaStepX <= deltaStepX + {15'b1, 7'd0};
		end

	end else if (dot[10:0] == 11'd27) begin						// x = H-Blank.
		if (baseX[17:0] >= {5'd0, height[10:0],6'd0}) begin
			baseX <= baseX - {5'd0, height[10:0], 6'd0};
			deltaStepX <= deltaStepX + {16'b1, 6'd0};
		end

	end else if (dot[10:0] == 11'd28) begin						// x = H-Blank.
		if (baseX[16:0] >= {6'd0, height[10:0],5'd0}) begin
			baseX <= baseX - {6'd0, height[10:0], 5'd0};
			deltaStepX <= deltaStepX + {17'b1, 5'd0};
		end

	end else if (dot[10:0] == 11'd29) begin						// x = H-Blank.
		if (baseX[15:0] >= {7'd0, height[10:0],4'd0}) begin
			baseX <= baseX - {7'd0, height[10:0], 4'd0};
			deltaStepX <= deltaStepX + {18'b1, 4'd0};
		end

	end else if (dot[10:0] == 11'd30) begin						// x = H-Blank.
		if (baseX[14:0] >= {8'd0, height[10:0],3'd0}) begin
			baseX <= baseX - {8'd0, height[10:0], 3'd0};
			deltaStepX <= deltaStepX + {19'b1, 3'd0};
		end

	end else if (dot[10:0] == 11'd31) begin						// x = H-Blank.
		if (baseX[13:0] >= {9'd0, height[10:0],2'd0}) begin
			baseX <= baseX - {9'd0, height[10:0], 2'd0};
			deltaStepX <= deltaStepX + {20'b1, 2'd0};
		end

	end else if (dot[10:0] == 11'd32) begin						// x = H-Blank.
		if (baseX[12:0] >= {10'd0, height[10:0],1'd0}) begin
			baseX <= baseX - {10'd0, height[10:0], 1'd0};
			deltaStepX <= deltaStepX + {21'b1, 1'd0};
		end

	end else if (dot[10:0] == 11'd33) begin						// x = H-Blank.
		if (baseX[11:0] >= {11'd0, height[10:0]}) begin
			baseX <= baseX - {11'd0, height[10:0]};
			deltaStepX <= deltaStepX + 22'd1;
		end
	end
end
endtask

// ----------------------------------------------------------------------------------
//	division when multi clocks for Y.
//
//	-i- width,height : square size.
//	-o- deltaStepY   : slope (fixed decimal point 11bits)
//
// equivalence this.
//		deltaStepY <= {height, 11'd0} / {11'd0, width};
//
// ----------------------------------------------------------------------------------
task	devide_deltaStepY;
begin
	if (dot[10:0] == 11'd41) begin										// x = H-Blank.
		deltaStepY <= 22'd0;													// equivalence : deltaStepY <= {height, 11'd0} / {11'd0, width};
		baseY <= {height, 11'd0};

	end else if (dot[10:0] == 11'd42) begin							// x = H-Blank.
		if ({10'd0,baseY[21:0]} >= {width[10:0],21'd0}) begin
			baseY <= baseY - {width[0:0], 21'd0};
			deltaStepY <= deltaStepY + {1'b1, 21'd0};
		end

	end else if (dot[10:0] == 11'd43) begin							// x = H-Blank.
		if ({9'd0,baseY[21:0]} >= {width[10:0],20'd0}) begin
			baseY <= baseY - {width[1:0], 20'd0};
			deltaStepY <= deltaStepY + {2'b1, 20'd0};
		end

	end else if (dot[10:0] == 11'd44) begin							// x = H-Blank.
		if ({8'd0,baseY[21:0]} >= {width[10:0],19'd0}) begin
			baseY <= baseY - {width[2:0], 19'd0};
			deltaStepY <= deltaStepY + {3'b1, 19'd0};
		end

	end else if (dot[10:0] == 11'd45) begin							// x = H-Blank.
		if ({7'd0,baseY[21:0]} >= {width[10:0],18'd0}) begin
			baseY <= baseY - {width[3:0], 18'd0};
			deltaStepY <= deltaStepY + {4'b1, 18'd0};
		end

	end else if (dot[10:0] == 11'd46) begin							// x = H-Blank.
		if ({6'd0,baseY[21:0]} >= {width[10:0],17'd0}) begin
			baseY <= baseY - {width[4:0], 17'd0};
			deltaStepY <= deltaStepY + {5'b1, 17'd0};
		end

	end else if (dot[10:0] == 11'd47) begin							// x = H-Blank.
		if ({5'd0,baseY[21:0]} >= {width[10:0],16'd0}) begin
			baseY <= baseY - {width[5:0], 16'd0};
			deltaStepY <= deltaStepY + {6'b1, 16'd0};
		end

	end else if (dot[10:0] == 11'd48) begin							// x = H-Blank.
		if ({4'd0,baseY[21:0]} >= {width[10:0],15'd0}) begin
			baseY <= baseY - {width[6:0], 15'd0};
			deltaStepY <= deltaStepY + {7'b1, 15'd0};
		end

	end else if (dot[10:0] == 11'd49) begin							// x = H-Blank.
		if ({3'd0,baseY[21:0]} >= {width[10:0],14'd0}) begin	// 25'b0_00yy_yyyy_yyyy_yyyy_yyyy_yyyy >= 25'bo_ooxx_xxxx_xx00_0000_0000_0000  <= compare 8bit upper bit. 
			baseY <= baseY - {width[7:0], 14'd0};
			deltaStepY <= deltaStepY + {8'b1, 14'd0};
		end

	end else if (dot[10:0] == 11'd50) begin						// x = H-Blank.
		if ({2'd0,baseY[21:0]} >= {width[10:0],13'd0}) begin	// 24'b00yy_yyyy_yyyy_yyyy_yyyy_yyyy >= 24'booxx_xxxx_xxx0_0000_0000_0000  <= compare 9bit upper bit. 
			baseY <= baseY - {width[8:0], 13'd0};
			deltaStepY <= deltaStepY + {9'b1, 13'd0};
		end

	end else if (dot[10:0] == 11'd51) begin						// x = H-Blank.
		if ({1'd0,baseY[21:0]} >= {width[10:0],12'd0}) begin	// 23'b0yy_yyyy_yyyy_yyyy_yyyy_yyyy >= 23'boxx_xxxx_xxxx_0000_0000_0000  <= compare 10bit upper bit. 
			baseY <= baseY - {width[9:0], 12'd0};
			deltaStepY <= deltaStepY + {10'b1, 12'd0};
		end

	end else if (dot[10:0] == 11'd52) begin						// x = H-Blank.
		if (baseY[21:0] >= {width[10:0],11'd0}) begin			// 22'byy_yyyy_yyyy_yyyy_yyyy_yyyy  >= 22'bxx_xxxx_xxxx_x000_0000_0000  <= **** just 22bit length value ****
			baseY <= baseY - {width[10:0], 11'd0};
			deltaStepY <= deltaStepY + {11'b1, 11'd0};
		end

	end else if (dot[10:0] == 11'd53) begin						// x = H-Blank.
		if (baseY[21:0] >= {1'd0, width[10:0],10'd0}) begin	// 22'byy_yyyy_yyyy_yyyy_yyyy_yyyy  >= 22'b0x_xxxx_xxxx_xx00_0000_0000  <= compare 22bit value and 21bit value (from first digit)
			baseY <= baseY - {1'd0, width[10:0], 10'd0};
			deltaStepY <= deltaStepY + {12'b1, 10'd0};
		end

	end else if (dot[10:0] == 11'd54) begin						// x = H-Blank.
		if (baseY[20:0] >= {2'd0, width[10:0],9'd0}) begin		// 21'by_yyyy_yyyy_yyyy_yyyy_yyyy  >= 21'b0_xxxx_xxxx_xxx0_0000_0000  <= compare 21bit value and 20bit value. 
			baseY <= baseY - {2'd0, width[10:0], 9'd0};
			deltaStepY <= deltaStepY + {13'b1, 9'd0};
		end
		
	end else if (dot[10:0] == 11'd55) begin						// x = H-Blank.
		if (baseY[19:0] >= {3'd0, width[10:0],8'd0}) begin		// 20'byyyy_yyyy_yyyy_yyyy_yyyy  >= 20'b0xxx_xxxx_xxxx_0000_0000  <= compare 20bit value and 19bit value. 
			baseY <= baseY - {3'd0, width[10:0], 8'd0};
			deltaStepY <= deltaStepY + {14'b1, 8'd0};
		end

	end else if (dot[10:0] == 11'd56) begin						// x = H-Blank.
		if (baseY[18:0] >= {4'd0, width[10:0],7'd0}) begin
			baseY <= baseY - {4'd0, width[10:0], 7'd0};
			deltaStepY <= deltaStepY + {15'b1, 7'd0};
		end

	end else if (dot[10:0] == 11'd57) begin						// x = H-Blank.
		if (baseY[17:0] >= {5'd0, width[10:0],6'd0}) begin
			baseY <= baseY - {5'd0, width[10:0], 6'd0};
			deltaStepY <= deltaStepY + {16'b1, 6'd0};
		end

	end else if (dot[10:0] == 11'd58) begin						// x = H-Blank.
		if (baseY[16:0] >= {6'd0, width[10:0],5'd0}) begin
			baseY <= baseY - {6'd0, width[10:0], 5'd0};
			deltaStepY <= deltaStepY + {17'b1, 5'd0};
		end

	end else if (dot[10:0] == 11'd59) begin						// x = H-Blank.
		if (baseY[15:0] >= {7'd0, width[10:0],4'd0}) begin
			baseY <= baseY - {7'd0, width[10:0], 4'd0};
			deltaStepY <= deltaStepY + {18'b1, 4'd0};
		end

	end else if (dot[10:0] == 11'd60) begin						// x = H-Blank.
		if (baseY[14:0] >= {8'd0, width[10:0],3'd0}) begin
			baseY <= baseY - {8'd0, width[10:0], 3'd0};
			deltaStepY <= deltaStepY + {19'b1, 3'd0};
		end

	end else if (dot[10:0] == 11'd61) begin						// x = H-Blank.
		if (baseY[13:0] >= {9'd0, width[10:0],2'd0}) begin
			baseY <= baseY - {9'd0, width[10:0], 2'd0};
			deltaStepY <= deltaStepY + {20'b1, 2'd0};
		end

	end else if (dot[10:0] == 11'd62) begin						// x = H-Blank.
		if (baseY[12:0] >= {10'd0, width[10:0],1'd0}) begin
			baseY <= baseY - {10'd0, width[10:0], 1'd0};
			deltaStepY <= deltaStepY + {21'b1, 1'd0};
		end

	end else if (dot[10:0] == 11'd63) begin						// x = H-Blank.
		if (baseY[11:0] >= {11'd0, width[10:0]}) begin
			baseY <= baseY - {11'd0, width[10:0]};
			deltaStepY <= deltaStepY + 22'd1;
		end
	end
end
endtask

endmodule
