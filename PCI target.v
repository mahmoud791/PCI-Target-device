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
    reg [31:0] DATA_IN;
    reg data_out_enable;
    assign ADDR_DATA = data_out_enable? DATA : 32'bZ;
    wire [31:0] data_out;
    reg [31:0] data_in_buffer;
    reg write_enable;
    reg [2:0] state,nextstate;
    reg [3:0] CONTROL;
    reg [3:0] BYTE_ENABLE; 
    reg [31:0] BACKUP_BUFFER_ADDRESS;
    reg[31:0] POINTER = {device_address,2'b00}
    mem_4GB mymem(ADDR, DATA_IN, CONTROL, data_out);
    mem_16reg mybuffer(BACKUP_BUFFER_ADDRESS, data_in_buffer);

    parameter idle = 4'b0000,
              read_address = 4'b0001,
              turnaround_read=4'b0010,
              data_read=4'b0011,
              wait_initiator = 4'b0100,
              last_read = 4'b0101,
              turnaround_main = 4'b0110,
              data_write = 4'b0111,
              last_write = 4'b1000,
              buffer_full = 4'b1001,
              device_address = {6{5'b00000}},
              READ = 4'b0001 ,
              WRITE = 4'b0010 ,
              last_address = {device_address,2'b11};
              

   //sychrounous block of state

              always@(posedge CLK)
              begin
                  if (!RST)
                      state <= idle;
                  else
                      state <= nextstate;

              end 

   //end of synchrounous block of state
  

   // synchrounous block of next state

              always @(posedge CLK)
                  begin
                      case(state)
                      idle:
                          begin
                              data_out_enable <= 0;

                              if (FRAME == 1)
                                  nextstate <= idle;
                              else if (FRAME == 0)
                                  ADDR <= ADDR_DATA;
                                  CONTROL <= C_BE;
                                  nextstate < read_address;
                          end
                       read_address:
                          begin
                              if (ADDR == device_address && CONTROL == READ && IRDY == 0 && FRAME == 0)
                                  nextstate <= turnaround_read;
                              else if (ADDR == device_address && CONTROL == WRITE && IRDY == 0 && FRAME == 0)
                                  nextstate <= data_write;
                              else if (ADDR != device_address)
                                  nextstate <= idle;

                          end
                       turnaround_read:
                          begin
                              if (IRDY == 1)
                                  nextstate <= wait_initiator;
                              else if (IRDY == 0 && FRAME == 1)
                                  nextstate <= last_read;
                              else if (IRDY == 0 && FRAME == 0);
                                  nextstate <= data_read;

                          end

                        data_read:
                          begin
                              data_out_enable <= 1'b1;
                              if (IRDY == 1 && FRAME ==0)
                                  nextstate <= wait_initiator;
                              else if (FRAME == 0 && IRDY == 0)
                                  begin
                                  nextstate < data_read;
                                  ADDR <= ADDR+1;
                                  if (ADDR == last_address)
                                      ADDR <= device_address;
                                  end
                              else if (FRAME == 1 && IRDY ==0)
                                  nextstate <= last_read;

                          end

                        wait_initiator:
                          begin
                              if (IRDY == 1)
                                  nextstate <= wait_initiator;
                              else if (FRAME == 0 && IRDY == 0 && CONTROL == WRITE)
                                  nextstate <= data_write;
                              else if (FRAME == 1 && IRDY && CONTROL == WRITE)
                                  nextstate <= last_write;
                              else if (FRAME == 1 && IRDY == 0 && CONTROL == READ)
                                  nextstate <= last_read;
                              else if (FRAME == 0 && IRDY == 0 && CONTROL == READ)
                                  nextstate <= data_read;
                          end

                        data_write:
                          begin
                              BYTE_ENABLE <= C_BE;
                              if (FRAME == 0 && IRDY == 0 && ADDR <= last_address)
                                  begin
                                      ADDR <= ADDR +1;
                                      nextstate <= data_write;
                                  end
                                  
                              else if (FRAME == 1 && IRDY ==0 )
                                  nextstate <= last_write;
                              else if (ADDR == last_address +1 && IRDY == 0 && FRAME ==0)
                                  begin
                                      nextstate <= buffer_full;
                                      ADDR <= device_address;
                                  end
                              else if (IRDY == 1)
                                  nextstate <= wait_initiator;
                          end

                         last_write:
                          begin
                                  nextstate <= turnaround_main;
                          end

                         buffer_full:
                          begin
                              if (POINTER != last_address)
                                  begin
                                BACKUP_BUFFER_ADDRESS <= BACKUP_BUFFER_ADDRESS+1
                                nextstate <= buffer_full;
                                POINTER <= POINTER +1;
                                  end
                                
                              else if (POINTER == last_address)
                                 nextstate <= data_write;
                          end
                        last_read:
                          begin
                              nextstate <= turnaround_main
                          end

                        turnaround_main:
                          begin
                              nextstate <= idle;
                          end

                      endcase
                  end

   // end of synchrounous block of next state


  // synchrounous block of output


                  always @(negedge CLK)
                      begin
                          case(state)

                              idle:
                              begin
                                  TRDY<=1;
                                  DEVSEL<=1;
                              end
                               
                              read_address:
                              begin
                                  DEVSEL <=1;
                                  TRDY <=1;
                              end

                              turnaround_read:
                              begin
                                  DEVSEL <= 0;
                                  TRDY <=0;
                              end

                              wait_initiator :;

                              data_read:
                              begin
                                  DATA <= data_out;
                              end

                              data_write:
                              begin
                               DATA_IN <= ADDR_DATA & {8{BYTE_ENABLE[3]},8{BYTE_ENABLE[2]},8{BYTE_ENABLE[1]},8{BYTE_ENABLE[0]}}; 
                               
                              end
                              
                              

                              


                          endcase
                      end


 //end of synchrounous block of output


endmodule 