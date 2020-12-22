module mem_4GB (
    input wire [31:0] address,
    input wire [31:0] data_in,
    input wire control,
    output reg [31:0] data_out   
);

    localparam mem_entries = (1<<32);
    reg[31:0] mem[0:mem_entries-1];



    always @(address)
        begin

		if(control == 1'b1)
		mem[address]<=data_in;
		else
                data_out <= mem[address];
        end


endmodule
