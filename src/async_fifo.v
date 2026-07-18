module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4  // FIFO Depth = 2^ADDR_WIDTH = 16 locations
) (
    // Write Domain (Source: System Ctrl)
    input  wire                  W_CLK,     // Write clock (REF_CLK)
    input  wire                  W_RST,     // Async reset (from RST_SYNC_1, active-low)
    input  wire                  W_INC,     // Write enable / increment
    input  wire [DATA_WIDTH-1:0] WR_DATA,   // Data to write
    output reg                   FULL,      // FIFO full flag

    // Read Domain (Destination: UART TX)
    input  wire                  R_CLK,     // Read clock
    input  wire                  R_RST,     // Async reset (from RST_SYNC_2, active-low)
    input  wire                  R_INC,     // Read enable / increment
    output wire [DATA_WIDTH-1:0] RD_DATA,   // Data to read
    output reg                   EMPTY      // FIFO empty flag
);

    // Dual-Port RAM Memory
    localparam DEPTH = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];

    // Pointers
    reg [ADDR_WIDTH:0] wbin, rbin;     // Binary pointers (1 extra bit for wrap-around)
    reg [ADDR_WIDTH:0] wptr, rptr;     // Gray pointers
    
    // Synchronized Gray Pointer Registers
    reg [ADDR_WIDTH:0] wq1_rptr, wq2_rptr; // Read pointer synchronized to W_CLK
    reg [ADDR_WIDTH:0] rq1_wptr, rq2_wptr; // Write pointer synchronized to R_CLK

    // Internal wire assignments for Gray Code conversion
    wire [ADDR_WIDTH:0] wgraynext, rgraynext;
    wire [ADDR_WIDTH:0] wbinnext, rbinnext;

    // ==========================================
    // 1. DUAL-PORT MEMORY WRITE & READ
    // ==========================================
    
    // Write to memory (Write Clock Domain)
    always @(posedge W_CLK) begin
        if (W_INC && !FULL) begin
            fifo_mem[wbin[ADDR_WIDTH-1:0]] <= WR_DATA;
        end
    end

    // Direct asynchronous read output (Read Clock Domain)
    assign RD_DATA = fifo_mem[rbin[ADDR_WIDTH-1:0]];


    // ==========================================
    // 2. WRITE POINTER & FULL FLAG GENERATION
    // ==========================================
    assign wbinnext  = wbin + (W_INC & ~FULL);
    assign wgraynext = (wbinnext >> 1) ^ wbinnext; // Binary to Gray formula

    always @(posedge W_CLK or negedge W_RST) begin
        if (!W_RST) begin
            wbin <= 0;
            wptr <= 0;
        end else begin
            wbin <= wbinnext;
            wptr <= wgraynext;
        end
    end

    // Synchronize Read Pointer into Write Clock Domain (W_CLK)
    always @(posedge W_CLK or negedge W_RST) begin
        if (!W_RST) begin
            wq1_rptr <= 0;
            wq2_rptr <= 0;
        end else begin
            wq1_rptr <= rptr;
            wq2_rptr <= wq1_rptr;
        end
    end

    // Full condition check
    // Full when MSB & MSB-1 are inverted, but the remaining bits match
    wire wfull_val = (wgraynext == {~wq2_rptr[ADDR_WIDTH:ADDR_WIDTH-1], wq2_rptr[ADDR_WIDTH-2:0]});

    always @(posedge W_CLK or negedge W_RST) begin
        if (!W_RST) begin
            FULL <= 1'b0;
        end else begin
            FULL <= wfull_val;
        end
    end


    // ==========================================
    // 3. READ POINTER & EMPTY FLAG GENERATION
    // ==========================================
    assign rbinnext  = rbin + (R_INC & ~EMPTY);
    assign rgraynext = (rbinnext >> 1) ^ rbinnext; // Binary to Gray formula

    always @(posedge R_CLK or negedge R_RST) begin
        if (!R_RST) begin
            rbin <= 0;
            rptr <= 0;
        end else begin
            rbin <= rbinnext;
            rptr <= rgraynext;
        end
    end

    // Synchronize Write Pointer into Read Clock Domain (R_CLK)
    always @(posedge R_CLK or negedge R_RST) begin
        if (!R_RST) begin
            rq1_wptr <= 0;
            rq2_wptr <= 0;
        end else begin
            rq1_wptr <= wptr;
            rq2_wptr <= rq1_wptr;
        end
    end

    // Empty condition check
    // Empty when Gray read pointer perfectly matches synchronized Gray write pointer
    wire rempty_val = (rgraynext == rq2_wptr);

    always @(posedge R_CLK or negedge R_RST) begin
        if (!R_RST) begin
            EMPTY <= 1'b1; // Start empty!
        end else begin
            EMPTY <= rempty_val;
        end
    end

endmodule