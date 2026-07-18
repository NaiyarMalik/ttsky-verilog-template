module uart_rx
	#(parameter DATA = 8)
	(
		input  wire            rx_in,        // Serial input line
		input  wire [5:0]      prescale,     // Oversampling rate (usually 16 or 8)
		input  wire            par_en,       // Parity enable
		input  wire            par_typ,      // Parity type (0: even, 1: odd)
		input  wire            clk,          // Receiver system clock
		input  wire            rst,          // Active-low reset

		output reg [DATA-1:0]  p_data,       // Parallel received byte
		output reg             data_vld,     // Pulses high when packet is ready
		output reg             par_err,      // High if parity mismatch detected
		output reg             stp_err       // High if invalid stop bit (0 instead of 1)
	);

	localparam  IDLE      = 3'b000,
	            START_BIT = 3'b001,
	            DATA_BITS = 3'b010,
	            PARITY    = 3'b011,
	            STOP_BIT  = 3'b100;

	reg [2:0] current_state, next_state;
	reg [2:0] bit_counter;
	reg [5:0] prescale_counter;
	reg [DATA-1:0] rx_data_buffer;
	
	reg sampled_parity_bit;
	reg sampled_stop_bit;
	reg parity_calculated;

	// Helper definitions for sampling logic
	wire [5:0] middle_of_bit = (prescale >> 1);
	wire [5:0] end_of_bit    = (prescale - 1'b1);

	// Sequential Block
	always @(posedge clk or negedge rst) 
		begin
			if (!rst) 
				begin
					current_state    <= IDLE;
					bit_counter      <= 3'd0;
					prescale_counter <= 6'd0;
					rx_data_buffer   <= {DATA{1'b0}};
					sampled_parity_bit <= 1'b0;
					sampled_stop_bit   <= 1'b0;
				end 
			
			else 
				
				begin
					current_state <= next_state;

					// --- Prescale Counter Logic ---
					if (current_state == IDLE) 
						begin
							prescale_counter <= 6'd0;
						end 
					else if (prescale_counter == end_of_bit) 
						begin
							prescale_counter <= 6'd0; // Reset counter at bit boundaries
						end 
					else 
						begin
							prescale_counter <= prescale_counter + 1'b1;
						end

					// --- Data Bit Sampling Logic ---
					if (current_state == DATA_BITS) 
						begin
							if (prescale_counter == middle_of_bit) 
								begin
									rx_data_buffer[bit_counter] <= rx_in; // Sample in the exact middle of the bit
								end
							
							if (prescale_counter == end_of_bit) 
								begin
									if (bit_counter == 3'd7) 
										bit_counter <= 3'd0;
									else 
										bit_counter <= bit_counter + 1'b1;
								end
						end 
					else 
						begin
							bit_counter <= 3'd0;
						end

					// --- Parity Sampling Logic ---
					if (current_state == PARITY && (prescale_counter == middle_of_bit)) 
						begin
							sampled_parity_bit <= rx_in;
						end

					// --- Stop Bit Sampling Logic ---
					if (current_state == STOP_BIT && (prescale_counter == middle_of_bit)) 
						begin
							sampled_stop_bit <= rx_in;
						end
				end
		end

	// Combinational Block: Parity Check Calculation
	always @(*) 
		begin
			if (par_typ) 
				begin
					parity_calculated = ~^rx_data_buffer; // Odd Parity
				end 
			else 
				begin
					parity_calculated = ^rx_data_buffer;  // Even Parity
				end
		end

	// Combinational Block: FSM State Transitions
	always @(*) 
		begin
			next_state = current_state;

			case (current_state)
				IDLE: 
					begin
						// Wait for the line to drop low (Start Bit detected)
						if (rx_in == 1'b0) 
							next_state = START_BIT;
						else 
							next_state = IDLE;
					end

				START_BIT: 
					begin
						if (prescale_counter == end_of_bit) 
							begin
								// Double-check at the middle point: if it was noise, reset to IDLE
								if (rx_data_buffer == 8'h00 && rx_in == 1'b1 && (prescale_counter < middle_of_bit)) 
									next_state = IDLE;
								else
									next_state = DATA_BITS;
							end
					end

				DATA_BITS: 
					begin
						if (bit_counter == 3'd7 && prescale_counter == end_of_bit) 
							begin
								if (par_en) 
									next_state = PARITY;
								else 
									next_state = STOP_BIT;
							end
					end

				PARITY: 
					begin
						if (prescale_counter == end_of_bit) 
							next_state = STOP_BIT;
					end

				STOP_BIT: 
					begin
						if (prescale_counter == end_of_bit) 
							next_state = IDLE;
					end

				default: 
					begin
						next_state = IDLE;
					end
			endcase
		end

	// Sequential Block: Error Flag Registers & Parallel Data Output Publish
	always @(posedge clk or negedge rst) 
		begin
			if (!rst) 
				begin
					p_data   <= {DATA{1'b0}};
					data_vld <= 1'b0;
					par_err  <= 1'b0;
					stp_err  <= 1'b0;
				end 
			else 
				begin
					// Clear flag pulses by default
					data_vld <= 1'b0; 

					// We make our final checks and update output lines in the STOP state
					if (current_state == STOP_BIT && prescale_counter == end_of_bit) 
						begin
							// Check 1: Stop Bit Framing Error (must be 1)
							if (sampled_stop_bit == 1'b0) 
								begin
									stp_err  <= 1'b1;
									par_err  <= 1'b0;
									data_vld <= 1'b0;
								end 
							// Check 2: Parity Error
							else if (par_en && (sampled_parity_bit != parity_calculated)) 
								begin
									par_err  <= 1'b1;
									stp_err  <= 1'b0;
									data_vld <= 1'b0;
								end 
							// Frame is perfectly valid!
							else 
								begin
									p_data   <= rx_data_buffer;
									data_vld <= 1'b1;
									par_err  <= 1'b0;
									stp_err  <= 1'b0;
								end
						end
				end
		end

endmodule