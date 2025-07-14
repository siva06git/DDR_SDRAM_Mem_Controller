module address_decoder(
    input wire [31:0]req_addr,
    output reg [31:0]req_write,
    output reg [31:0]req_read,
   
    output reg [9:0]  col_addr,
    output reg [2:0]  bank_addr,
    output reg [13:0] row_addr,
    output reg [31:0] req_wdata,

);

always@(*) begin 
    wire [13:0] row_addr = req_addr[25:12];
    wire [9:0]  col_addr = req_addr[12:3];
    wire [2:0]  bank_addr = req_addr[3:1];


end




endmodule