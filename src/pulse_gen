module pulse_gen
	(
	
		input rst, clk, lvl_sig,
		
		output pulse_sig
	
	);
	

	reg lvl_sig_delay;
	
	always @ (posedge clk or negedge rst)
		begin
			if(!rst)
				begin
					lvl_sig_delay <= 1'b0;
				end
			else
				begin
					lvl_sig_delay <= lvl_sig;
				end
		end
	
		
		
	assign pulse_sig = lvl_sig && !lvl_sig_delay;	
	
endmodule
	