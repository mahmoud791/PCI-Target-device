module test_bench_MASTER();

    reg CLK;
    wire [31:0] ADDR_DATA_1;
    wire [31:0] ADDR_DATA_2;
    wire [31:0] ADDR_DATA_3;
    wire [31:0] ADDR_DATA_4;
    reg switch_1;
    reg switch_2;
    reg switch_3;
    reg switch_4; 
    reg [31:0] ADDR_1;
    reg [31:0] ADDR_2;
    reg [31:0] ADDR_3;
    reg [31:0] ADDR_4;
    reg [31:0] DATA_1;
    reg [31:0] DATA_2;
    reg [31:0] DATA_3;
    reg [31:0] DATA_4;
    assign ADDR_DATA_1 = switch_1 ? ADDR_1: DATA_1;
    assign ADDR_DATA_2 = switch_2 ? ADDR_2: DATA_2 ;
    assign ADDR_DATA_3 = switch_3 ? ADDR_3: DATA_3;
    assign ADDR_DATA_4 = switch_4 ? ADDR_4 : DATA_4;
    reg [3:0] C_BE_1 ;
    reg [3:0] C_BE_2 ;
    reg [3:0] C_BE_3 ;
    reg [3:0] C_BE_4 ;
    reg RST_1 ;
    reg RST_2;
    reg RST_3;
    reg RST_4;
    reg FRAME_1 = 1'b1;
    reg FRAME_2 = 1'b1;
    reg FRAME_3 = 1'b1;
    reg FRAME_4 = 1'b1;
    reg IRDY_1 = 1'b1;
    reg IRDY_2 = 1'b1;
    reg IRDY_3 = 1'b1;
    reg IRDY_4 = 1'b1;
    wire TRDY_1;
    wire TRDY_2;
    wire TRDY_3;
    wire TRDY_4;
    wire DEVSEL_1;
    wire DEVSEL_2;
    wire DEVSEL_3;
    wire DEVSEL_4;

    PCI_TARGET pci_1(ADDR_DATA_1,C_BE_1,CLK,RST_1,FRAME_1,IRDY_1,TRDY_1,DEVSEL_1);

    PCI_TARGET pci_2(ADDR_DATA_2,C_BE_2,CLK,RST_2,FRAME_2,IRDY_2,TRDY_2,DEVSEL_2);

    PCI_TARGET pci_3(ADDR_DATA_3,C_BE_3,CLK,RST_3,FRAME_3,IRDY_3,TRDY_3,DEVSEL_3);

    PCI_TARGET pci_4(ADDR_DATA_4,C_BE_4,CLK,RST_4,FRAME_4,IRDY_4,TRDY_4,DEVSEL_4);





    always 
        begin
            #10 CLK = ~CLK;
        end

    
    initial
        begin
            CLK = 1;
            #5   
                FRAME_1 <=0;
                switch_1 <= 1;
                ADDR_1 <= 32'b0;
                C_BE_1 <= 4'b0010;
           #15

                IRDY_1 <= 0;
                C_BE_1 <= 4'b1111;


            #25
                switch_1 <= 0;
                DATA_1 <= 32'h0000000E;
                FRAME_1 <=1;
            #35
                IRDY_1 <= 1;

        end



endmodule

