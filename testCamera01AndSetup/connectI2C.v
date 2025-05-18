// I2C.
module connectI2C (
	input						CLOCK_50,
	input						RST_N,
	
	inout						I2C_SCLK,
	inout						I2C_SDAT,

	input			[7:0]		SLAVE_ADDRESS,
	input			[7:0]		DATA_ADDRESS,
	input			[7:0]		DATA_IMAGE,
	output reg	[7:0]		RECV_DATA,
	output reg	[7:0]		RECV_DATA02,
	output reg	[7:0]		RECV_DATA03,
	output reg	[7:0]		RECV_DATA04,
	output reg	[7:0]		RECV_DATA05,
	output reg	[7:0]		RECV_DATA06,
	
	input						flagRequest,			// Please clearing is flag when after flagBusy==1 or flagReady==1.
	input						flagReadMode,			// read mode flag.
	input						flagMultiByteMode,	// multi byte mode flag.
	input			[3:0]		countMultiByte,		// multi byte byte count.(2~6)
	
	output	reg			flagBusy = 1'b0,		// This flag at request period immediately. End is stop condition.
	output	reg			flagReady = 1'b0		// This flag at one clock only.
);

reg	[9:0]		CLOCK_COUNT = 10'd0;
reg	[7:0]		SDAT_COUNTER = 8'd0;

reg	[0:0]		SCLK = 1'b1;
reg	[0:0]		SDAT = 1'b1;

reg	[0:0]		CLOCKS = 1'b0;

reg	[0:0]		flagReadData = 1'b0;

reg	[0:0]		flagNoACK = 1'b0;

reg	[0:0]		flagStartCondition = 1'b0;

reg	[0:0]		flagStopCondition = 1'b0;

reg	[0:0]		flagCatchACK = 1'b0;
reg	[0:0]		ACK = 1'b0;

reg	[0:0]		flagCatchData = 1'b0;
reg	[0:0]		RECV_SDAT = 1'b0;

reg	[0:0]		flagSendACK = 1'b0;

reg	[0:0]		flagMultiByte = 1'b0;

reg	[0:0]		flagReadSkipEnd = 1'b0;

reg	[0:0]		flagGoMultiByteLoop = 1'b0;

wire				I2C_SCLK_w;
wire				I2C_SDAT_w;

// base : assign I2C_SCLK_w = (CLOCKS == 1'b1) ? (~CLOCK_COUNT[9]) : SCLK;
assign			I2C_SCLK_w = (CLOCKS == 1'b1) ? ( (CLOCK_COUNT[9]) ? (CLOCK_COUNT[8:6] == 3'b111) : !(CLOCK_COUNT[8:6] == 3'b111)) : SCLK;

assign			I2C_SDAT_w = SDAT;

assign			I2C_SCLK = (I2C_SCLK_w) ? 1'bz : 1'b0;		// pullup output (high impedance) SCL.
assign			I2C_SDAT = (I2C_SDAT_w) ? 1'bz : 1'b0;		// pullup output (high impedance) SDA.

reg	[7:0]		w_SLAVE_ADDRESS = 8'd0;
reg	[7:0]		w_DATA_ADDRESS = 8'd0;
reg	[7:0]		w_DATA_IMAGE = 8'd0;
reg	[7:0]		r_RECV_DATA = 8'd0;

reg	[3:0]		countMultiByteNow = 4'd0;

always @(posedge CLOCK_50, negedge RST_N)
begin	
	if (RST_N == 0) begin
		SDAT_COUNTER <= 0;
		SCLK <= 1'b1;
		SDAT <= 1'b1;
		CLOCKS <= 1'b0;
		flagBusy <= 1'b0;
		flagReady <= 1'b0;
		flagReadData = 1'b0;
		flagNoACK = 1'b0;
		flagStartCondition <= 1'b0;
		flagStopCondition <= 1'b0;
		flagCatchACK <= 1'b0;
		ACK <= 1'b0;
		flagCatchData <= 1'b0;
		RECV_SDAT <= 1'b0;
		flagSendACK <= 1'b0;
		flagMultiByte <= 1'b0;
		flagReadSkipEnd = 1'b0;
		flagGoMultiByteLoop = 1'b0;
	end else begin
		CLOCK_COUNT <= CLOCK_COUNT + 10'd1;

		if (flagReady == 1'b1) begin								// ready flag of one clock.
			flagReady <= 1'b0;										// ready clear.

		end else begin

			if (flagRequest == 1'b1 && flagBusy == 1'b0) begin
				flagBusy <= 1'b1;										// set busy.
				SDAT_COUNTER <= 0;									// I2C counter clear.
				flagReadData = flagReadMode;						// read mode flag set.
				flagNoACK = 1'b0;										// No ACK flag clear.(blocking)
				flagStartCondition <= 1'b0;
				flagStopCondition <= 1'b0;
				flagCatchACK <= 1'b0;
				ACK <= 1'b0;
				flagCatchData <= 1'b0;
				RECV_SDAT <= 1'b0;
				flagSendACK <= 1'b0;
				flagMultiByte <= flagMultiByteMode;;
				flagReadSkipEnd = 1'b0;
				flagGoMultiByteLoop = 1'b0;
				
				w_SLAVE_ADDRESS[7:0] <= SLAVE_ADDRESS[7:0];
				w_DATA_ADDRESS[7:0]  <= DATA_ADDRESS[7:0];
				
				if (flagReadMode == 1'b0) begin
					w_DATA_IMAGE[7:0] <= DATA_IMAGE[7:0];
				end
			end
			
			
			if (flagBusy == 1'b1 && flagStartCondition == 1'b1) begin
				if (CLOCK_COUNT == 10'b10_1000_0000) begin
					SDAT <= 1'b0;												// start condition.
				end else if (CLOCK_COUNT == 10'b11_0000_0000) begin
					SCLK <= 1'b0;												// start condition.
					flagStartCondition <= 1'b0;
				end
			end
			
			if (flagBusy == 1'b1 && flagStopCondition == 1'b1) begin
				if (CLOCK_COUNT == 10'b01_0000_0000) begin
					SCLK <= 1'b1;												// stop condition.
				end else if (CLOCK_COUNT == 10'b01_1000_0000) begin
					SDAT <= 1'b1;												// stop condition.
					flagStopCondition <= 1'b0;
				end
			end

			if (flagBusy == 1'b1 && flagCatchACK == 1'b1) begin	// ACK catch.
				if (CLOCK_COUNT == 10'b01_1000_0000)					// ACK get timing.
					ACK <= I2C_SDAT;											//
				else if (CLOCK_COUNT == 10'b01_1100_0000)				// ACK check end timing.
					flagCatchACK <= 1'b0;									//
					SDAT <= 1'b0;												//
			end
			
			if (flagBusy == 1'b1 && flagCatchData == 1'b1 && CLOCK_COUNT == 10'b01_1000_0000) begin
				RECV_SDAT <= I2C_SDAT;										//
			end
			
			if (flagBusy == 1'b1 && flagSendACK == 1'b1 && CLOCK_COUNT == 10'b01_1100_0000) begin	// timing = falling I2C_SCLK_w.
				flagSendACK <= 1'b0;											//
				SDAT <= 1'b0;													// send ACK.
			end
			
			if (flagBusy == 1'b1 && CLOCK_COUNT == 10'b10_0000_0000) begin	// 20.48 micro sec cycle.
			
				if (flagReadData == 1'b0) begin					// read data flag off.(=write data mode)

					case (SDAT_COUNTER)								// write logic...
					0  : begin											//
							SCLK <= 1'b1;								// start condition.
							SDAT <= 1'b1;								// start condition.
							CLOCKS <= 1'b0;							//
						end												//
					1  : begin											//
							SCLK <= 1'b1;								// start condition.
							SDAT <= 1'b1;								// start condition.
							flagStartCondition <= 1'b1;			// start condition set.
						end												//
					2  : begin											//
							SDAT <= w_SLAVE_ADDRESS[7:7];			// slave address.
							CLOCKS <= 1'b1;							//
						end												//
					3  : SDAT <= w_SLAVE_ADDRESS[6:6];			//
					4  : SDAT <= w_SLAVE_ADDRESS[5:5];			//
					5  : SDAT <= w_SLAVE_ADDRESS[4:4];			//
					6  : SDAT <= w_SLAVE_ADDRESS[3:3];			//
					7  : SDAT <= w_SLAVE_ADDRESS[2:2];			//
					8  : SDAT <= w_SLAVE_ADDRESS[1:1];			//
					9  : SDAT <= 1'b0;								// 0=write,1=read.
					10 : begin											//
							SDAT <= 1'b1;								// ACK receive.
							flagCatchACK <= 1'b1;					//
						end												//
					
					11 : SDAT <= w_DATA_ADDRESS[7:7];			// EEPROM address.
					12 : SDAT <= w_DATA_ADDRESS[6:6];			//
					13 : SDAT <= w_DATA_ADDRESS[5:5];			//
					14 : SDAT <= w_DATA_ADDRESS[4:4];			//
					15 : SDAT <= w_DATA_ADDRESS[3:3];			//
					16 : SDAT <= w_DATA_ADDRESS[2:2];			//
					17 : SDAT <= w_DATA_ADDRESS[1:1];			//
					18 : SDAT <= w_DATA_ADDRESS[0:0];			//
					19 : begin											//
							SDAT <= 1'b1;								// ACK receive.
							flagCatchACK <= 1'b1;					//
						end

					20 : SDAT <= w_DATA_IMAGE[7:7];				// write data.
					21 : SDAT <= w_DATA_IMAGE[6:6];				//
					22 : SDAT <= w_DATA_IMAGE[5:5];				//
					23 : SDAT <= w_DATA_IMAGE[4:4];				//
					24 : SDAT <= w_DATA_IMAGE[3:3];				//
					25 : SDAT <= w_DATA_IMAGE[2:2];				//
					26 : SDAT <= w_DATA_IMAGE[1:1];				//
					27 : SDAT <= w_DATA_IMAGE[0:0];				//
					28 : begin											//
							SDAT <= 1'b1;								// ACK receive.
							flagCatchACK <= 1'b1;					//
						end
					
					29 : begin											// ACK after falling edge.
							CLOCKS <= 1'b0;							//
							SCLK <= 1'b0;								// stop condition.
							SDAT <= 1'b0;								// stop condition.
							flagStopCondition <= 1'b1;				// stop condition set.
						end												//
					30 : begin											//
							SCLK <= 1'b1;								// stop condition.
							SDAT <= 1'b1;								// stop condition.
							flagBusy <= 1'b0;							// busy clear.
							flagReady <= 1'b1;						// set ready.
						end												//
					endcase
					
					SDAT_COUNTER <= SDAT_COUNTER + 8'd1;
					
				end else begin											// read data flag on.(=read data mode)
				
					case (SDAT_COUNTER)								// read logic...
					0  : begin											//
							SCLK <= 1'b1;								// start condition.
							SDAT <= 1'b1;								// start condition.
							CLOCKS <= 1'b0;							//
						end												//
					1  : begin											//
							SCLK <= 1'b1;								// start condition.
							SDAT <= 1'b1;								// start condition.
							flagStartCondition <= 1'b1;			// start condition set.
						end												//
					2  : begin											//
							SDAT <= w_SLAVE_ADDRESS[7:7];			// slave address.
							CLOCKS <= 1'b1;							//
						end												//
					3  : SDAT <= w_SLAVE_ADDRESS[6:6];			//
					4  : SDAT <= w_SLAVE_ADDRESS[5:5];			//
					5  : SDAT <= w_SLAVE_ADDRESS[4:4];			//
					6  : SDAT <= w_SLAVE_ADDRESS[3:3];			//
					7  : SDAT <= w_SLAVE_ADDRESS[2:2];			//
					8  : SDAT <= w_SLAVE_ADDRESS[1:1];			//
					9  : SDAT <= 1'b0;								// 0=write,1=read.
					10 : begin											//
							SDAT <= 1'b1;								// ACK receive.
							flagCatchACK <= 1'b1;					//
						end												//
					11 : begin											// if NO ACK.(this sample is 17 count retry)
							if (ACK == 1'b1) begin					//            (first write=4,177.92 micro sec) 
								flagNoACK = 1'b1;						// No ACK flag set.(blocking)
								CLOCKS <= 1'b0;						//
								SCLK <= 1'b1;							// start condition.
								SDAT <= 1'b1;							// start condition.
								SDAT_COUNTER <= 0;					// Acknowledge polling flow.
							end else begin								//
								flagNoACK = 1'b0;						// No ACK flag clear.(blocking)
								SDAT <= w_DATA_ADDRESS[7:7];		// EEPROM address.
							end											//
						end												//
						
					12 : SDAT <= w_DATA_ADDRESS[6:6];			//
					13 : SDAT <= w_DATA_ADDRESS[5:5];			//
					14 : SDAT <= w_DATA_ADDRESS[4:4];			//
					15 : SDAT <= w_DATA_ADDRESS[3:3];			//
					16 : SDAT <= w_DATA_ADDRESS[2:2];			//
					17 : SDAT <= w_DATA_ADDRESS[1:1];			//
					18 : SDAT <= w_DATA_ADDRESS[0:0];			//
					19 : begin											//
							SDAT <= 1'b1;								// ACK receive.
							flagCatchACK <= 1'b1;					//
						end												//
					
					20 : begin											// ACK after falling edge.
							CLOCKS <= 1'b0;							// stop condition.
							SCLK <= 1'b0;								// stop condition.
							SDAT <= 1'b0;								// stop condition set.
							flagStopCondition <= 1'b1;				//
						end												//

					21 : begin											//
							CLOCKS <= 1'b0;							//
							SCLK <= 1'b1;								// start condition.
							SDAT <= 1'b1;								// start condition.
						end												//
					22 : begin											//
							SCLK <= 1'b1;								// start condition.
							SDAT <= 1'b1;								// start condition.
							flagStartCondition <= 1'b1;			// start condition set.
						end												//
					23 : begin											//
							SDAT <= w_SLAVE_ADDRESS[7:7];			// slave address.
							CLOCKS <= 1'b1;							//
						end												//
					24 : SDAT <= w_SLAVE_ADDRESS[6:6];			//
					25 : SDAT <= w_SLAVE_ADDRESS[5:5];			//
					26 : SDAT <= w_SLAVE_ADDRESS[4:4];			//
					27 : SDAT <= w_SLAVE_ADDRESS[3:3];			//
					28 : SDAT <= w_SLAVE_ADDRESS[2:2];			//
					29 : SDAT <= w_SLAVE_ADDRESS[1:1];			//
					30 : SDAT <= 1'b1;								// 0=write,1=read.
					31 : begin											//
							SDAT <= 1'b1;								// ACK receive.
							flagCatchACK <= 1'b1;					//
							countMultiByteNow <= 4'd1;				//
						end												//

					32 : begin											// 2 block read data(8bit+ack)
							SDAT <= 1'b1;								// data receive.
							flagCatchData <= 1'b1;					// 7
						end												//
					33 : r_RECV_DATA[7:7] <= RECV_SDAT;			// 6
					34 : r_RECV_DATA[6:6] <= RECV_SDAT;			// 5
					35 : r_RECV_DATA[5:5] <= RECV_SDAT;			// 4
					36 : r_RECV_DATA[4:4] <= RECV_SDAT;			// 3
					37 : r_RECV_DATA[3:3] <= RECV_SDAT;			// 2
					38 : r_RECV_DATA[2:2] <= RECV_SDAT;			// 1
					39 : begin											//
							r_RECV_DATA[1:1] <= RECV_SDAT;		// 0
							if (countMultiByte[3:0] > countMultiByteNow[3:0] && flagMultiByte == 1'b1) begin	// multi bytes.
								flagSendACK <= 1'b1;					//
							end											//
						end												//
					40 : begin											//
							case (countMultiByteNow)
							1 : RECV_DATA[7:0]   <= {r_RECV_DATA[7:1], RECV_SDAT};	// receive data set.
							2 : RECV_DATA02[7:0] <= {r_RECV_DATA[7:1], RECV_SDAT};	// receive data set.
							3 : RECV_DATA03[7:0] <= {r_RECV_DATA[7:1], RECV_SDAT};	// receive data set.
							4 : RECV_DATA04[7:0] <= {r_RECV_DATA[7:1], RECV_SDAT};	// receive data set.
							5 : RECV_DATA05[7:0] <= {r_RECV_DATA[7:1], RECV_SDAT};	// receive data set.
							6 : RECV_DATA06[7:0] <= {r_RECV_DATA[7:1], RECV_SDAT};	// receive data set.
							endcase
							
							flagCatchData <= 1'b0;					//
							
							if (countMultiByte[3:0] <= countMultiByteNow[3:0] || flagMultiByte == 1'b0) begin	// multi bytes.
								SDAT <= 1'b1;							// ACK receive (No ACK when read)
								flagReadSkipEnd = 1'b1;				//
							end else begin								//
								SDAT <= 1'b0;							// ACK send.
								countMultiByteNow <= countMultiByteNow + 4'd1;
								flagGoMultiByteLoop = 1'b1;		//
							end											//
						end												//

					41 : begin											// ACK after falling edge.
							CLOCKS <= 1'b0;							//
							SCLK <= 1'b0;								// stop condition.
							SDAT <= 1'b0;								// stop condition.
							flagStopCondition <= 1'b1;				// stop condition set.
						end												//
					42 : begin											//
							SCLK <= 1'b1;								// stop condition.
							SDAT <= 1'b1;								// stop condition.
							flagBusy <= 1'b0;							// busy clear.
							flagReady <= 1'b1;						// set ready.
						end												//
					endcase												//
	
					if (flagGoMultiByteLoop == 1'b1) begin			// go multi byte loop top.
						flagGoMultiByteLoop = 1'b0;					//
						SDAT_COUNTER <=  8'd32;							// go data read loop.
					end else if (flagReadSkipEnd == 1'b1) begin	// read skip end.
						flagReadSkipEnd = 1'b0;							//
						SDAT_COUNTER <=  8'd41;							// go stop.
					end else if (flagNoACK == 1'b1) begin			// No ACK flag check.(blocking)
						flagNoACK = 1'b0;									// No ACK flag set.(blocking)
					end else begin											//
						SDAT_COUNTER <= SDAT_COUNTER + 8'd1;		//
					end
				end
			end
		end
	end
end

endmodule
