module clk_gate
	(
		 input clk,
		 input clk_en,
		 output gated_clk
	);

	assign gated_clk = clk & clk_en;

endmodule