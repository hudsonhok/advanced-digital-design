/* Copyright 2020 Jason Bakos, Philip Conrad, Charles Daniels */

/* Top-level module for CSCE611 RISC-V CPU, for running under simulation.  In
 * this case, the I/Os and clock are driven by the simulator. */

module simtop;

	logic clk; // , reset;
    logic [6:0] H0, H1, H2, H3, H4, H5, H6, H7;
    logic [55:0] EXPECTED; // expected output
    logic [11:0] counter;  // 12-bit counter, check output every 4096 clk
    logic [17:0] SW;
    logic [73:0] test_vectors [1999:0];  // reading 74 bits each time from tv file
    logic [31:0] vector_num, errors;    // array index

    logic [3:0] KEY;

	top dut
	(
		//////////// CLOCK //////////
		.CLOCK_50(clk),
		.CLOCK2_50(),
	    .CLOCK3_50(),

		//////////// LED //////////
		.LEDG(),
		.LEDR(),

		//////////// KEY //////////
		.KEY(KEY),

		//////////// SW //////////
		.SW(SW),

		//////////// SEG7 //////////
        .HEX0(H0),
        .HEX1(H1),
        .HEX2(H2),
        .HEX3(H3),
        .HEX4(H4),
        .HEX5(H5),
        .HEX6(H6),
        .HEX7(H7)
    );
    // drive the clock
    always begin
        clk =1'b1; #10; clk= 1'b0; #10;
    end

    initial begin
        $readmemb("testvector.tv", test_vectors);
        vector_num = 32'b0;
        errors = 32'b0;
        {SW, EXPECTED} = test_vectors[vector_num];
    end

    // reset pulse to CPU, initialize counter
    initial begin
        counter = 12'b0;
        KEY = 4'b1110;
        #30;
        KEY = 4'b1111;
    end
    
    always @(posedge clk) begin
        counter = counter + 12'b1;
        if (counter == 12'b0) begin
            if ({H7, H6, H5, H4, H3, H2, H1, H0} !== EXPECTED) begin
                $display("Error: Inputs = %b", SW);
                $display("  outputs = %b (%b expected)", {H7, H6, H5, H4, H3, H2, H1, H0}, EXPECTED);
                errors = errors + 32'b1;
            end
        end
        vector_num = vector_num + 32'b1;
        if (test_vectors[vector_num] === 74'bx) begin
            $display("%d tests completed with %d errors", vector_num, errors);
            $finish;
        end
        {SW, EXPECTED} = test_vectors[vector_num];
    end
endmodule

