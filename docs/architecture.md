    # CHƯƠNG 2: ĐẶC TẢ KIẾN TRÚC PHẦN CỨNG & MÔ HÌNH HOẠT ĐỘNG

## PHẦN 1: TỔNG QUAN KIẾN TRÚC & MÔ HÌNH HOẠT ĐỘNG TỔNG QUÁT

- **Mô hình kiến trúc (FSM + Datapath):** Hệ thống được thiết kế phân tách rõ ràng giữa hai khối chính:
  - **Control Unit (FSM Core):** Đảm nhận vai trò điều phối chuyển pha giao thông dựa trên trạng thái hiện tại và tín hiệu điều khiển đầu vào.
  - **Datapath (Timer & Blink Generator):** Đảm nhận đếm thời lượng cho từng pha đèn ($10\text{s}$ Green, $3\text{s}$ Yellow) và phát xung nhấp nháy 1-bit phục vụ chế độ ban đêm.
- **Mô hình FSM (Moore State Machine):** Tín hiệu ngõ ra chỉ phụ thuộc trực tiếp vào trạng thái hiện tại (`current_state`), giúp triệt tiêu nhiễu kim (glitch) từ các tín hiệu đầu vào.
- **Tích hợp trong Tile vi mạch:** Khối `fsm_traffic_light` nằm trọn trong ô 1×1 tile, giao tiếp với hệ thống bên ngoài qua tập chân I/O tiêu chuẩn Tiny Tapeout.

---

## PHẦN 2: KIẾN TRÚC PHẦN CỨNG CHI TIẾT & SƠ ĐỒ KHỐI

### 2.1. Sơ đồ khối ASCII (Hiển thị trực tiếp trong Text Editor)

                 +-----------------------+
  clk ---------> | 1-bit Blink Generator |----> night_blink
  rst_n -------> +-----------------------+
                             |
                             v
                 +-----------------------+
  clk ---------> |  4-bit Timer Counter  |----> timer[3:0]
  rst_n -------> +-----------------------+
                             |
                             v
                 +-----------------------+
  uio_in[0] ---> |   Next State Logic    |<---+
 (night_mode)    +-----------------------+    |
                             |                |
                             v next_state     | current_state
                 +-----------------------+    |
                 | 2-bit State Register  |----+----> uo_out[7:6]
                 +-----------------------+
                             |
                             v
                 +-----------------------+
                 | Output Decoder Logic  |----> uo_out[5:0] (H1 & H2)
                 +-----------------------+

### 2.2. Phân bổ chân I/O trên khung Tiny Tapeout

- `ui_in[7:0]`: Nối đất (`8'h00`) do không sử dụng đầu vào phụ.
- `uio_in[0]`: Nhận tín hiệu `night_mode` (`0`: Ban ngày, `1`: Ban đêm).
- `uio_oe[7:0]`: Đặt bằng `8'h00` (cấu hình tất cả các chân `uio` làm ngõ vào Input).
- `uo_out[7:0]`: Ngõ ra 8-bit bao gồm:
  - `uo_out[2:0]`: Đèn Hướng 1 `{Red, Yellow, Green}`.
  - `uo_out[5:3]`: Đèn Hướng 2 `{Red, Yellow, Green}`.
  - `uo_out[7:6]`: Mã trạng thái FSM hiện tại (`current_state`).

---

## PHẦN 3: THANH GHI TRẠNG THÁI & MÃ HÓA TRẠNG THÁI

### 3.1. Bảng mã hóa trạng thái (State Encoding Table)

| Trạng thái FSM | Mã Binary (`2'b`) | Mã One-Hot (`4'b`) | Chức năng hoạt động |
| :--- | :---: | :---: | :--- |
| `S_H1G_H2R` ($S_0$) | `00` | `0001` | Hướng 1 Xanh ($10\text{s}$), Hướng 2 Đỏ ($10\text{s}$) |
| `S_H1Y_H2R` ($S_1$) | `01` | `0010` | Hướng 1 Vàng ($3\text{s}$), Hướng 2 Đỏ ($3\text{s}$) |
| `S_H1R_H2G` ($S_2$) | `10` | `0100` | Hướng 1 Đỏ ($10\text{s}$), Hướng 2 Xanh ($10\text{s}$) |
| `S_H1R_H2Y` ($S_3$) | `11` | `1000` | Hướng 1 Đỏ ($3\text{s}$), Hướng 2 Vàng ($3\text{s}$) |

### 3.2. Ngân sách phần tử nhớ (Flip-Flop Budget)

- **State Register:** 2 Flip-Flops (Mã hóa Binary) hoặc 4 Flip-Flops (Mã hóa One-Hot do Yosys tự động tối ưu).
- **Timer Counter:** 4 Flip-Flops (đếm $0 \rightarrow 15$).
- **Blink Generator:** 1 Flip-Flop.
- **Tổng ngân sách dự kiến:** $7 \sim 9$ Flip-Flops (tương đương $\approx 180 \sim 260$ ô chuẩn standard cells).

---

## PHẦN 4: ĐẶC TẢ CHI TIẾT CÁC KHỐI LOGIC

### 4.1. Khối Bộ đếm thời gian (4-bit Timer Counter)

- **Nguyên lý:** Đếm tăng từng đơn vị mỗi chu kỳ clock khi ở chế độ ban ngày (`night_mode = 0`).
- **Điều kiện Xóa bộ đếm (`clear_timer`):**
  $$\text{clear\_timer} = (\neg \text{rst\_n}) \lor \text{night\_mode} \lor (\text{current\_state} \neq \text{next\_state})$$

### 4.2. Khối Logic Trạng thái Kế tiếp (Next State Combinational Logic)

- Giải mã trạng thái kế tiếp `next_state` dựa trên `current_state`, `timer` và `night_mode`:
  - Nếu `night_mode == 1`: Khóa và ép `next_state = S_H1G_H2R`.
  - Nếu `night_mode == 0`:
    - Tại $S_0$: Chuyển sang $S_1$ khi `timer >= TIME_GREEN - 1` ($9$).
    - Tại $S_1$: Chuyển sang $S_2$ khi `timer >= TIME_YELLOW - 1` ($2$).
    - Tại $S_2$: Chuyển sang $S_3$ khi `timer >= TIME_GREEN - 1` ($9$).
    - Tại $S_3$: Chuyển sang $S_0$ khi `timer >= TIME_YELLOW - 1` ($2$).

### 4.3. Khối Giải mã Ngõ ra & Đè Ban đêm (Output Decoder Logic)

- **Ban ngày (`night_mode = 0`):**
  - $S_0$: `uo_out[2:0] = 3'b001` (H1 Green), `uo_out[5:3] = 3'b100` (H2 Red).
  - $S_1$: `uo_out[2:0] = 3'b010` (H1 Yellow), `uo_out[5:3] = 3'b100` (H2 Red).
  - $S_2$: `uo_out[2:0] = 3'b100` (H1 Red), `uo_out[5:3] = 3'b001` (H2 Green).
  - $S_3$: `uo_out[2:0] = 3'b100` (H1 Red), `uo_out[5:3] = 3'b010` (H2 Yellow).
- **Ban đêm (`night_mode = 1`):**
  - `uo_out[2:0] = {1'b0, night_blink, 1'b0}` (Hướng 1 nhấp nháy đèn Vàng).
  - `uo_out[5:3] = {1'b0, night_blink, 1'b0}` (Hướng 2 nhấp nháy đèn Vàng).

---

## PHẦN 5: CÁC VẤN ĐỀ & RỦI RO KỸ THUẬT

1. **Lỗi Trôi 1 Chu kỳ Clock (Timer Off-by-One):**
   - *Rủi ro:* So sánh đếm `timer == 10` kéo dài pha Green thành 11s.
   - *Biện pháp xử lý:* So sánh `timer >= TIME - 1` (đếm từ $0 \rightarrow 9$ đúng đủ 10s).
2. **Chuyển Chế độ Đêm Đột ngột (`night_mode` Edge Case):**
   - *Rủi ro:* Bật ban đêm ở giữa pha làm lệch bộ đếm khi quay lại chế độ ban ngày.
   - *Biện pháp xử lý:* Kích hoạt `clear_timer` và ép FSM về $S_0$ ngay khi `night_mode = 1`.
3. **Vi phạm Ràng buộc An toàn (Safety Invariant Violation):**
   - *Rủi ro:* Cả 2 hướng cùng Xanh do lỗi mạch giải mã logic.
   - *Biện pháp xử lý:* Đảm bảo kiểm tra điều kiện $\neg(\text{uo\_out}[0] \land \text{uo\_out}[3]) == 1$ trong mọi chu kỳ.
4. **Tránh Sinh Chốt (Latch Avoidance):**
   - *Biện pháp xử lý:* Khai báo giá trị mặc định cho tất cả tín hiệu ngõ ra ở đầu khối `always @(*)` và thêm nhánh `default` trong câu lệnh `case`.

---

## PHẦN 6: PHÂN TÍCH KỸ THUẬT

### 6.1. Phân tích Đường tới hạn (Critical Path Analysis)

- **Đường tới hạn dự kiến:** Đi từ `Timer Register (DFF)` $\rightarrow$ `Comparator (>=)` $\rightarrow$ `Next State Logic` $\rightarrow$ `State Register (DFF)`.
- **Đánh giá thời gian:** Độ sâu logic ngắn ($\approx 3 - 4$ cổng logic tổ hợp), đảm bảo thỏa mãn thời gian Setup/Hold dễ dàng ở mọi tần số hoạt động của khung thiết kế.

### 6.2. Phân tích Chênh lệch Diện tích và Ô chuẩn (Synthesis vs Floorplan Area)

- **Chênh lệch số lượng ô:** Báo cáo sau bước Tổng hợp (Synthesis) chỉ phản ánh số ô logic thuần túy. Sau bước Đặt ô & Đi dây (P&R/Layout), tổng số ô sẽ tăng thêm do quá trình chèn các ô đệm (Buffers), ô cây xung nhịp (Clock Tree Buffers), và các ô nguồn/tiếp địa (Tap/Endcap cells).

### 6.3. Phân tích & Kế hoạch Kiểm tra Tự động bằng Assertion

- Tích hợp trực tiếp các đoạn mã kiểm tra an toàn (Safety Assertion) vào Testbench để tự động hóa việc phát hiện lỗi ở cả hai công đoạn: Mô phỏng RTL (RTL Simulation) và Mô phỏng sau tổng hợp mức cổng (Gate-Level Simulation).