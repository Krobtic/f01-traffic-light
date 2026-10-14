`default_nettype none

module fsm_traffic_light (
    input  wire       clk,        // Xung clock hệ thống (1Hz / 1s)
    input  wire       rst_n,      // Reset bất đồng bộ mức thấp (0)
    input  wire [7:0] uio_in,     // uio_in[0] = Chế độ ban đêm (1: Đêm, 0: Ngày)
    input  wire [7:0] ui_in,      // Ngõ vào phụ (Không sử dụng, đặt 8'h00)
    output reg  [7:0] uo_out,     // uo_out[2:0]=H1, uo_out[5:3]=H2, uo_out[7:6]=State
    output wire [7:0] uio_out,    // Ngõ ra phụ (Không sử dụng, đặt 8'h00)
    output wire [7:0] uio_oe      // Điều khiển chiều I/O (Đặt 8'h00 = chọn Input)
);

    // Vô hiệu hóa các chân I/O không dùng
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    // Tham số thời lượng từng pha (Số chu kỳ clock)
    parameter TIME_GREEN  = 10;
    parameter TIME_YELLOW = 3;

    // Mã hóa 4 trạng thái Ban ngày (Binary Encoding)
    localparam S_H1G_H2R = 2'b00; // S0: Hướng 1 Xanh (10s), Hướng 2 Đỏ (10s)
    localparam S_H1Y_H2R = 2'b01; // S1: Hướng 1 Vàng (3s),  Hướng 2 Đỏ (3s)
    localparam S_H1R_H2G = 2'b10; // S2: Hướng 1 Đỏ (10s),   Hướng 2 Xanh (10s)
    localparam S_H1R_H2Y = 2'b11; // S3: Hướng 1 Đỏ (3s),    Hướng 2 Vàng (3s)

    // Thanh ghi nội bộ
    reg [1:0] current_state, next_state;
    reg [3:0] timer;
    reg       night_blink;

    wire night_mode = uio_in[0];

    // =========================================================================
    // 1. KHỐI BỘ ĐẾM THỜI GIAN (TIMER) & TẠO XUNG NHẤP NHÁY BAN ĐÊM
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer       <= 4'd0;
            night_blink <= 1'b0;
        end else begin
            night_blink <= ~night_blink; // Đảo bit nhấp nháy mỗi chu kỳ clock
            
            // Xóa bộ đếm khi ở chế độ ban đêm hoặc khi vừa chuyển trạng thái FSM
            if (night_mode || (current_state != next_state)) begin
                timer <= 4'd0;
            end else begin
                timer <= timer + 1'b1;
            end
        end
    end

    // =========================================================================
    // 2. KHỐI LƯU TRẠNG THÁI FSM (STATE MEMORY REGISTER)
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= S_H1G_H2R;
        end else begin
            current_state <= next_state;
        end
    end

    // =========================================================================
    // 3. KHỐI LOGIC CHUYỂN TRẠNG THÁI KẾ TIẾP (NEXT STATE COMBINATIONAL LOGIC)
    // =========================================================================
    always @(*) begin
        // Giá trị mặc định tránh sinh Latch
        next_state = current_state;

        if (!night_mode) begin
            case (current_state)
                S_H1G_H2R: if (timer >= TIME_GREEN - 1)  next_state = S_H1Y_H2R;
                S_H1Y_H2R: if (timer >= TIME_YELLOW - 1) next_state = S_H1R_H2G;
                S_H1R_H2G: if (timer >= TIME_GREEN - 1)  next_state = S_H1R_H2Y;
                S_H1R_H2Y: if (timer >= TIME_YELLOW - 1) next_state = S_H1G_H2R;
                default:   next_state = S_H1G_H2R;
            endcase
        end else begin
            // Ép trạng thái kế tiếp về S0 khi ở chế độ ban đêm
            next_state = S_H1G_H2R;
        end
    end

    // =========================================================================
    // 4. KHỐI GIẢI MÃ NGÕ RA (MOORE OUTPUT DECODER LOGIC)
    // =========================================================================
    always @(*) begin
        // Mã trạng thái FSM xuất ra 2 bit cao nhất
        uo_out[7:6] = current_state;

        if (night_mode) begin
            // Chế độ ban đêm: Nhấp nháy đèn Vàng {Red=0, Yellow=Blink, Green=0}
            uo_out[2:0] = {1'b0, night_blink, 1'b0}; // Đèn Hướng 1
            uo_out[5:3] = {1'b0, night_blink, 1'b0}; // Đèn Hướng 2
        end else begin
            case (current_state)
                S_H1G_H2R: begin
                    uo_out[2:0] = 3'b001; // Hướng 1 Green
                    uo_out[5:3] = 3'b100; // Hướng 2 Red
                end
                S_H1Y_H2R: begin
                    uo_out[2:0] = 3'b010; // Hướng 1 Yellow
                    uo_out[5:3] = 3'b100; // Hướng 2 Red
                end
                S_H1R_H2G: begin
                    uo_out[2:0] = 3'b100; // Hướng 1 Red
                    uo_out[5:3] = 3'b001; // Hướng 2 Green
                end
                S_H1R_H2Y: begin
                    uo_out[2:0] = 3'b100; // Hướng 1 Red
                    uo_out[5:3] = 3'b010; // Hướng 2 Yellow
                end
                default: begin
                    uo_out[2:0] = 3'b100; // Mặc định Đỏ an toàn
                    uo_out[5:3] = 3'b100;
                end
            endcase
        end
    end

    // Triệt tiêu cảnh báo Verilator & loại bỏ hoàn toàn floating nets
    wire _unused = &{ui_in, uio_in[7:1], 1'b0};

endmodule

`default_nettype wire