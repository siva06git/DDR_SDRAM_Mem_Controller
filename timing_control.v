module timing_control(
    input wire clk,
    input wire reset,

    input wire activate_issued,
    input wire read_issued,
    input wire write_issued,
    input wire precharge_issued,
    input wire refresh_issued,

    output reg tRCD_done,
    output reg tRP_done,
    output reg tRAS_done,
    output reg tRFC_done,
    output reg tWR_done,
    output reg tWTR_done,
    output reg tRTP_done,

    output reg tRCD_running,
    output reg tRP_running,
    output reg tRAS_running,
    output reg tRFC_running,
    output reg tWR_running,
    output reg tWTR_running,
    output reg tRTP_running,

    output reg refresh_req
);
   
    parameter tRCD = 3;     //RAS to CAS delay
    parameter tRP = 10;     //PRECHARGE to ACTIVATE delay
    parameter tRAS = 10;    //ACTIVATE to RAS delay
    parameter tRFC = 10;    //time taken to refresh
    parameter tWR = 10;     //WRITE to CAS delay
    parameter tWTR = 10;    //WRITE to READ delay
    parameter tRTP = 10;    //PRECHARGE to ACTIVATE delay

    reg [2:0] tRCD_counter;
    reg [2:0] tRP_counter;
    reg [2:0] tRAS_counter;
    reg [2:0] tRFC_counter;
    reg [2:0] tWR_counter;
    reg [2:0] tWTR_counter;
    reg [2:0] tRTP_counter;

    reg       tRCD_running;
    reg       tRP_running;
    reg       tRAS_running;
    reg       tRFC_running;
    reg       tWR_running;
    reg       tWTR_running;
    reg       tRTP_running;
    reg       tREFI_running; ;

always @(posedge clk or posedge reset) begin

    if (reset) begin
      //refresh cycle counter begins
       tREFI_counter <=0;
       tREFI_running <=1;

       tRCD_running <= 0;
       tRP_running  <= 0;
       tRAS_running <= 0;
       tRFC_running <= 0;
       tWR_running  <= 0;
       tWTR_running <= 0;
       tRTP_running <= 0;
       
       tRCD_counter <= 0;
       tRP_counter  <= 0;
       tRAS_counter <= 0;
       tRFC_counter <= 0;
       tWR_counter  <= 0;
       tWTR_counter <= 0;
       tRP_counter  <= 0;

       tRCD_done    <= 0;
       tRP_done     <= 0;
       tRAS_done    <= 0;
       tRFC_done    <= 0;
       tWR_done     <= 0;
       tWTR_done    <= 0;
       tRTP_done    <= 0;
    end 
    
    else begin
       if(activate_issued && !tRCD_running) begin 
        tRCD_running <= 1;
        tRCD_counter <= 1;  
            if(tRCD_running) begin 
            if(tRCD_counter == tRCD) begin 
                tRCD_done    <= 1;
                tRCD_running <= 1;
            end
            else begin
                tRCD_counter <= tRCD_counter+1;
            end
        end
       end

       else if(activate_issued && !tRAS_done) begin 
        tRAS_counter <=1;
        tRAS_running <=1;
            if(tRAS_counter == tRAS) begin 
                tRAS_done <= 1;
                tras<tRP_running <= 0;
            end
            else if(tRAS_running) begin 
                tRAS_counter <= tRAS_counter + 1;
            end
       end
        else if(read_issued && !tRTP_done) begin 
            tRTP_running <= 1;
            tRTP_counter <= 1;
            if(tRTP_counter == tRTP)begin 
                tRTP_done <= 1;
                tRTP_running <= 0;
            end
            else if(tRTP_running) begin 
                tRTP_counter <= tRTP_counter+1;
            end
        end

        else if(write_issued && !tWR_done && !tWTR_done) begin 
            tWR_running <= 1;
            tWTR_running <= 1;
            tWR_counter <= 1;
            tWTR_counter <= 1;
                if(tWR_counter == tWR) begin
                    tWR_done <= 1;
                    tWR_running <= 0;
                end
                else if (tWR_running) begin 
                    tWR_counter <= tWR_counter + 1;
                end
                if (tWTR_counter == tWR) begin 
                    tWTR_done <= 1;
                    tWTR_running <= 0;
                end
                else if (tWTR_running) begin 
                    tWTR_counter <= tWTR_counter + 1;
                end
        end

        else if(precharge_issued && !tRP_done) begin 
            tRP_running <= 1;
            tRP_counter <= 1;
                if(tRP_counter == tRP) begin 
                    tRP_done <= 1;
                    tRP_running <= 0;
                end
                else if(tRP_running) begin 
                    tRP_counter <= tRP_counter+1;
                end
        end

        if(refresh_issued && !tRFC_done) begin 
            tRFC_counter <= 1;
            tRFC_running <= 1;
                if(tRFC_counter == tRFC) begin 
                 tRFC_done    <= 1;
                 tRFC_running <= 0;    
                end
                else if (tRFC_running) begin 
                    tRFC_counter <= tRFC_counter+1;
                end
        end
        if(tREFI_running) begin
            if(tREFI_counter == tREFI) begin
                tREFI_done <= 1;
                tREFI_running <= 0;
                refresh_req = 1;
            end
            else if(tREFI_running) begin
                tREFI_counter <= tREFI_counter+1;
            end
        
        end
    end
end
endmodule