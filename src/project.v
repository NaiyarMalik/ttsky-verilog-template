/*
 * Copyright (c) 2026 Naiyar Malik
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_TinyProcessor_naiyar_ (
	input  wire [7:0] ui_in,    // RX INPUT
   output wire [7:0] uo_out,   // TX OUTPUT
   input  wire [7:0] uio_in,   // 
   output wire [7:0] uio_out,  // 
   output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
   input  wire       ena,      // Always 1 when the design is powered
   input  wire       clk,      // System Master Clock
   input  wire       rst_n     // Master Active-Low Reset
);
	
	
	
	// SYS_CTRL INTERNAL WIRES
	
	wire rst_sync_n;

	// ALU connection
	wire [15:0] alu_out;
	wire alu_out_valid;

	wire [3:0]  alu_fun;
	wire alu_enable;


	// Clock gate connection
	wire clk_en;
	wire gated_clk;

	// RegFile connection
	wire [3:0] reg_address;
	wire reg_wr_en;
	wire reg_rd_en;

	wire [7:0] reg_wr_data;
	wire [7:0] reg_rd_data;

	wire reg_rd_valid;


	// UART RX connection
	wire [7:0] rx_p_data;
	wire rx_d_valid;


	// UART TX connection
	wire [7:0] tx_p_data;
	wire tx_d_valid;


	// Clock divider enable
	wire clk_div_en;


	// REGFILE INTERNAL WIRES

	wire [7:0] reg0_data;
	wire [7:0] reg1_data;
	wire [7:0] reg2_data;
	wire [7:0] reg3_data;
	
	
	
	// UART INTERNAL WIRES
	wire rx_clk;
	wire tx_clk;
	wire rx_par_err;
	wire rx_stop_err;

	wire       rx_par_en;
	wire       rx_par_typ;
	wire [5:0] rx_prescale;


	assign rx_par_en    = reg2_data[0];

	assign rx_par_typ   = reg2_data[1];

	assign rx_prescale  = reg2_data[7:2];

	wire tx_serial_out;
	wire tx_busy;
	
	assign uo_out[0] = tx_serial_out;
	assign uo_out[7:1] = 7'b0;
	
	
	// Pulse Generator interal wires
	
	wire tx_ready;

	assign tx_ready = (~tx_busy) && (~fifo_empty);
	
	// FIFIO
	
	wire fifo_w_inc;
	wire fifo_r_inc;

	wire [7:0] fifo_wr_data;
	wire [7:0] fifo_rd_data;

	wire fifo_full;
	wire fifo_empty;
	
	assign fifo_wr_data = tx_p_data;
	assign fifo_w_inc   = tx_d_valid;
	
	wire [7:0] sync_rx_data;
	wire       sync_rx_d_valid;
	
	// wire fifo_rst_sync_n;
	
	
	assign uio_out = 8'b0;
	assign uio_oe  = 8'b0;
	wire unused = &{ena, uio_in};
	
	wire fifo_w_rst;
	wire fifo_r_rst;
	
 // ----------------------------------------------------------------------------------------------------------------------------




	
	// SYSTEM CONTROL UNIT
	sys_ctrl #(.ADDY(4), .REGWIDTH(8)) sys_ctrl1 (

		// Clock / Reset
		.clk(clk),
		.rst(rst_sync_n),


		// ALU
		.ALU_OUT(alu_out),
		.out_valid(alu_out_valid),
		.ALU_FUN(alu_fun),
		.en(alu_enable),

		// Clock Gate
		.clk_en(clk_en),

		// RegFile
		.address(reg_address),
		.WrEn(reg_wr_en),
		.RdEn(reg_rd_en),
		.WrData(reg_wr_data),
		.RdData(reg_rd_data),
		.RdData_Valid(reg_rd_valid),

		// UART RX
		.RX_P_DATA(sync_rx_data),
		.RX_D_VLD(sync_rx_d_valid),

		// UART TX
		.TX_D_VLD(tx_d_valid),
		.TX_P_DATA(tx_p_data),

		// CLK DIV
		.clk_div_en(clk_div_en),
		
		.fifo_full(fifo_full)


	);
	
	
	
	// REGFILE UNIT
	regFile #(.ADDY(4), .DATA(8)) rf1 (

		// Write interface
		.WrData(reg_wr_data),
		.Address(reg_address),
		.WrEn(reg_wr_en),
		.RdEn(reg_rd_en),

		// Clock/reset
		.clk(gated_clk),
		.rst(rst_sync_n),

		// Read interface
		.RdData(reg_rd_data),
		.RdData_Valid(reg_rd_valid),

		// Register outputs
		.REG0(reg0_data),
		.REG1(reg1_data),
		.REG2(reg2_data),
		.REG3(reg3_data)

	);
	
	
	
	// ARITHMETIC UNIT
	ALU #(.DATA(8), .OPERATION(4)) a1 (

		// Inputs from REGFILE
		.A(reg0_data),
		.B(reg1_data),

		// Operation from SYS_CTRL
		.ALU_FUN(alu_fun),

		// Enable from SYS_CTRL
		.Enable(alu_enable),

		// Clock/reset
		.CLK(gated_clk),
		.RST(rst_sync_n),

		// Output back to SYS_CTRL
		.ALU_OUT(alu_out),
		.OUT_VALID(alu_out_valid)

	);
	
	
	// UART RX LINE
	uart_rx #(.DATA(8)) rx1 (

		.rx_in(ui_in[0]),
		.prescale(rx_prescale),
		.par_en(rx_par_en),
		.par_typ(rx_par_typ),
		.clk(rx_clk),
		.rst(rst_sync_n),
		.p_data(rx_p_data),
		.data_vld(rx_d_valid),
		.par_err(rx_par_err),
		.stp_err(rx_stop_err)

	);
	
	
	//UART TX LINE

	uart_tx #(.DATA(8)) tx1 (

		.p_data(fifo_rd_data),
		.data_valid(fifo_r_inc),

		.par_en(rx_par_en),
		.par_typ(rx_par_typ),

		.clk(tx_clk),
		.rst(rst_sync_n),

		.s_data(tx_serial_out),
		.busy(tx_busy)
);
	
	
	// PULSE GENERATOR
	
	pulse_gen tx_fifo_read_pulse (

    .rst(rst_sync_n),
    .clk(tx_clk),
    .lvl_sig(tx_ready),
    .pulse_sig(fifo_r_inc)

);
	
	
	// CLOCK GATE
	clk_gate cg1 (
	
		.clk(clk),
		.clk_en(clk_en),
		.gated_clk(gated_clk)
	
	);
	
	
	// CLOCK DIVIDER FOR TX
	clk_div #(.RATIO_WD(8)) cd2 (
		
		.i_ref_clk(clk),
		.i_rst(rst_sync_n),
		.i_clk_en(clk_div_en),
		.i_div_ratio(reg3_data),
		.o_div_clk(tx_clk)
		
	);
	
	
	// CLOCK DIVIDER FOR RX
	clk_div #(.RATIO_WD(8)) cd1 (
		
		.i_ref_clk(clk),
		.i_rst(rst_sync_n),
		.i_clk_en(clk_div_en),
		.i_div_ratio({2'b00, rx_prescale}),
		.o_div_clk(rx_clk)
		
	);
	
	
	
	// ASYNC FIFO

	async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) af1 (

		.W_CLK(clk), // REF_CLK
		.W_INC(fifo_w_inc),
		.WR_DATA(fifo_wr_data),
		.W_RST(fifo_w_rst),
		.R_RST(fifo_r_rst),
		.R_CLK(tx_clk),
		.R_INC(fifo_r_inc),
		.RD_DATA(fifo_rd_data),
		.EMPTY(fifo_empty),
		.FULL(fifo_full)

);
	
	
	// DATA SYNCHRONIZER
	data_sync ds1 (
	
		// Source domain (UART RX)
		.unsync_bus(rx_p_data),
		.bus_enable(rx_d_valid),

		// Destination domain (SYS_CTRL / REF_CLK)
		.dest_clk(clk),
		.dest_rst(rst_sync_n),

		// Synchronized outputs
		.sync_bus(sync_rx_data),
		.enable_pulse_d(sync_rx_d_valid)

	);
	
	
	// RST FOR REGFILE
	rst_sync rs1 (
	
		.clk(clk),
		.rst_n(rst_n),
		.rst_sync_n(rst_sync_n)
	
	);
	
	
	// RST FOR FIFO
	rst_sync fifo_write_rst (
		.clk(clk),
		.rst_n(rst_n),
		.rst_sync_n(fifo_w_rst)
	);


	rst_sync fifo_read_rst (
		.clk(tx_clk),
		.rst_n(rst_n),
		.rst_sync_n(fifo_r_rst)
	);
	
	

endmodule