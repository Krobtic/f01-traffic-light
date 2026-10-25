`default_nettype none

module tt_um_f01_traffic_light (
    input  wire [7:0] ui_in,    // Ngõ vào phụ (không dùng)
    output wire [7:0] uo_out,   // Ngõ ra đèn giao thông & trạng thái
    input  wire [7:0] uio_in,   // uio_in[0] = night_mode, uio_in[1] = ena
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      // Enable toàn mạch
    input  wire       clk,      // Clock hệ thống
    input  wire       rst_n     // Reset tích cực mức thấp
);

    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    // ĐẤU NỐI VÀO DÚNG TÊN MODULE LÕI CỦA THẦY (f01_traffic_fsm_explicit)
    f01_traffic_fsm_explicit fsm_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .ena        (ena && uio_in[1]),
        .night_mode (uio_in[0]),
        .uo_out     (uo_out)
    );

    // Triệt tiêu cảnh báo chân không sử dụng
    wire _unused = &{ui_in, uio_in[7:2], 1'b0};

endmodule

`default_nettype wire