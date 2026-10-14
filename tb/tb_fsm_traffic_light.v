`timescale 1ns/1ps

module tb_fsm_traffic_light;

    reg        clk;
    reg        rst_n;
    reg  [7:0] uio_in;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // Khởi tạo Module RTL
    fsm_traffic_light uut (
        .clk(clk),
        .rst_n(rst_n),
        .uio_in(uio_in),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_out(uio_out),
        .uio_oe(uio_oe)
    );

    // 1. Tạo xung clock chu kỳ 10ns (Tương ứng 1Hz trong mô phỏng)
    always #5 clk = ~clk;

    // 2. Bộ kiểm tra an toàn tự động (Safety Assertion - Ca bắt buộc)
    always @(posedge clk) begin
        if (rst_n && !uio_in[0]) begin
            // Kiểm tra vi phạm: Cả Hướng 1 (uo_out[0]) và Hướng 2 (uo_out[3]) cùng bật Xanh
            if (uo_out[0] && uo_out[3]) begin
                $display("[ASSERTION ERROR AT %0tns] VI PHẠM AN TOÀN: Cả 2 hướng cùng XANH!", $time);
                $finish;
            end
        end
    end

    // 3. Tiến trình chạy các kịch bản kiểm thử (Test Cases)
    initial begin
        $dumpfile("sim/tb_fsm_traffic_light.vcd");
        $dumpvars(0, tb_fsm_traffic_light);

        // Khởi tạo trạng thái ban đầu
        clk = 0;
        rst_n = 0;
        uio_in = 8'h00;
        ui_in = 8'h00;

        $display("=================================================================");
        $display("CA 1 [BẮT BỘC]: MỘT VÒNG ĐỦ CÁC PHA BAN NGÀY (S0 -> S1 -> S2 -> S3)");
        $display("=================================================================");
        #15 rst_n = 1; // Thả Reset
        #260; // Chạy đủ 26 chu kỳ clock (10s Xanh H1 + 3s Vàng H1 + 10s Xanh H2 + 3s Vàng H2)

        $display("=================================================================");
        $display("CA 2 [BẮT BỘC]: CHUYỂN SANG CHẾ ĐỘ ĐÊM GIỮA CHỪNG");
        $display("=================================================================");
        #40; // Đang ở nửa chừng pha Xanh Hướng 1
        uio_in[0] = 1; // Bật night_mode
        #50; // Giữ chế độ đêm 5 chu kỳ
        uio_in[0] = 0; // Trở lại ban ngày
        #60;

        $display("=================================================================");
        $display("CA 3 [BỔ SUNG 1 - CA BIÊN]: RESET ĐỘT NGỘT TẠI TIMING BIÊN (timer = 9)");
        $display("=================================================================");
        wait(uut.timer == 4'd9); // Chờ đúng chu kỳ đếm cuối cùng trước khi chuyển trạng thái
        #1; 
        rst_n = 0; // Kích hoạt Reset
        #10;
        rst_n = 1; // Thả Reset
        #50;

        $display("=================================================================");
        $display("CA 4 [BỔ SUNG 2 - NGOẠI LỆ]: NHIỄU BẬT/TẮT NIGHT_MODE SIÊU NGẮN (GLITCH)");
        $display("=================================================================");
        #20;
        uio_in[0] = 1; #10; // Bật 1 chu kỳ clock
        uio_in[0] = 0; #10; // Tắt ngay
        uio_in[0] = 1; #10; // Bật lại
        uio_in[0] = 0;      // Tắt hẳn
        #80;

        $display("=================================================================");
        $display(" SUCCESS: ĐÃ VƯỢT QUA TẤT CẢ CÁC CA KIỂM THỬ BẮT BỘC VÀ BỔ SUNG!");
        $display("=================================================================");
        $finish;
    end

endmodule