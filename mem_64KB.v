module mem_64KB (
    input wire [15:0] address,
    output reg [31:0] data_out   
);

    localparam mem_entries = (1<<16);
    reg[31:0] mem[0:mem_entries-1];



    always @(address)
        begin
                data_out <= mem[address];
        end


endmodule
