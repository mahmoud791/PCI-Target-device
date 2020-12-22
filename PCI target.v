
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


    reg [31:0] ADDR ;
    reg [31:0] DATA ;
    reg data_out_enable;
    reg data_in_enable;
    assign ADDR_DATA = data_out_enable? DATA : 32'bZ;
    assign DATA = data_in_enable? ADDR_DATA : 32'bZ;
    wire [31:0] data_out;
    mem_64KB mymem (ADDR,DATA,C_BE,data_out);  

    parameter standby = 4'b0000 ,
              turn_around = 4'b0001 ,
              data_transfer = 4'b0010 ,
              wait_target = 4'b0011 ,
              wait_initiator = 4'b0100 ,
              device_address = {4{4'b0000}} ,
              READ = 4'b0001 ,
              WRITE = 4'b0010 ,
              last_byte_address = {4{4'b1111}};
/////////////////////////////////////////////////////////////////////////////
    parameter read_address = 4'b0101 ,
	      write_data = 4'b0110 ,
	      wait_initiator_w = 4'b0111 , 
	      wait_target_w = 4'b1000 ,
	      last_read = 4'b1000;

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
                                 
                         else if (FRAME == 0 && (ADDR_DATA == device_address) && (C_BE == READ))
                             begin
                                     ADDR <= ADDR_DATA;
                                     nextstate <= turn_around;
                             end

                         else if (FRAME == 0 && (ADDR_DATA == device_address) && (C_BE == WRITE))
                             begin
                                     ADDR <= ADDR_DATA;
                                     nextstate <= read_address;
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
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                     read_address: begin 
                         if (FRAME == 0 && IRDY == 1)
                             nextstate <= read_address;
                         else if (FRAME == 0 && IRDY == 0)
                             nextstate <= wait_target_w;
                                     end
                     write_data: begin 
                         if (FRAME == 0 && IRDY == 1)
                             nextstate <= wait_initiator_w;
                         else if (FRAME == 0 && IRDY == 0)
                             nextstate <= write_data;
                         else if (FRAME == 1)
                             nextstate <= last_read;
                         else if (FRAME == 0 && IRDY == 0 && (ADDR == last_byte_address)  )   //when Master try to read from last byte in memory
                             nextstate <= wait_target_w;                                   //the target needs one more clock cycle before its ready  
                                     end
                     wait_initiator_w: begin 
                         if (IRDY == 1)
                             nextstate <= wait_initiator_w;
                         else if (FRAME == 0 && IRDY == 0)
                             nextstate <= write_data;
                         else if (FRAME == 1 && IRDY == 0)
                             nextstate <= last_read;
                                     end
                     wait_target_w: begin 
                         if (IRDY == 1)
                             nextstate <= wait_initiator_w;
                         else if (FRAME == 0 && IRDY == 0)
                             nextstate <= write_data;
                         else if (FRAME == 1 && IRDY == 0)
                             nextstate <= last_read;
                                     end
                     last_read: begin 
                         if (FRAME == 1 && IRDY == 1)
                             nextstate <= wait_initiator_w;
                         else if (FRAME == 1 && IRDY == 0)
                             nextstate <= turn_around;
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
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                     wait_target_w: begin 
                             TRDY <= 1;
                             DEVSEL <=1;
				   end
                     write_data: begin 
			data_in <= ADDR_DATA;
				   end
                     wait_initiator_w: begin 
			
				   end
                     last_read: begin 
			
				   end

            endcase                            
           
            end



      // end of outputs block 

endmodule