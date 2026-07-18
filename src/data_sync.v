module data_sync (
    input  wire [7:0] unsync_bus,     // Unsynchronized 8-bit data bus (from source clock domain)
    input  wire       bus_enable,     // Enable control signal (from source clock domain)
    input  wire       dest_clk,       // Destination domain Clock
    input  wire       dest_rst,       // Destination domain Active-Low Reset

    output reg  [7:0] sync_bus,       // Synchronized 8-bit data bus (valid on enable_pulse_d)
    output wire       enable_pulse_d  // 1-clock-cycle pulse indicating sync_bus is updated
);

    // 1. Two-stage synchronizer registers for the single-bit "bus_enable"
    reg enable_sync_stage1;
    reg enable_sync_stage2;

    // 2. Delay register for edge detection (to generate the 1-cycle output pulse)
    reg enable_sync_stage2_delay;

    // Synchronize the enable signal into the dest_clk domain
    always @(posedge dest_clk or negedge dest_rst) begin
        if (!dest_rst) begin
            enable_sync_stage1       <= 1'b0;
            enable_sync_stage2       <= 1'b0;
            enable_sync_stage2_delay <= 1'b0;
        end else begin
            enable_sync_stage1       <= bus_enable;
            enable_sync_stage2       <= enable_sync_stage1;
            enable_sync_stage2_delay <= enable_sync_stage2;
        end
    end

    // 3. Generate the 1-cycle output pulse using rising-edge detection
    assign enable_pulse_d = enable_sync_stage2 && !enable_sync_stage2_delay;

    // 4. Safely capture the data bus when the synchronized enable pulse occurs
    always @(posedge dest_clk or negedge dest_rst) begin
        if (!dest_rst) begin
            sync_bus <= 8'd0;
        end else if (enable_pulse_d) begin
            sync_bus <= unsync_bus; // Capture the stable data bus
        end
    end

endmodule