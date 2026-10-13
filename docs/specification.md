# SPECIFICATION (ĐẶC TẢ KỸ THUẬT) — ĐỀ TÀI F01

**Tên dự án:** Bộ điều khiển đèn giao thông hai chiều có đèn vàng (Traffic Light FSM Controller)  
**Mã đề:** F01 | **Khung vi mạch:** Tiny Tapeout (24 chân tiêu chuẩn)  
**Quy mô thiết kế:** ~180–260 cells, 1×1 tile

---

## 1. TỔNG QUAN VÀ BỐI CẢNH ỨNG DỤNG

* **Vị trí hệ thống:** Khối điều khiển trung tâm (FSM Controller) điều phối cụm đèn tín hiệu giao thông tại ngã tư hai chiều vuông góc (Hướng 1 và Hướng 2).
* **Tín hiệu điều khiển:** Tầng trên (cảm biến ánh sáng / đồng hồ hệ thống) gửi tín hiệu `uio_in[0]` để chuyển đổi giữa chế độ ban ngày và ban đêm.
* **Tín hiệu chấp hành:** Khối điều khiển sinh ra 6 ngõ ra điều khiển hai bộ đèn LED `{Red, Yellow, Green}` cho Hướng 1 và Hướng 2.
* **Yêu cầu cốt lõi:**
  1. Chạy tuần tự các pha đèn theo đúng thời lượng quy định.
  2. Tự động chuyển sang chế độ nhấp nháy đèn Vàng ban đêm.
  3. **Ràng buộc an toàn tuyệt đối (Safety Invariant):** Không bao giờ cho phép đèn Xanh ở hai hướng bật đồng thời.

---

## 2. BẢNG MÔ TẢ GIAO DIỆN TÍN HIỆU (INTERFACE SPECIFICATION)

Khối thiết kế phân bổ 9 / 24 chân tín hiệu trên ô Tiny Tapeout:

| Tên tín hiệu | Chiều (I/O) | Độ rộng | Mức tích cực | Giả định & Chức năng |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Cạnh lên (`posedge`) | Xung clock hệ thống ($T_{clk} = 1\text{ cycle} = 1\text{s}$). |
| `rst_n` | Input | 1 bit | Mức thấp (`0`) | Reset bất đồng bộ toàn hệ thống. |
| `uio_in[0]` | Input | 1 bit | Mức cao (`1`) | Tín hiệu chế độ đêm:<br>• `0`: Ban ngày (Chạy chu kỳ 4 pha).<br>• `1`: Ban đêm (Nhấp nháy đèn Vàng cả 2 hướng). |
| `ui_in[7:0]` | Input | 8 bit | — | Không sử dụng (đặt `8'h00`). |
| `uo_out[2:0]` | Output | 3 bit | Mức cao (`1`) | **Đèn Hướng 1:** `uo_out[2]` = Red, `uo_out[1]` = Yellow, `uo_out[0]` = Green. |
| `uo_out[5:3]` | Output | 3 bit | Mức cao (`1`) | **Đèn Hướng 2:** `uo_out[5]` = Red, `uo_out[4]` = Yellow, `uo_out[3]` = Green. |
| `uo_out[7:6]` | Output | 2 bit | Binary | **Mã trạng thái FSM:** `2'b00` ($S_0$), `2'b01` ($S_1$), `2'b10` ($S_2$), `2'b11` ($S_3$). |
| `uio_out[7:0]` | Output | 8 bit | — | Không sử dụng (đặt `8'h00`). |
| `uio_oe[7:0]` | Output | 8 bit | — | Cấu hình chiều chân `uio` (đặt `8'h00` = chọn Input). |

---

## 3. NGUYÊN LÝ HOẠT ĐỘNG & QUY TẮC AN TOÀN

### 3.1 Các trạng thái Ban ngày (`uio_in[0] == 0`)
FSM thiết kế theo mô hình **Moore Machine** với 4 trạng thái chu kỳ:

1. **Trạng thái $S_0$ (`S_H1G_H2R` — `2'b00`):**
   * Ngõ ra: Hướng 1 Xanh (`3'b001`), Hướng 2 Đỏ (`3'b100`).
   * Thời lượng: 10 chu kỳ clock ($T_{\text{Green}} = 10\text{s}$).
2. **Trạng thái $S_1$ (`S_H1Y_H2R` — `2'b01`):**
   * Ngõ ra: Hướng 1 Vàng (`3'b010`), Hướng 2 Đỏ (`3'b100`).
   * Thời lượng: 3 chu kỳ clock ($T_{\text{Yellow}} = 3\text{s}$).
3. **Trạng thái $S_2$ (`S_H1R_H2G` — `2'b10`):**
   * Ngõ ra: Hướng 1 Đỏ (`3'b100`), Hướng 2 Xanh (`3'b001`).
   * Thời lượng: 10 chu kỳ clock ($T_{\text{Green}} = 10\text{s}$).
4. **Trạng thái $S_3$ (`S_H1R_H2Y` — `2'b11`):**
   * Ngõ ra: Hướng 1 Đỏ (`3'b100`), Hướng 2 Vàng (`3'b010`).
   * Thời lượng: 3 chu kỳ clock ($T_{\text{Yellow}} = 3\text{s}$).

### 3.2 Chế độ Ban đêm (`uio_in[0] == 1`)
* Khi `uio_in[0] = 1`, FSM ghi đè ngõ ra: Đèn Vàng Hướng 1 (`uo_out[1]`) và Đèn Vàng Hướng 2 (`uo_out[4]`) nhấp nháy đồng bộ (1s bật, 1s tắt).
* Tất cả các đèn Xanh và Đỏ ở hai hướng lập tức tắt.
* Khi thoát chế độ đêm (`uio_in[0]` về `0`), FSM tự động khởi tạo về trạng thái ban đầu $S_0$.

### 3.3 Ràng buộc An toàn Tuyệt đối (Safety Invariant)
Điều kiện an toàn hệ thống luôn phải được đảm bảo bằng 1 trong mọi chu kỳ hoạt động:
$$\text{Safety\_OK} = \neg (\text{uo\_out}[0] \land \text{uo\_out}[3]) == 1$$

---

## 4. DỰ TOÁN TÀI NGUYÊN (RESOURCE ESTIMATION)

* **Thanh ghi đếm thời gian (Timer):** Đếm $0 \rightarrow 9$ $\Rightarrow$ 4-bit Counter (4 Flip-Flops).
* **Thanh ghi Trạng thái FSM:** 4 trạng thái $\Rightarrow$ $\lceil \log_2(4) \rceil = 2$ Flip-Flops (Mã hóa Binary) hoặc 4 Flip-Flops (Mã hóa One-Hot).
* **Thanh ghi Nhấp nháy Ban đêm:** 1 Flip-Flop.
* **Ước tính tổng cộng:** $7 \sim 9$ Flip-Flops, quy mô ~180–260 Standard Cells.

---

## 5. KỊCH BẢN KIỂM THỬ (TEST PLAN)

1. **TC1 (Chạy chu kỳ Ban ngày):** Đặt `uio_in[0] = 0`. Cho chạy đủ 1 vòng 26 chu kỳ ($10\text{s} + 3\text{s} + 10\text{s} + 3\text{s}$), kiểm tra ngõ ra và thời lượng từng pha.
2. **TC2 (Chuyển chế độ đêm giữa chừng):** Kích hoạt `uio_in[0] = 1` khi FSM đang chạy ở pha $S_2$. Kiểm tra mạch lập tức chuyển sang nhấp nháy vàng.
3. **TC3 (Thoát chế độ đêm):** Trả `uio_in[0] = 0`. Kiểm tra mạch quay về $S_0$ đúng quy chuẩn.
4. **TC4 (Reset bất đồng bộ):** Bật `rst_n = 0` ngẫu nhiên giữa chừng. Kiểm tra mạch lập tức xóa `timer` và về $S_0$.
5. **TC5 (Kiểm tra An toàn tự động):** Tích hợp hàm `assert` trong Testbench để phát hiện lỗi nếu `uo_out[0]` và `uo_out[3]` đồng thời bằng `1`.