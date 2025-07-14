module command_fsm(
    input wire clk,
    input wire reset,

    input wire init_done,
    input wire read_req,
    input wire write_req,
    input wire refresh_req,

    //Address info 
    input wire [13:0] row_addr,
    input wire [9:0]  col_addr,
    input wire [2:0]  bank_addr,

    //Timing control
    input wire tRCD_done,
    input wire tRP_done,
    input wire tRAS_done,
    input wire tRFC_done,
    input wire tWR_done,
    input wire tWTR_done,
    input wire tRTP_done,
    

    output reg activate_issued,
    output reg read_issued,
    output reg write_issued,
    output reg precharge_issued,
    output reg refresh_issued,

    //To Physical layer
    output reg cas_n,
    output reg ras_n,
    output reg we_n,
    output reg cs_n,
    output reg [13:0] addr,
    output reg [2:0] ba,
    output reg cmd_valid

);

// State encoding
    parameter IDLE      = 3'b000;
    parameter ACTIVATE  = 3'b001;
    parameter READ      = 3'b010;
    parameter WRITE     = 3'b011;
    parameter PRECHARGE = 3'b100;
    parameter REFRESH   = 3'b101;


reg [2:0] state, next_state;

// Sequential logic for state register
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end
assign bus_idle = (state == IDLE || state == PRECHARGE_DONE) &&
                  !tRCD_running &&
                  !tWR_running &&
                  !tRFC_running &&
                  !tRP_running &&
                  !read_pending &&
                  !write_pending;
                  
// Combinational logic for next state and outputs
always @(*) begin
    // Default outputs
    cas_n = 1'b1;
    ras_n = 1'b1;
    we_n = 1'b1;
    cs_n = 1'b1;
    addr = 14'b0;
    ba = 3'b0;
    cmd_valid = 1'b0;
    next_state = state;

    activate_issued = 1'b0;
    read_issued     = 1'b0;
    write_issued    = 1'b0;
    refresh_issued  = 1'b0;
    precharge_issued = 1'b0;

    case (state)
        IDLE: begin
            if (init_done) begin
                if (refresh_req) begin
                    next_state = REFRESH;
                end else if (read_req || write_req) begin
                    next_state = ACTIVATE;
                end
            end
        end

        ACTIVATE: begin
            // Issue ACTIVATE command
            activate_issued = 1'b1;
            cas_n = 1'b1; 
            ras_n = 1'b0;
            we_n = 1'b1;
            cs_n = 1'b0;
            addr = row_addr;
            ba = bank_addr;
            cmd_valid = 1'b1;
            
            if (tRCD_done) begin
                if (read_req) begin
                    next_state = READ;
                end

                else if (write_req) begin
                    next_state = WRITE;
                end
            end
        end

        READ: begin
            // Issue READ command
            read_issued = 1'b1;
            cas_n = 1'b0;
            ras_n = 1'b1;
            we_n = 1'b1;
            cs_n = 1'b0;
            addr = {4'b0, col_addr};
            ba = bank_addr;
            cmd_valid = 1'b1;
            if(tRTP_done) begin 
            next_state = PRECHARGE;
            end
        end

        WRITE: begin
            // Issue WRITE command
            write_issued = 1'b1;
            cas_n = 1'b0;
            ras_n = 1'b1;
            we_n = 1'b0;
            cs_n = 1'b0;
            addr = {4'b0, col_addr};
            ba = bank_addr;
            cmd_valid = 1'b1;
            
            if (tWR_done && tWTR_done) begin
                next_state = PRECHARGE;
            end
        end

        PRECHARGE: begin
            // Issue PRECHARGE command
            precharge_issued = 1'b1;
            cas_n = 1'b1;
            ras_n = 1'b0;
            we_n = 1'b0;
            cs_n = 1'b0;
            addr = 14'b0; // All banks
            ba = 3'b0;
            cmd_valid = 1'b1;
            
            if (tRP_done) begin
                next_state = IDLE;
            end
        end

        REFRESH: begin
            // Issue REFRESH command
            refresh_issued = 1'b1;
            cas_n = 1'b0;
            ras_n = 1'b0;
            we_n = 1'b1;
            cs_n = 1'b0;
            addr = 14'b0;
            ba = 3'b0;
            cmd_valid = 1'b1;
            
            if (tRFC_done) begin
                next_state = IDLE;
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule