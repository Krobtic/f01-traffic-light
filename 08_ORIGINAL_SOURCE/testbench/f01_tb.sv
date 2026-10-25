module f01_tb;
    logic clk,rst_n,ena,night_mode;
    logic [7:0] uo_out;

    f01_traffic_fsm #(.PHASE_TICKS(2),.NIGHT_TICKS(2)) dut(
        .clk(clk),.rst_n(rst_n),.ena(ena),
        .night_mode(night_mode),.uo_out(uo_out)
    );

    always #5 clk=~clk;

    function automatic bit both_green(input logic [7:0] x);
        return (x[0] && x[3]);
    endfunction

    initial begin
        clk=0; rst_n=0; ena=1; night_mode=0;
        repeat(2) @(posedge clk);
        rst_n=1;

        // Source-required complete-cycle safety observation.
        repeat(12) begin
            @(posedge clk); #1;
            assert(!both_green(uo_out))
                else $fatal(1,"SAFETY VIOLATION: both directions green");
        end

        // Source-required night-mode transition.
        night_mode=1;
        repeat(4) begin
            @(posedge clk); #1;
            assert(!both_green(uo_out))
                else $fatal(1,"SAFETY VIOLATION in night mode");
        end

        // Additional boundary: disable enable and confirm no illegal green.
        ena=0;
        repeat(2) begin
            @(posedge clk); #1;
            assert(!both_green(uo_out));
        end

        // Return to normal operation.
        ena=1; night_mode=0;
        repeat(6) begin
            @(posedge clk); #1;
            assert(!both_green(uo_out));
        end

        $display("F01 TB PASS");
        $finish;
    end
endmodule
