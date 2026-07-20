
// ************************* Description *********************** //
//  This module is implemented to:-                              //
//   -- generate write address in binary code                    //
//   -- generate full flag to overcome fifo overwrite            //
//   -- generate gray coded write pointer                        //
// ************************************************************* //

module fifo_wr #(
  parameter P_SIZE = 4                          // pointer width
)
  (
   input  wire                    w_clk,              // write domian operating clock
   input  wire                    w_rstn,             // write domian active low reset 
   input  wire                    w_inc,              // write control signal 
   input  wire  [P_SIZE-1:0]      sync_rd_ptr,        // synced gray coded read pointer         
   output wire  [P_SIZE-2:0]      w_addr,             // generated binary write address
   output reg   [P_SIZE-1:0]      gray_w_ptr,         // generated gray coded write address [registered]
   output wire                    full                // fifo full flag

);

reg [P_SIZE-1:0]  w_ptr ;

wire [P_SIZE-1:0]  comb_gray_w_ptr ;


assign comb_gray_w_ptr = w_ptr ^ (w_ptr >> 1);

// increment binary pointer
always @(posedge w_clk or negedge w_rstn)
 begin
  if(!w_rstn)
   begin
    w_ptr <= 0 ;
   end
 else if (!full && w_inc)
    w_ptr <= w_ptr + 1 ;
 end


// generation of write address
assign w_addr = w_ptr[P_SIZE-2:0] ;

// converting binary write pointer to gray coded
always @(posedge w_clk or negedge w_rstn)
 begin
  if(!w_rstn)
   begin
    gray_w_ptr <= 0 ;
   end
 else
  begin
   gray_w_ptr <= comb_gray_w_ptr;
  end
 end


// generation of full flag
assign full = (sync_rd_ptr[P_SIZE-1]!= comb_gray_w_ptr[P_SIZE-1] && sync_rd_ptr[P_SIZE-2]!= comb_gray_w_ptr[P_SIZE-2] && sync_rd_ptr[P_SIZE-3:0]== comb_gray_w_ptr[P_SIZE-3:0]) ;



endmodule

