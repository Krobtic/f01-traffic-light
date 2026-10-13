`timescale 1ns/1ps

module tb_fsm_traffic_light;

    reg        clk;
    reg        rst_n;
    reg  [7:0] uio_in;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // Instantiate Module RTL
    fsm_traffic_light uut (
        .clk(clk),
        .rst_n(rst_n),
        .uio_in(uio_in),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_out(uio_out),
        .uio_oe(uio_oe)
    );

    // 1. Tạo xung clock 1Hz (chu kỳ 10ns trong mô phỏng)
    always #5 clk = ~clk;

    // 2. Tự động kiểm tra điều kiện an toàn (Safety Assertion)
    always @(posedge clk) begin
        if (rst_n && !uio_in[0]) begin
            if (uo_out[0] && uo_out[3]) begin
                $display("[ERROR AT %0tns] VI PHẠM AN TOÀN: Cả 2 hướng cùng XANH!", $time);
                $finish;
            end
        end
    end

    // 3. Kịch bản kiểm thử (Test Cases)
    initial begin
        // Ghi file dạng sóng VCD để xem bằng GTKWave
        $dumpfile("sim/tb_fsm_traffic_light.vcd");
        $dumpvars(0, tb_fsm_traffic_light);

        // Khởi tạo
        clk = 0;
        rst_n = 0;
        uio_in = 8'h00;
        ui_in = 8'h00;

        $display("=== BẮT ĐẦU KIỂM THỬ BAN NGÀY ===");
        #15 rst_n = 1; // Thả Reset

        // Cho chạy đủ 1 vòng chu kỳ Ban ngày (10s + 3s + 10s + 3s = 26 chu kỳ)
        #260;

        $display("=== BẮT ĐẦU KIỂM THỬ CHẾ ĐỘ BAN ĐÊM ===");
        uio_in[0] = 1; // Bật night_mode
        #60;

        $display("=== THOÁT CHẾ ĐỘ ĐÊM TRỞ VỀ BAN NGÀY ===");
        uio_in[0] = 0; // Tắt night_mode
        #100;

        $display("==========================================");
        $display(" SUCCESS: TẤT CẢ KỊCH BẢN KIỂM THỬ ĐÃ ĐẠT!");
        $display("==========================================");
        $finish;
    end

endmodule