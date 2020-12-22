module mem_4GB (
    input wire [31:0] address,
    input wire [31:0] data_in,
    input wire [3:0] control,
    output reg [31:0] data_out   
);

    localparam mem_entries = (1<<32);
    reg[31:0] mem[0:mem_entries-1];



    always @(address)
        begin
		if(control == 4'b0001)
                data_out <= mem[address];
		else if(control == 4'b0010)
		mem[address]<=data_in;
        end


endmodule
