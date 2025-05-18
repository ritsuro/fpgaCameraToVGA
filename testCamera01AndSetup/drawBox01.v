module drawBox01(
	input		[19:0]		dot,
	input 	[19:0]		y_count_in,
	
	input		[10:0]		x1,
	input		[10:0]		y1,
	input		[10:0]		x2,
	input		[10:0]		y2,
	input						r_color,
	input						g_color,
	input						b_color,
	
	output  	[0:0]			r_val,
	output  	[0:0]			g_val,
	output  	[0:0]			b_val,
	output 	[0:0]			flagOK
);

wire	[10:0]	dotX1;
wire	[10:0]	dotX2;
assign			dotX1[10:0] = dot[10:0] - 11'd320;
assign			dotX2[10:0] = dot[10:0] - 11'd320 + 11'd1;

wire	[10:0]	y_count_45;
assign 			y_count_45[10:0] = y_count_in[10:0] - 11'd45;

wire				compareHorizon;
assign			compareHorizon = ((y_count_45 == y1 || y_count_45 == y2) && x1 <= dotX1 && x2 >= dotX2);

wire				compareVertical;
assign			compareVertical = ((x1 == dotX1 || x1 == dotX2 || x2 == dotX1 || x2 == dotX2) && y_count_45 >= y1 && y_count_45 < y2);

assign			flagOK = (compareHorizon) ? 1'b1 : (compareVertical) ? 1'b1 : 1'b0;

assign 			r_val = r_color;
assign 			g_val = g_color;
assign 			b_val = b_color;

endmodule
