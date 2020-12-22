
module PCI_TARGET (
    inout [31:0] ADDR_DATA,
    input [3:0] C_BE,
    input CLK,
    input RST,
    input FRAME,
    input IRDY,
    output reg TRDY,
    output reg DEVSEL
      );


    reg [15:0] ADDR ;
    reg [31:0] DATA ;
    reg data_out_enable;
    assign ADDR_DATA = data_out_enable? DATA : 32'bZ;
    reg target_need_time;
    wire [31:0] data_out;
    mem_64KB mymem (ADDR,data_out);  

    parameter standby = 2'b000 ,
              turn_around = 2'b001 ,
              data_transfer = 2'b010 ,
              wait_target = 2'b011 ,
              wait_initiator = 2'b100 ,
              device_address = {4{4'b0000}} ,
              READ = 4'b0001 ,
              WRITE = 4'b0010 ,
              last_byte_address = {4{4'b1111}};

    reg [2:0] state,nextstate;

   //synchrounous block
    always @(posedge CLK)
        begin
            if (~RST)
                state <= standby;
            else
                state <= nextstate;
        end
    //end of synchrounous block



    // combinational block for next state

        always @(posedge CLK)
            begin
                case (state)
                     standby:begin
                         if (FRAME == 1 || (FRAME == 0 && ADDR_DATA[31:16] != device_address))
                             nextstate <= standby; 
                                 
                         else if (FRAME == 0 && ADDR_DATA == device_address && C_BE == READ)
                             begin
                                     ADDR <= ADDR_DATA;
                                     nextstate <= turn_around;
                             end
                                 
                         
                             end
                              
                     turn_around:
                         begin

                         if(FRAME == 1)
                             nextstate <= standby;
                         else if(FRAME == 0 && IRDY == 0)
                             nextstate <= data_transfer;
                         else if(FRAME == 0 && IRDY == 1)
                             nextstate <= wait_initiator;
                         end

  
                     data_transfer: 
                                 
                      begin
                                         
                         data_out_enable = 1'b1;                                                    
                         if (FRAME == 1)
                             nextstate <= standby;
                         else if (FRAME == 0 && IRDY == 1)
                             nextstate <= wait_initiator;
                         else if (FRAME == 0 && IRDY == 0 && (ADDR == last_byte_address)  )   //when Master try to read from last byte in memory
                             nextstate <= wait_target;                                        //the target needs one more clock cycle before its ready  

                       end
                     

                     wait_target: begin

                         if (FRAME == 1)
                             nextstate <= standby;

                         if (FRAME == 0 && IRDY == 0)
                             nextstate <= data_transfer;

                         else if (FRAME == 0 && IRDY == 1)
                             nextstate <= wait_initiator;
                                  end
                     wait_initiator: begin 
                         if (FRAME == 0 && IRDY == 1)
                             nextstate <= wait_initiator;
                         else if (FRAME == 0 && IRDY == 0)
                             nextstate <= data_transfer;
                                     end
                endcase
            end
      // end of always block for the next state
      

      // always block for outputs
       always@(negedge CLK)
            
            begin
            
            case(state)
               
                standby: begin
                             TRDY <= 1;
                             DEVSEL <=1;
                          end
                
                turn_around: DEVSEL <= 0;

                data_transfer:begin
                              DATA <= data_out;
                              TRDY <= 0;
                              end
                 
                 wait_target: TRDY <= 1;

                 wait_initiator: TRDY <= 0;
            endcase                            
           
            end



      // end of outputs block 

endmodule