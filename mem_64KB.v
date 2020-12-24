module mem_4GB (
    input wire [31:0] address,
    input wire [31:0] data_in,
    input wire [3:0] control,
    input wire [3:0] byte_enable,
    output reg [31:0] data_out   
);

    
     reg bit_mask;
    localparam mem_entries = (1<<32);
    reg[31:0] mem[0:mem_entries-1];



    always @(address or control or data_in)
        begin
                bit_mask = {{8{byte_enable[3]}},{8{byte_enable[2]}},{8{byte_enable[1]}},{8{byte_enable[0]}}};
		if(control == 4'b0010)
                mem[address] <=  (mem[address] & ~bit_mask) | (data_in & bit_mask);
         else if (control == 4'b0001)
                data_out <= mem[address];
        end


endmodule
