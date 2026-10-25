# F01 · Đặc tả chức năng (Functional Specification)

---

## 0. Cảnh báo đối chiếu Charter — đọc trước

| # | Hạng mục | Kết luận |
|---|---|---|
| W-1 | **Cổng `ena` không có trong Charter mục 4** | ⚠️ **CHƯA THOẢ.** Charter mục 4 chỉ định đúng một tín hiệu vào: `uio_in[0]` = chế độ đêm. RTL khai báo thêm `ena` (`f01_traffic_fsm.sv:7`), một chân vào **không** nằm trong danh mục đề. Ngân sách chân vẫn đủ (2 bit vào + 8 bit ra = 10 / 24), nhưng bảng ánh xạ chân của Charter **phải được cập nhật** (ví dụ `uio_in[1] = ena`), hoặc tầng ngoài phải buộc `ena = 1'b1` cố định. **Không tự sửa RTL** — ghi nhận để thầy quyết. |
| W-2 | **Module được mô phỏng ≠ module được tổng hợp** | ⚠️ **CHƯA THOẢ.** Testbench khởi tạo `f01_traffic_fsm` (`f01_tb.sv:5`); Yosys lấy top là `f01_traffic_fsm_explicit` (`synth_stat.txt`, `synth.ys`). Đây là **hai module khác nhau**, và `yosys.log:21` ghi rõ *"Removing unused module `\f01_traffic_fsm`"*. Mọi kết quả mô phỏng vì vậy **không** trực tiếp chứng nhận netlist. Hai module có nội dung tương đương về hành vi (đối chiếu từng dòng ở §7), nhưng **sự tương đương đó chưa được chứng minh bằng công cụ**. |
| W-3 | **Tham số mô phỏng ≠ tham số tổng hợp** | ⚠️ **CHƯA THOẢ.** Testbench dùng `PHASE_TICKS(2)`; tổng hợp dùng giá trị mặc định `PHASE_TICKS = 4`. Hệ quả: bộ đếm `pc` rộng 1 bit khi mô phỏng nhưng 2 bit khi tổng hợp ⇒ **số flip-flop khác nhau** (5 khi mô phỏng, 6 khi tổng hợp). Mọi kết luận về số ô nhớ phải nói rõ đang nói về cấu hình nào. |
| W-4 | Charter mục 10 dự đoán *"pha ≈ 3 ô nhớ + bộ đếm thời lượng ≈ 8 ô nhớ"* | ⚠️ Không khớp: đo được **6** ô nhớ, trong đó bộ đếm pha chỉ **2** bit. Nguyên nhân: `PHASE_TICKS = 4` là giá trị *tick*, không phải *giây*. Việc chia tần từ giây xuống tick nằm **ngoài** khối (xem `system_diagram.md` §1). Không phải lỗi, nhưng phải nói rõ khi báo cáo. |

Ngoài bốn điểm trên, ánh xạ `uo_out` khớp đúng Charter mục 4.

---

## 1. Khối này làm gì — phát biểu một câu

F01 là **máy trạng thái 4 pha** điều khiển hai hướng đèn của một ngã tư, mỗi pha kéo dài
`PHASE_TICKS` chu kỳ clock, cộng thêm một **lớp phủ chế độ đêm** biến cả hai hướng thành
đèn vàng nhấp nháy mà **không** thêm trạng thái nào.

## 2. Ánh xạ tín hiệu ra (đọc từ RTL, khớp Charter mục 4)

| Bit | Ý nghĩa | Nguồn |
|---|---|---|
| `uo_out[0]` | Hướng 1 — **Xanh** (G) | `f01_traffic_fsm.sv:91` `uo_out[2:0]=3'b001` |
| `uo_out[1]` | Hướng 1 — **Vàng** (Y) | `:95` `3'b010` |
| `uo_out[2]` | Hướng 1 — **Đỏ** (R) | `:99` `3'b100` |
| `uo_out[3]` | Hướng 2 — **Xanh** (G) | `:100` |
| `uo_out[4]` | Hướng 2 — **Vàng** (Y) | `:104` |
| `uo_out[5]` | Hướng 2 — **Đỏ** (R) | `:92` |
| `uo_out[7:6]` | **Mã trạng thái** (2 bit) | `:114` `uo_out[7:6] = state;` |

Quy ước bit trong nhóm 3 bit: `{R, Y, G}` từ MSB xuống LSB, nên **bit thấp nhất là xanh**.
Testbench dùng đúng quy ước này: `both_green = x[0] && x[3]` (`f01_tb.sv:13`).

## 3. Bảng hành vi — đầu ra theo trạng thái

| Trạng thái | Mã (`uo_out[7:6]`) | Hướng 1 `[2:0]` | Hướng 2 `[5:3]` | `uo_out` đầy đủ |
|---|:-:|---|---|---|
| `NS_GREEN` | `00` | `001` = Xanh | `100` = Đỏ | `0b00_100_001` = `0x21` |
| `NS_YELLOW` | `01` | `010` = Vàng | `100` = Đỏ | `0b01_100_010` = `0x62` |
| `EW_GREEN` | `10` | `100` = Đỏ | `001` = Xanh | `0b10_001_100` = `0x8C` |
| `EW_YELLOW` | `11` | `100` = Đỏ | `010` = Vàng | `0b11_010_100` = `0xD4` |

Chế độ đêm (`night_mode = 1`) — **ghi đè** bảng trên, nhưng `uo_out[7:6]` **vẫn** hiện
trạng thái đang bị giữ:

| `night_phase` | Hướng 1 | Hướng 2 | Ghi chú |
|:-:|---|---|---|
| `1` | `010` = Vàng | `010` = Vàng | Nửa chu kỳ **sáng** |
| `0` | `000` = tắt hết | `000` = tắt hết | Nửa chu kỳ **tối** |

## 4. Hàm chuyển trạng thái

```
  rst_n = 0               → state ← NS_GREEN, pc ← 0, nc ← 0, night_phase ← 0  (ĐỒNG BỘ)
  ena   = 0               → giữ nguyên TẤT CẢ (state, pc, nc, night_phase)
  night_mode = 1          → state GIỮ NGUYÊN; pc ← 0; nc đếm; night_phase lật khi nc = NIGHT_TICKS-1
  night_mode = 0, pc<P-1  → state giữ; pc ← pc+1; nc ← 0; night_phase ← 0
  night_mode = 0, pc=P-1  → state ← pha kế tiếp; pc ← 0; nc ← 0; night_phase ← 0
```

Vòng pha: `NS_GREEN → NS_YELLOW → EW_GREEN → EW_YELLOW → NS_GREEN` (chi tiết đầy đủ ở
`03_ARCHITECTURE/fsm.md`).

Bằng chứng (`f01_traffic_fsm.sv:29–45`):

```systemverilog
if (night_mode) begin
    next_state = state;          // chế độ đêm GIỮ pha, không phải trạng thái thứ năm
end else begin
    case (state)
        NS_GREEN: if (phase_cnt == PHASE_TICKS-1) next_state = NS_YELLOW;
        ...
```

## 5. Ràng buộc cấu trúc bắt buộc

| Ràng buộc từ tên đề / Charter | Phải thấy ở đâu | Đã thoả? |
|---|---|:-:|
| Phải là **FSM thật** (nhóm F) | `typedef enum` + `case (state)` + thanh ghi trạng thái | ✅ `f01_traffic_fsm.sv:14–21`, `:33` |
| Phải có **đèn vàng** (trong tên đề) | Hai trạng thái vàng riêng, không gộp | ✅ `NS_YELLOW`, `EW_YELLOW` |
| Phải **hai chiều** | Hai nhóm 3 bit độc lập | ✅ `uo_out[2:0]`, `uo_out[5:3]` |
| Ban đêm **nhấp nháy vàng** | Lớp phủ có bộ đếm và bit lật | ✅ `night_phase`, `night_cnt` |
| Charter mục 3: **không** cảm biến xe, **không** đèn bộ hành, **không** phối hợp nhiều ngã tư | RTL không có cổng nào cho các chức năng đó | ✅ chỉ có `night_mode`, `ena` |

## 6. Tính chất bất biến (invariants)

| ID | Phát biểu | Mức | Kiểm bằng |
|---|---|---|---|
| **INV-1** 🔴 | **AN TOÀN: không bao giờ `uo_out[0] = 1` và `uo_out[3] = 1` cùng lúc** (hai hướng cùng xanh) | **An toàn, không phải chức năng** | Đã kiểm ở mọi chu kỳ mô phỏng (`f01_tb.sv:24,32,40,47`) **và** chứng minh cấu trúc từ netlist — xem `fsm.md` §6 |
| **INV-2** | Sau cạnh clock có `rst_n = 0`: `state = NS_GREEN`, `pc = 0`, `nc = 0`, `night_phase = 0` | Chức năng | `f01_traffic_fsm.sv:49–53` |
| **INV-3** | Khi `ena = 0`, **không** thanh ghi nào đổi giá trị | Chức năng | `:54` `else if (ena)`; TB kiểm ở `:37–41` |
| **INV-4** | Mỗi hướng luôn bật **đúng một** trong ba đèn khi `night_mode = 0`: `uo_out[0]+uo_out[1]+uo_out[2] = 1` | Chức năng | Bảng §3; chưa có assertion riêng |
| **INV-5** | Không bao giờ chuyển trực tiếp Xanh → Xanh của hướng kia; luôn phải qua Vàng | An toàn | Vòng pha ở §4: `NS_GREEN → NS_YELLOW → EW_GREEN` |
| **INV-6** | `night_mode = 1` **không** làm mất pha đang chạy: khi trở lại `night_mode = 0`, FSM tiếp tục từ đúng pha cũ | Chức năng | `:31` `next_state = state;` |
| **INV-7** | Trong chế độ đêm, **không** đèn xanh nào bật: `uo_out[0] = uo_out[3] = 0` | An toàn | `:84–87` chỉ gán `3'b010` hoặc để `'0` |
| **INV-8** | `uo_out[7:6]` luôn bằng giá trị thanh ghi `state`, kể cả trong chế độ đêm | Quan sát được | `:114`; netlist: `state[0]` **chính là** net `uo_out[6]` |

> 🔴 **INV-1 là yêu cầu AN TOÀN, không phải yêu cầu chức năng.** Khác biệt: một lỗi chức
> năng làm đèn sai nhịp (phiền); một lỗi an toàn làm hai hướng cùng xanh (tai nạn). Vì
> vậy INV-1 phải được chứng minh bằng **cấu trúc**, không chỉ bằng mô phỏng — mô phỏng chỉ
> phủ được các ca đã chạy. Chứng minh cấu trúc ở `fsm.md` §6.

## 7. Đối chiếu hai module RTL (W-2)

| Nội dung | `f01_traffic_fsm` (mô phỏng) | `f01_traffic_fsm_explicit` (tổng hợp) | Tương đương? |
|---|---|---|:-:|
| Tên trạng thái | `NS_GREEN`…`EW_YELLOW` | `S_NS_G`…`S_EW_Y` | ✅ cùng mã `2'd0…2'd3` |
| Hàm chuyển trạng thái | `:26–46` | `:20–31` | ✅ cùng logic |
| Cập nhật `pc` | `:68–73` ba nhánh `if/else if/else` | `:46` một biểu thức ba ngôi | ✅ cùng kết quả |
| Lớp phủ đêm | `:81–87` | `:53–57` | ✅ |
| Bảng giải mã đầu ra | `:89–110` | `:59–65` | ✅ |
| Nhánh `default` | `next_state = NS_GREEN` | `next=S_NS_G` | ✅ |

**Kết luận:** hai module tương đương **theo đọc mã**. Điều này **chưa** được xác nhận bằng
công cụ (chưa chạy kiểm tương đương hình thức, chưa mô phỏng bản `_explicit`). Đây là một
lỗ hổng chuỗi bằng chứng thật, ghi nhận ở `07_TRACEABILITY/limitations.md`.

## 8. Độ trễ đầu vào → đầu ra (đếm theo chu kỳ)

| Từ | Tới | Độ trễ |
|---|---|---|
| `rst_n = 0` | `state = NS_GREEN` | **1 chu kỳ** (reset đồng bộ) |
| `night_mode` đổi | `uo_out[5:0]` đổi (đèn) | **0 chu kỳ** — tổ hợp thuần ⇒ **hành vi Mealy** |
| `night_mode` đổi | `state` ngừng tiến | 1 chu kỳ (ảnh hưởng qua `next_state`) |
| `ena` đổi | toàn bộ thanh ghi đóng băng | 1 chu kỳ |
| Bắt đầu một pha | Chuyển sang pha kế | **`PHASE_TICKS` chu kỳ** |
| Hết một vòng đủ 4 pha | | **`4 × PHASE_TICKS` chu kỳ** (= 16 khi tổng hợp, = 8 khi mô phỏng) |
| `night_phase` lật | | mỗi **`NIGHT_TICKS`** chu kỳ (= 2) |

## 9. Điều kiện biên và hành vi không xác định

| Tình huống | Hành vi | Ghi chú |
|---|---|---|
| `rst_n = 0` và `ena = 0` cùng lúc | **Reset thắng** — `if (!rst_n)` đứng trước `else if (ena)` | Đã định nghĩa rõ |
| `night_mode` bật **giữa** một pha | Pha bị **đóng băng**, `pc` về 0. Khi tắt đêm, pha đó chạy lại **từ đầu** đủ `PHASE_TICKS` | Hệ quả thiết kế có chủ ý; TB kiểm ở `:29–34` |
| `night_mode` bật khi đang ở `NS_GREEN` | `uo_out[7:6] = 00` vẫn hiện `NS_GREEN` trong khi đèn nhấp nháy vàng | **Có thể gây nhầm** khi đọc mã trạng thái ngoài hiện trường — xem `implementation-notes_F01.md` §9 |
| Mã trạng thái bất hợp lệ | **Không tồn tại** — 2 bit mã hoá đủ 4 trạng thái, không còn mã thừa | Nhánh `default` không tới được; xem `fsm.md` §7 |
| Trước cạnh clock đầu tiên | Tất cả thanh ghi là `X`, `uo_out` là `X` | Tầng ngoài **bắt buộc** phát `rst_n = 0` ≥ 1 chu kỳ |
| `night_mode = X` | `if (night_mode)` rẽ nhánh `else` khi mô phỏng; netlist cho `X` lan ra `uo_out` | Không nhất quán RTL ↔ gate |
| `PHASE_TICKS = 1` | `PW = 1`, `PHASE_TICKS-1 = 0`, điều kiện `pc == 0` luôn đúng ⇒ mỗi pha 1 chu kỳ | Hợp lệ, `localparam` có xử lý trường hợp `<= 1` |

## 10. Những gì đặc tả này **không** quy định

- Không quy định thời lượng pha tính bằng **giây**. `PHASE_TICKS` đếm **chu kỳ clock**;
  việc chia tần từ clock hệ thống xuống "tick giây" thuộc tầng ngoài.
- Không quy định hành vi khi mất điện giữa chừng.
- Không quy định đèn bộ hành, cảm biến xe, ưu tiên xe cứu hoả — Charter mục 3 loại trừ.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
