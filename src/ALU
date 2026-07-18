module ALU

	#(parameter DATA = 8, parameter OPERATION = 4)
	(
		input [DATA-1:0] A, B,
		input [OPERATION-1:0] ALU_FUN,
		input Enable, CLK, RST,
	
		output [15:0] ALU_OUT,
		output OUT_VALID
	);
	
	
	reg [2*DATA-1:0] alu_out_i;
	reg out_valid_i;

	
	always @ (posedge CLK)
		begin
			if(!RST)
				begin
					alu_out_i <= {15{1'b0}};
					out_valid_i <= 1'b0;
				end
				
			else
				if(Enable)
					begin
						
						case(ALU_FUN)
							
								
								// 1. Arith
								
								4'b0000: // Addition
									begin
										alu_out_i <= A + B;
										out_valid_i <= 1'b1;
									end
									
								4'b0001: // Subtraction
									begin
										alu_out_i <= A - B;
										out_valid_i <= 1'b1;
									end
									
								4'b0010: // Muliply
									begin
										alu_out_i <= A * B;
										out_valid_i <= 1'b1;
									end
									
								4'b0011: // Divide
									begin
										if(B != 0)
											alu_out_i <= A / B;
										else
											alu_out_i <= {15{1'b0}};

										
										out_valid_i <= 1'b1;
									end
							
								// 2. Logic
								
								4'b0100: // AND
									begin
										alu_out_i <= A & B;
										out_valid_i <= 1'b1;
									end
									
								4'b0101: // OR
									begin
										alu_out_i <= A | B;
										out_valid_i <= 1'b1;
									end
									
								4'b0110: // NAND
									begin
										alu_out_i <= ~(A & B);
										out_valid_i <= 1'b1;
									end
									
								4'b0111: // NOR
									begin
										alu_out_i <= ~(A | B);
										out_valid_i <= 1'b1;
									end
									
								4'b1000: // XOR
									begin
										alu_out_i <= A ^ B;
										out_valid_i <= 1'b1;
									end
								
								4'b1001: // XNOR
									begin
										alu_out_i <= ~(A ^ B);
										out_valid_i <= 1'b1;
									end
							
								// 3. CMP
								
								
								4'b1010: // Equality
									begin
										alu_out_i <= (A == B);
										out_valid_i <= 1'b1;
									end
							
								4'b1011: // A greater than B
									begin
										alu_out_i <= (A > B);
										out_valid_i <= 1'b1;
									end
									
								// 4. Shifting
									
								4'b1100: // A shifts right
									begin
										alu_out_i <= (A >> 1);
										out_valid_i <= 1'b1;
									end
									
								4'b1101: // A shifts left
									begin
										alu_out_i <= (A << 1);
										out_valid_i <= 1'b1;
									end
									
								default:
									begin
										alu_out_i   <= {15{1'b0}};
										out_valid_i <= 1'b0;
									end

						endcase
						
					end
				
				else
					begin
						out_valid_i <= 1'b0;
					end	
				
				
		end

	assign ALU_OUT = alu_out_i;	
	assign OUT_VALID = out_valid_i;
	
endmodule