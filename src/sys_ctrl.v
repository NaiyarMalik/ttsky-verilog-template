module sys_ctrl 
	
	#(parameter REGWIDTH = 8, parameter ADDY = 4)
	(
	
	
		input clk, rst, 
		
		// FIFO
		input fifo_full,
		
		// ALU
		input [15:0] ALU_OUT, // ALU result
		input out_valid,
		output [3:0] ALU_FUN,
		output en, // enable the ALU unit
		
		
		output clk_en, // Clock Gate
		
		// RegFile
		output [ADDY-1:0] address,
		output WrEn, RdEn,
		output [REGWIDTH-1:0] WrData,
		input [REGWIDTH-1:0] RdData,
		input RdData_Valid,
	
		// UART
		input [REGWIDTH-1:0] RX_P_DATA, // recieved frame
		input RX_D_VLD, 
		output TX_D_VLD,
		output [REGWIDTH-1:0] TX_P_DATA, // transmits frame
		
		
		// CLK DIV
		output clk_div_en
		
	);
	
	
	reg WrEn_i;
	reg RdEn_i;
	reg [7:0] WrData_i;
	reg [7:0] TX_P_DATA_i;
	reg TX_D_VLD_i;
	reg en_i;
	reg clk_en_i;
	
	
	
	reg [3:0] current_state;
	reg [3:0] next_state;
	
	localparam  IDLE             = 4'b0000,
                START           = 4'b0001,
                READ_CMD        = 4'b0010,
                WRITE_CMD       = 4'b0011,
                ALU_CMD         = 4'b0100,
                ALU_NO_OP_CMD   = 4'b0101,
                READ_WHERE      = 4'b0110,
                WRITE_WHERE     = 4'b0111,
                OP_A            = 4'b1000,
                OP_B            = 4'b1001,
                WRITE_WHAT      = 4'b1010,
                READOUT         = 4'b1011,
                ALU_FUN_CMD     = 4'b1100,
                ALU_WAIT        = 4'b1101,
                ALU_TX_LOW      = 4'b1110,
                ALU_TX_HIGH     = 4'b1111;
                
               
    localparam  WRITE     = 8'hAA,
                READ      = 8'hBB,
                ALU_OP    = 8'hCC,
                ALU_OP_NO = 8'hDD;
	

	reg [ADDY-1:0] hold_address;
	reg [REGWIDTH-1:0] hold_wr_data;
	reg [REGWIDTH-1:0] hold_OP_A;
	reg [REGWIDTH-1:0] hold_OP_B;
	reg [3:0] hold_alu_fun;
	reg [15:0] hold_alu_out;
	
	
	always @ (posedge clk)
		begin
			if(!rst)
				begin
					current_state <= IDLE;
					hold_address  <= {ADDY{1'b0}};
               hold_wr_data  <= {REGWIDTH{1'b0}};
               hold_alu_fun  <= 4'b0;
               hold_alu_out  <= 16'b0;
				end
			else
				begin
					
					current_state <= next_state;
					
					if ((current_state == WRITE_WHERE || current_state == READ_WHERE) && RX_D_VLD)						 
						begin
							hold_address <= RX_P_DATA[ADDY-1:0]; 
						end
						 
					if ((current_state == WRITE_WHAT) && RX_D_VLD)
						begin
							hold_wr_data <= RX_P_DATA;
						end		
						
								
					if((current_state == OP_A) && RX_D_VLD)
						begin
							hold_wr_data <= RX_P_DATA;
							hold_address <= {ADDY{1'b0}};
						end
							
					if((current_state == OP_B) && RX_D_VLD)
						begin
							hold_address <= 4'b0001;
							hold_wr_data <= RX_P_DATA;
						end
	
					if ((current_state == ALU_FUN_CMD) && RX_D_VLD)
						begin
							hold_alu_fun <= RX_P_DATA[3:0];
						end
						
					if (out_valid)
                  begin
                     hold_alu_out <= ALU_OUT;
                  end
	
			  end
	end
	
	
		
	always @ (*)
		begin
		
			next_state  = current_state; // Prevents state latches
			WrEn_i      = 1'b0;
			RdEn_i      = 1'b0;
			en_i        = 1'b0;
			clk_en_i    = 1'b0;
			TX_P_DATA_i = {REGWIDTH{1'b0}};
			TX_D_VLD_i  = 1'b0;
				
				
			case(current_state)
				IDLE:
					if(RX_D_VLD)
						next_state = START;
					else
						next_state = IDLE;
						
				START:
					case(RX_P_DATA)
						WRITE:
							next_state = WRITE_CMD;
						
						READ:
							next_state = READ_CMD;
							
						ALU_OP:
							next_state = ALU_CMD;
						
						ALU_OP_NO:
							next_state = ALU_NO_OP_CMD;
						
						default:
							next_state = IDLE;
							
					endcase
			
				WRITE_CMD:
					next_state = WRITE_WHERE;
					
					
				WRITE_WHERE:
					if(RX_D_VLD)
						begin
							next_state = WRITE_WHAT;
						end
					else
						next_state = WRITE_WHERE;
						
				WRITE_WHAT:
					if(RX_D_VLD)
						begin
							WrEn_i = 1'b1;
							next_state = IDLE;
						end
					else
						next_state = WRITE_WHAT;
						
				
				READ_CMD:
					next_state = READ_WHERE;
				
				READ_WHERE:
					if(RX_D_VLD)
						begin
							RdEn_i = 1'b1;
							next_state = READOUT;
						end
					else
						next_state = READ_WHERE;
				
				READOUT:
					begin
						RdEn_i = 1'b1;
						if(RdData_Valid && !fifo_full)
							begin
								TX_P_DATA_i = RdData;
								TX_D_VLD_i = 1'b1;
								next_state = IDLE;
							end
						else
							begin
								next_state = READOUT;
							end
					end
								
				ALU_CMD:
					next_state = OP_A;
					
				OP_A:
					if(RX_D_VLD)
						begin
							WrEn_i = 1'b1;
							next_state = OP_B;
						end
					else
						next_state = OP_A;
						
				OP_B:
					if(RX_D_VLD)
						begin
							WrEn_i = 1'b1;
							next_state = ALU_FUN_CMD;
						end
					else
						next_state = OP_B;
				
				ALU_FUN_CMD:
					if(RX_D_VLD)
						begin
							en_i = 1'b1;
							clk_en_i = 1'b1;
							next_state = ALU_WAIT;
							
						end
					else
						next_state = ALU_FUN_CMD;
				
				ALU_WAIT:
                    begin
                        en_i   = 1'b1; 
                        clk_en_i = 1'b1; 
                        if(out_valid)
                            next_state = ALU_TX_LOW; // Result
                        else
                            next_state = ALU_WAIT;
                    end

            ALU_TX_LOW:
                    begin
								if(!fifo_full)
									begin
										// Transmit lower byte of the 16-bit ALU output [7:0]
										TX_P_DATA_i = hold_alu_out[7:0];
										TX_D_VLD_i  = 1'b1;
										next_state  = ALU_TX_HIGH;
									end
						  end

            ALU_TX_HIGH:
                    begin
								if(!fifo_full)
									begin
										// Transmit upper byte of the 16-bit ALU output [15:8]
										TX_P_DATA_i = hold_alu_out[15:8];
										TX_D_VLD_i  = 1'b1;
										next_state  = IDLE;
									end
						  end
            
				ALU_NO_OP_CMD:
					begin
						next_state = ALU_FUN_CMD;
					end 
				
				
            default: 
					next_state = IDLE;
					
				
			endcase
		
		end
		
		
	assign WrEn = WrEn_i;
	assign RdEn = RdEn_i;
	assign en = en_i;
	assign TX_P_DATA = TX_P_DATA_i;
	assign TX_D_VLD = TX_D_VLD_i;
	assign address = hold_address;
	assign WrData = hold_wr_data;
	assign ALU_FUN = hold_alu_fun;
	assign clk_en = clk_en_i;
	assign clk_div_en = 1'b1;
		
		
endmodule