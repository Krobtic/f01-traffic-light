# F01 · Ca biên và ca góc (Corner Cases)

---

## 1. Tiêu chí phân loại ca riêng cho một FSM an toàn

Với F01, "độ phủ" không đo bằng số giá trị đầu vào (chỉ có 2 bit vào) mà đo bằng **độ phủ
đồ thị trạng thái** và **độ phủ tính chất an toàn**. Bốn trục:

| Trục | Câu hỏi ca phải trả lời |
|---|---|
| **T1 — Phủ đỉnh** | Đã vào đủ **4 trạng thái** chưa? |
| **T2 — Phủ cạnh** | Đã đi đủ **4 cạnh chuyển pha** chưa? Đã đi cạnh **tự lặp** (giữ pha khi chưa hết thời lượng) chưa? |
| **T3 — Phủ lớp phủ đêm** | Đã vào chế độ đêm, đã thấy **cả hai** nửa nhấp nháy (`night_phase = 0` và `= 1`), đã **thoát** chế độ đêm chưa? |
| **T4 — An toàn (INV-1)** | Tính chất "không bao giờ hai hướng cùng xanh" được kiểm ở **mọi** chu kỳ, hay chỉ vài chu kỳ? |

Trục T4 khác hẳn ba trục kia: nó không phải một *ca*, nó là một *assertion chạy liên tục*.

## 2. Ca bắt buộc của Charter mục 8 — và lý do kỹ thuật

| Ca | Thuộc trục | Vì sao được chọn | Đã có? |
|---|:-:|---|:-:|
| **C-1 · Một vòng đủ các pha** | T1+T2 | Đây là ca xương sống. Nếu chỉ chạy nửa vòng, một cạnh chuyển (ví dụ `EW_YELLOW → NS_GREEN`, cạnh **khép vòng**) sẽ không bao giờ được thử — và đó chính là cạnh hay viết sai nhất (viết `next = EW_GREEN` thay vì `NS_GREEN`). | ✅ `f01_tb.sv:22–27` |
| **C-2 · Chuyển sang đêm giữa chừng** | T3 | "Giữa chừng" là từ khoá. Nếu chỉ bật đêm ngay sau reset thì không phát hiện được lỗi *mất pha*: một hiện thực sai có thể ép `state ← NS_GREEN` khi vào đêm. Bật đêm khi FSM đang ở `EW_GREEN` mới phân biệt được. | ✅ `f01_tb.sv:29–34` |
| **C-3 · Không bao giờ hai hướng cùng xanh** | T4 | Yêu cầu **an toàn**. Testbench hiện thực bằng hàm `both_green()` và gọi sau **mỗi** cạnh clock trong cả bốn giai đoạn. | ✅ `f01_tb.sv:12–14`, kiểm ở `:24, :32, :40, :47` |

```systemverilog
// f01_tb.sv:12-14 — assertion an toàn, đúng bản chất yêu cầu
function automatic bit both_green(input logic [7:0] x);
    return (x[0] && x[3]);
endfunction
```

## 3. Độ phủ thật của testbench — truy vết từng chu kỳ

Testbench dùng `PHASE_TICKS(2)` ⇒ mỗi pha 2 chu kỳ, một vòng đủ = 8 chu kỳ. `clk` chu kỳ
10 đơn vị, cạnh lên tại `t = 5, 15, 25, …`; `$finish` tại `t = 256` (`simulation.log`).

| Giai đoạn | Cạnh clock | Trạng thái đi qua | Trục phủ được |
|---|---|---|---|
| Reset | 5, 15 | — → `NS_GREEN` | INV-2 |
| `repeat(12)` | 25…135 | `NS_G → NS_Y → EW_G → EW_Y → NS_G → NS_Y → EW_G` | **T1 đủ 4/4 đỉnh** · **T2 đủ 4/4 cạnh chuyển + cạnh tự lặp** |
| `night_mode=1`, `repeat(4)` | 145…175 | giữ `EW_GREEN`; `night_phase`: 0→0→1→1→0 | **T3: cả hai nửa nhấp nháy** |
| `ena=0`, `repeat(2)` | 185, 195 | đóng băng hoàn toàn | INV-3 |
| `ena=1, night_mode=0`, `repeat(6)` | 205…255 | **tiếp tục từ `EW_GREEN`** → `EW_Y → NS_G → NS_Y` | **INV-6 — thoát đêm không mất pha** |

> ✅ **Kết luận độ phủ:** testbench đạt **phủ đỉnh 100 %** và **phủ cạnh 100 %** của đồ
> thị 4 trạng thái. Đây là mức phủ tốt, hiếm gặp ở bài tập FSM.

## 4. Ca tự xây dựng đã có trong testbench

| Ca | Thuộc trục | Lý do kỹ thuật | Vị trí |
|---|:-:|---|---|
| **C-4 · Hạ `ena = 0` giữa chế độ đêm** | T3 + biên | **Ca biên thật.** Nó kiểm giao của hai cơ chế đóng băng khác nhau: `ena` đóng băng *tất cả* thanh ghi, còn `night_mode` chỉ đóng băng *`state`*. Một hiện thực sai có thể cho `night_phase` vẫn lật khi `ena = 0` (nếu quên bọc trong `else if (ena)`) — ca này bắt được. | `f01_tb.sv:37–41` |
| **C-5 · Trở lại hoạt động bình thường** | T3 + INV-6 | Kiểm **đường thoát** khỏi chế độ đêm. Rất nhiều hiện thực xử lý đúng chiều vào mà sai chiều ra (quên xoá `night_phase`, hoặc reset `state` về `NS_GREEN`). Ca này khẳng định FSM tiếp tục từ `EW_GREEN` — đúng pha bị giữ. | `f01_tb.sv:44–48` |

## 5. Ca còn thiếu — đề xuất bổ sung

| # | Ca đề xuất | Vì sao cần | Mức |
|---|---|---|:-:|
| M-1 | **Kiểm giá trị đầu ra đầy đủ**, không chỉ `both_green` | Hiện testbench **chỉ** kiểm tính chất an toàn. Không có một dòng nào khẳng định `uo_out == 8'h21` ở `NS_GREEN`. Một RTL bật **sai đèn** (ví dụ đổi chỗ vàng và đỏ) vẫn PASS toàn bộ testbench hiện tại. **Đây là lỗ hổng lớn nhất.** | **Rất cao** |
| M-2 | **Kiểm thời lượng pha**: đếm số chu kỳ mỗi pha, khẳng định đúng `PHASE_TICKS` | Testbench không kiểm thời lượng. Nếu `pc` đếm sai (ví dụ pha dài 3 chu kỳ thay vì 2), không ca nào bắt được. | Cao |
| M-3 | **Kiểm INV-5**: không bao giờ chuyển Xanh → Xanh của hướng kia mà không qua Vàng | Tính chất an toàn thứ hai, quan trọng ngang INV-1, nhưng **chưa** được kiểm. Cần assertion thời gian: `$rose(uo_out[3]) |-> $past(uo_out[4])`. | Cao |
| M-4 | **Reset giữa chừng**: reset khi đang ở `EW_YELLOW`, khẳng định về `NS_GREEN` | Reset hiện chỉ chạy **một lần** ở đầu, khi thanh ghi vốn là `X`. Chưa có bằng chứng reset kéo được FSM từ một trạng thái **hợp lệ** về trạng thái đầu. | Cao |
| M-5 | **Bật/tắt `night_mode` liên tục từng chu kỳ** | Ca stress cho lớp phủ. Kiểm rằng `nc` và `night_phase` không kẹt ở giá trị lạ. | Trung bình |
| M-6 | **Chạy với `PHASE_TICKS = 4`** — đúng cấu hình được tổng hợp | Hiện mô phỏng dùng `2`, tổng hợp dùng `4` (`functional_spec.md` W-3). **Cấu hình được tổng hợp chưa từng được mô phỏng.** | **Rất cao** |
| M-7 | **Mô phỏng module `_explicit`** — đúng module được tổng hợp | `f01_traffic_fsm_explicit` chưa từng được mô phỏng (`functional_spec.md` W-2) | **Rất cao** |
| M-8 | `PHASE_TICKS = 1` (biên dưới của tham số) | `localparam PW` có nhánh riêng cho `<= 1`; nhánh đó chưa được thử | Thấp |

## 6. Ca **KHÔNG** áp dụng cho đề này — và vì sao

| Ca thường gặp | Vì sao không áp dụng |
|---|---|
| Ca **trạng thái bất hợp lệ** | Mã trạng thái là 2 bit cho **đúng 4** trạng thái ⇒ **không tồn tại mã thừa**. Nhánh `default` trong RTL không tới được. Yosys xác nhận: `yosys.log:30` — *"Removed 1 dead cases"*. Ca này chỉ áp dụng nếu số trạng thái không phải luỹ thừa của 2 (ví dụ **F02** có 3 trạng thái trên 2 bit ⇒ có mã thừa `2'd3`). |
| Ca **tràn số / carry** | F01 không làm phép toán trên dữ liệu người dùng. Bộ đếm `pc` có tự quấn vòng, nhưng đó là hành vi mong muốn, không phải tràn. |
| Ca **clock domain crossing** | Chỉ có một clock. Netlist có đúng một net `clk` tới 6 chân `CLK`. |
| Ca **cảm biến xe / ưu tiên xe ưu tiên / đèn bộ hành** | Charter mục 3 ghi rõ **ngoài phạm vi**. Không có cổng vào tương ứng. |
| Ca **phối hợp nhiều ngã tư** | Charter mục 3. Không có giao diện đồng bộ liên ngã tư. |
| Ca **deadlock / livelock** | FSM là vòng đơn không nhánh rẽ; không có trạng thái hấp thụ. Chỉ `ena = 0` và `night_mode = 1` đóng băng, và cả hai đều **có đường thoát** (đã kiểm ở C-4, C-5). |

## 7. Ca phải **bổ sung** khi chuyển sang gate-level và post-layout

`05_VERIFICATION/test_matrix.csv` ghi L4-GATE và L5-SDF là `CHUA CHAY`.

| Ca mới | Vì sao chỉ xuất hiện ở gate-level |
|---|---|
| **INV-1 trên netlist thật** | Ở RTL, INV-1 đúng nhờ cấu trúc `case`. Sau tổng hợp, `uo_out[0]` và `uo_out[3]` là hai cell riêng (`_41_` và `_44_`, cùng loại `nor3_1`). Phải kiểm rằng **không cell nào** cho hai đầu ra đó cùng bằng 1. Phân tích cấu trúc đã làm ở `fsm.md` §6 — nhưng cần cả mô phỏng xác nhận. |
| **Glitch trên `uo_out` khi `night_mode` đổi** | Đường tới hạn là `night_mode → uo_out[1]` (tổ hợp thuần, 0,18 ns qua `a22o_1`). Khi `night_mode` lật, cả 6 bit đèn chuyển **không đồng thời**. Trong khoảnh khắc đó, về lý thuyết có thể xuất hiện tổ hợp bit **không hợp lệ**. Mô phỏng zero-delay **không** sinh glitch nên **không** phát hiện được. **Đây là ca quan trọng nhất của lớp L5 đối với một FSM an toàn.** |
| **Ca `X` lúc bật nguồn** | 6 flip-flop `dfxtp_1` khởi động là `X`. Phải khẳng định sau đúng 1 chu kỳ `rst_n = 0`, mọi `X` biến mất khỏi `uo_out`. |
| **Ca hold trên vòng hồi tiếp `nc`** | Đường hold ngắn nhất: `_51_/Q → _37_ → _39_ → _51_/D`, arrival 0,41 ns, hold slack 0,45 ns (`timing_report_min.txt`). Sau CTS, clock skew thật ăn trực tiếp vào biên này. |
| **Ca xung `ena` hẹp** | Zero-delay sim không kiểm setup/hold của `ena`. STA cho setup slack 8,43 ns (`ena → _47_`), nhưng chưa có RC thật. |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
