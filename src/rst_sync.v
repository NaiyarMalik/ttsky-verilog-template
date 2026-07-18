module rst_sync (
    input  wire clk,         // System clock
    input  wire rst_n,       // Raw, asynchronous active-low reset input
    output wire rst_sync_n   // Clean, clock-synchronized active-low reset output
);

    // Two-stage shift register to eliminate metastability
    reg rst_stage1;
    reg rst_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous Reset: Both stages drop to 0 instantly
            rst_stage1 <= 1'b0;
            rst_stage2 <= 1'b0;
        end else begin
            // Synchronous Release: Shift a '1' through the registers on the clock edges
            rst_stage1 <= 1'b1;
            rst_stage2 <= rst_stage1;
        end
    end

    // The output is the synchronized reset signal
    assign rst_sync_n = rst_stage2;

endmodule