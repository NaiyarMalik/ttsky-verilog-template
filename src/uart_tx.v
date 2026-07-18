module uart_tx
	#(parameter DATA = 8)
	
	(
		input  wire [DATA-1:0] p_data,
		input  wire            data_valid,
		input  wire            par_en,
		input  wire            par_typ,
		input  wire            clk,
		input  wire            rst,

		output reg             s_data,
		output reg             busy
	);
 
   localparam	IDLE      = 3'b000,
               START_BIT = 3'b001,
               DATA_BITS = 3'b010,
               PARITY    = 3'b011,
               STOP_BIT  = 3'b100;
                
	reg [2:0] current_state, next_state;
	reg [2:0] bit_counter;
	reg [DATA-1:0] tx_data_buffer;
   reg parity_bit;
    


	always @(posedge clk or negedge rst) 
		begin
			if(!rst) 
				begin
					current_state  <= IDLE;
					bit_counter    <= 3'd0;
					tx_data_buffer <= {DATA{1'b0}};
				end 
			else 
				begin
					current_state <= next_state;
            
            if (current_state == DATA_BITS) 
					begin
               
					if (bit_counter == 3'd7) 
						begin
                    bit_counter <= 3'd0;
						end 
					
					else 
						begin
                    bit_counter <= bit_counter + 1'b1;
						end
				
					end 
				
				else
					begin
						bit_counter <= 3'd0;
					end
            
            if (current_state == IDLE && data_valid && !busy) 
					begin
						tx_data_buffer <= p_data;
					end
				
				end
		end
    
	 
	 
	always @(*) // Determinds Parity Bit
		begin
        if (par_typ) 
				begin
					parity_bit = ~^tx_data_buffer;
				end 
			else 
				begin
					parity_bit = ^tx_data_buffer;
			end
		end

	always @(*) // FSM Cycle
		begin
			next_state = current_state;
        
			case (current_state)
				IDLE: 
					begin
						if (data_valid) 
							begin
								next_state = START_BIT;
							end 
						else 
							begin
								next_state = IDLE;
							end
					end
            
            START_BIT: 
					begin
						next_state = DATA_BITS;
					end
            
            DATA_BITS: 
					begin
						if(bit_counter == 3'd7) 
							begin							
								if(par_en)
									begin
										next_state = PARITY;
									end 
								else
									begin
										next_state = STOP_BIT;
									end
							end 
						
						else 
							begin
								next_state = DATA_BITS;
							end
					end
            
            PARITY: 
					begin
						next_state = STOP_BIT;
					end
            
            STOP_BIT: 
					begin
						next_state = IDLE;
					end
            
            default: 
					begin
						next_state = IDLE;
					end
			endcase
		end

	always @(*) // Controls the busy and s_data values
		begin
			s_data = 1'b1;
			busy   = 1'b1;
        
			case (current_state)
				IDLE: 
					begin
						s_data = 1'b1;
						busy   = 1'b0;
					end
            
            START_BIT: 
					begin
						s_data = 1'b0;
						busy   = 1'b1;
					end
            
            DATA_BITS: 
					begin
						s_data = tx_data_buffer[bit_counter];
						busy   = 1'b1;
					end
            
            PARITY: 
					begin
						s_data = parity_bit;
						busy   = 1'b1;
					end
            
            STOP_BIT: 
					begin
						s_data = 1'b1;
						busy   = 1'b1;
					end
            
            default: 
					begin
						s_data = 1'b1;
						busy   = 1'b0;
					end
			endcase
		end

endmodule