module regFile
	#(parameter DATA = 8, parameter ADDY = 4)
	(
	
		input [DATA-1:0] WrData, //
		input [ADDY-1:0] Address, // 
		input WrEn, RdEn, clk, rst,
		
		output [DATA-1:0] RdData,
		output RdData_Valid,
		output [DATA-1:0] REG0, // ALU op 1, Ad: 0x0
		output [DATA-1:0] REG1, // ALU op 2, Ad: 0x1
		output [DATA-1:0] REG2, // UART config, Ad: 0x2 (REG2[0]: Parity En, REG2[1]: Parity Typ, REG3[7:2]: Prescale)
		output [DATA-1:0] REG3 // Clock Divider ratio, Ad: 0x3
	
	);

	reg [DATA-1:0] reg8x16 [15:0];
	reg [DATA-1:0] RdData_i;
	reg RdData_Valid_i; 
	integer i;

	always @(posedge clk)
		begin
			if(!rst)
				begin
					RdData_Valid_i <= 1'b0;
					RdData_i <= {DATA{1'b0}};
				
					for(i = 0; i < 16; i = i + 1)
						reg8x16[i] <= {DATA{1'b0}};
						
					reg8x16[2] <= 8'b10000001;
				end
			else
				begin
					RdData_Valid_i <= 0;
					if(WrEn)
						begin
							RdData_Valid_i <= 1'b0;
							RdData_i <= {DATA{1'b0}};
							reg8x16[Address] <= WrData;
							
						end
						
					else if(RdEn)
						begin
							RdData_i <= reg8x16[Address];
							RdData_Valid_i <= 1'b1;
						end
			
					
				end
		end	
	
		assign RdData_Valid = RdData_Valid_i;
		assign RdData = RdData_i;
		
		assign REG0 = reg8x16[0];
		assign REG1 = reg8x16[1];
		assign REG2 = reg8x16[2];
		assign REG3 = reg8x16[3];
	
endmodule