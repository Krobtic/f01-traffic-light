# F01 · Đánh đổi kiến trúc (Trade-off Analysis)

---

## 1. Câu hỏi trung tâm của đề

> Charter mục 10 — **Chỗ hay tắc:** *"Vẽ sơ đồ trạng thái SAU khi viết code — sơ đồ khi đó
> chỉ là bản vẽ lại, không phải thiết kế."*

Đây là một chỗ tắc về **quy trình**, không về kỹ thuật. Tài liệu này lật ngược lại: mọi
quyết định kiến trúc dưới đây **đều có thể quyết ở mức sơ đồ trạng thái, trước khi viết
một dòng RTL**, và mỗi quyết định đều để lại dấu vết đo được trong netlist.

## 2. Số liệu nền — dùng cho mọi so sánh dưới đây

Nguồn: `06_GDSII/synthesis/synth_stat.txt`, diện tích cell từ liberty
`sky130_fd_sc_hd__tt_025C_1v80`.

| Chỉ số | Giá trị đo được |
|---|---:|
| Tổng số cell | **32** |
| Flip-flop (`dfxtp_1`) | **6** |
| Diện tích tổng | **279,0176 µm²** |
| ├ tuần tự (6 × 20,0192) | 120,1152 µm² — **43,05 %** |
| └ tổ hợp (26 cell) | 158,9024 µm² — **56,95 %** |
| Công suất | 2,76e-05 W (tuần tự 92,8 %, tổ hợp 7,2 %) |
| Slack xấu nhất | 7,82 ns (chu kỳ giả định 10 ns) |
| Ước lượng Charter | ~180–260 cell · 1×1 tile |

> Kết quả thật (**32 cell**) **nhỏ hơn 5–8 lần** ước lượng Charter. Nguyên nhân chính:
> `PHASE_TICKS = 4` ⇒ bộ đếm pha chỉ 2 bit. Charter dự đoán *"bộ đếm thời lượng ≈ 8 ô
> nhớ"* — tức một bộ đếm 8 bit đếm tới ~256 tick. Thiết kế này đẩy việc chia tần **ra
> ngoài khối** (`system_diagram.md` §1), nên phần đó không nằm trong 32 cell. **Đây không
> phải "làm tốt hơn Charter" — đây là dịch chuyển ranh giới khối.** Phải nói rõ khi báo
> cáo.

## 3. Quyết định 1 — Chế độ đêm: lớp phủ hay trạng thái? **(quyết định quan trọng nhất)**

| Tiêu chí | **A. Lớp phủ đầu ra (ĐÃ CHỌN)** | **B. Thêm 2 trạng thái đêm** | **C. Thêm 1 trạng thái đêm + bit nháy** |
|---|---|---|---|
| Số trạng thái | 4 | 6 | 5 |
| Bit mã hoá trạng thái | **2** | 3 | 3 |
| FF cho trạng thái | **2** (đo được) | 3 | 3 |
| FF khác (`pc`, `nc`, `night_phase`) | 4 | ≥ 4 (vẫn cần `nc`) | ≥ 4 |
| **Tổng FF** | **6** (đo được) | ≥ 7 | ≥ 7 |
| Mã trạng thái thừa | **0** | **2 / 8** — phải xử lý | **3 / 8** — phải xử lý |
| Nhớ pha cũ khi vào đêm | **miễn phí** — `state` tự giữ | phải thêm thanh ghi lưu pha ⇒ **+2 FF nữa** | như B |
| Loại máy | **Mealy** | Moore thuần | Moore thuần |
| Đường tổ hợp in→out | **có** (rủi ro glitch) | không | không |
| Số cạnh trên sơ đồ | 8 | ≥ 16 (mỗi pha cần cạnh đi/về đêm) | ≥ 12 |

**Đánh giá bằng số thật:** phương án A đo được **6 FF, 120,1152 µm² tuần tự**. Phương án B
cần tối thiểu 9 FF (3 trạng thái + 2 lưu pha + 4 còn lại) ⇒ ≥ 180,1728 µm² tuần tự, tăng
**≥ 50 %** phần tuần tự, chưa kể logic next-state phức tạp hơn nhiều (đồ thị 16 cạnh so
với 8).

**Cái giá của A, nói thẳng:** máy trở thành **Mealy**. `night_mode` đi thẳng ra đèn qua
đúng một cell (`a22o_1`, 0,18 ns — `sta/summary.txt`). Một glitch trên `night_mode`
**không được clock lọc**. Với hệ thống an toàn, phải bù bằng nghĩa vụ tầng ngoài: đồng bộ
`night_mode` bằng 2 flip-flop trước khi đưa vào F01 (`control.md` N-3). Chi phí bù: 2 FF
ở tầng ngoài — vẫn rẻ hơn phương án B.

## 4. Quyết định 2 — Mã hoá trạng thái: nhị phân hay one-hot?

| Tiêu chí | **Nhị phân tuần tự (ĐÃ DÙNG)** | One-hot | Gray |
|---|---|---|---|
| FF cho 4 trạng thái | **2** (đo được) | 4 | 2 |
| Diện tích FF trạng thái | **40,0384 µm²** | 80,0768 µm² (+100 %) | 40,0384 µm² |
| Mã thừa cần xử lý | **0** | 12 / 16 | 0 |
| Logic next-state | phức hợp vừa | đơn giản nhất | phức hợp hơn nhị phân |
| Logic giải mã đầu ra | **6 cell** (đo được) | ~6 cell, đơn giản hơn từng cell | phức tạp hơn |
| Đường tới hạn qua next-state | 3 cell, arrival 1,49 ns | ngắn hơn | dài hơn |
| Xuất mã ra chân `uo_out[7:6]` | **miễn phí** | cần bộ mã hoá 4→2 ⇒ **+cell** | miễn phí |
| Nhiễu chuyển tiếp (2 bit đổi cùng lúc) | có (`01 → 10`) | không | **không** — ưu điểm chính |

**Vì sao nhị phân thắng ở đây:** (a) Charter mục 4 **bắt buộc** xuất mã trạng thái ra
`uo_out[7:6]`; với nhị phân việc đó là 0 cell, với one-hot phải thêm bộ mã hoá. (b) Đường
tới hạn **vốn đã chỉ 1 cell** và nằm ở đường ra, nên ưu điểm "next-state ngắn" của one-hot
không mang lại gì. (c) 4 trạng thái là quá nhỏ để one-hot có lợi.

**Vì sao Gray đáng cân nhắc nhưng không bắt buộc:** Gray tránh được việc hai bit trạng
thái đổi cùng lúc ở cạnh `NS_YELLOW (01) → EW_GREEN (10)`. Trong F01, hai bit đó **đi
thẳng ra chân** `uo_out[7:6]`. Nếu tầng ngoài lấy mẫu bất đồng bộ đúng lúc đó, nó có thể
đọc được `00` hoặc `11` thoáng qua. **Đây là một rủi ro thật, chưa được xử lý.** Chi phí
sửa: đổi hằng số enum, 0 flip-flop thêm. Đây là đề xuất cải tiến rẻ nhất trong cả tài liệu
này — nhưng **chưa được áp dụng** và cần thầy duyệt.

## 5. Quyết định 3 — Đếm thời lượng: bộ đếm hay chuỗi dịch?

| Tiêu chí | **Bộ đếm nhị phân (ĐÃ DÙNG)** | Chuỗi dịch vòng (ring counter) |
|---|---|---|
| FF cho `PHASE_TICKS = 4` | **2** (đo được: `pc[0]`, `pc[1]`) | 4 |
| Logic so sánh | cần bộ so sánh `== P-1` | không cần — chỉ đọc 1 bit |
| Mở rộng lên `PHASE_TICKS = 256` | **8 FF** | 256 FF — **không khả thi** |
| Đường tới hạn | dài hơn (qua bộ so sánh) | ngắn nhất |
| Mã thừa | 0 khi `P` là luỹ thừa của 2 | nhiều (chỉ 1 bit được phép bằng 1) |

Bộ đếm nhị phân là lựa chọn gần như bắt buộc vì khả năng mở rộng. Với đèn giao thông thật,
`PHASE_TICKS` sẽ ở hàng chục tới hàng trăm — chuỗi dịch sẽ vỡ ngay.

## 6. Quyết định 4 — Ranh giới khối: có nên đưa bộ chia tần vào trong?

| | **Để ngoài (ĐÃ CHỌN)** | Đưa vào trong |
|---|---|---|
| FF của khối | **6** (đo được) | 6 + ~26 bit chia tần |
| Diện tích | **279,0176 µm²** | ước tính tăng ~5–6 lần |
| Kiểm thử | mô phỏng 26 chu kỳ là đủ | phải mô phỏng hàng chục triệu chu kỳ để thấy một pha |
| Tái dùng khối | dùng được với mọi tần số clock | gắn chặt với một tần số |
| Đúng Charter? | ✅ Charter mục 1 nói "khối điều khiển đèn", không nói "khối chia tần" | — |

**Đây là quyết định làm cho đề dạy được.** Nếu đưa chia tần vào trong, testbench sẽ không
chạy nổi một vòng pha trong thời gian hợp lý, và bài học về FSM sẽ chìm trong một bộ đếm
khổng lồ. Cái giá: số cell đo được (32) **không so sánh trực tiếp** được với ước lượng
Charter (180–260) — phải giải thích, như đã làm ở §2.

## 7. Ràng buộc phạm vi — những gì **chỉ được so trên giấy**

Charter mục 3 ghi **ngoài phạm vi**: *"Cảm biến xe, ưu tiên xe ưu tiên, đèn bộ hành, phối
hợp nhiều ngã tư."*

| Kiến trúc mở rộng | Vì sao hấp dẫn | Vì sao **không được** hiện thực |
|---|---|---|
| FSM có cảm biến xe (actuated control) | Không phí thời gian cho hướng không có xe | Charter mục 3. Cần thêm ≥ 2 cổng vào + logic ưu tiên; đồ thị trạng thái phức tạp gấp nhiều lần |
| Ưu tiên xe cứu hoả (preemption) | Yêu cầu thật của hệ thống thật | Charter mục 3. Cần thêm trạng thái `ALL_RED` và đường chuyển sớm — sẽ **phá** tính dư thừa của nhánh `pc` đã phân tích ở `datapath.md` §3 |
| Đèn bộ hành | Yêu cầu thật | Charter mục 3. Cần thêm ≥ 2 trạng thái và ≥ 2 bit ra — hết `uo_out` |
| Phối hợp nhiều ngã tư (green wave) | Tối ưu dòng xe | Charter mục 3. Cần giao diện đồng bộ liên khối |
| Trạng thái `ALL_RED` chèn giữa các pha | **Thực hành an toàn chuẩn** ở ngã tư thật (dọn ngã tư trước khi đổi hướng) | Không có trong đề. Nếu thêm: +2 trạng thái ⇒ 3 bit mã hoá ⇒ +1 FF, và xuất hiện mã thừa |

> 🎓 Mục cuối bảng đáng bàn khi bảo vệ: **đèn giao thông thật hầu như luôn có pha
> all-red.** F01 chuyển thẳng từ `NS_YELLOW` sang `EW_GREEN`. Về mặt dạy học, đây là chỗ
> tốt để hỏi *"thiết kế này an toàn theo nghĩa nào, và không an toàn theo nghĩa nào?"* —
> INV-1 (không hai xanh) thoả, nhưng "dọn ngã tư" thì không có.

## 8. Những đánh đổi **KHÔNG được phép** trong đề này

| Đánh đổi | Vì sao cấm | Bằng chứng ràng buộc |
|---|---|---|
| Gộp `NS_YELLOW` và `EW_YELLOW` thành một trạng thái vàng chung | Mất khả năng biết vàng của hướng nào ⇒ phải thêm bit nhớ hướng ⇒ không tiết kiệm được gì | Tên đề: "có đèn vàng" cho **hai chiều** |
| Bỏ `uo_out[7:6]` để tiết kiệm chân | Charter mục 4 **bắt buộc** xuất mã trạng thái | Charter mục 4 |
| Bỏ bộ đếm, đổi pha mỗi chu kỳ clock | Đèn nhấp nháy ở tần số clock — vô nghĩa vật lý | Charter mục 1 (đèn giao thông thật) |
| Hiện thực đêm bằng cách ép `state = NS_GREEN` | Vi phạm INV-6 (mất pha đang chạy) | `functional_spec.md` INV-6; TB ca C-5 sẽ bắt |
| Sửa netlist bằng tay để bớt cell | Cấm chung mọi đề | Charter mục 3 |
| Bỏ `ena` để khớp Charter mục 4 | Mất khả năng đóng băng khi bảo trì — nhưng **đây là lựa chọn hợp lệ nếu thầy duyệt** | Xem `functional_spec.md` §0 W-1 |
| Bỏ nhánh `default` vì "nó chết rồi" | `always_comb` mất `full_case` ⇒ Yosys có thể suy diễn latch | `yosys.log:70–71` *"No latch inferred"* — nhờ có `default` |

## 9. Bảng tổng kết: quyết định → dấu vết đo được

Đây là bảng trả lời trực tiếp Charter mục 10 (*"sơ đồ phải là thiết kế, không phải bản vẽ
lại"*): mỗi quyết định ở mức sơ đồ để lại một con số kiểm chứng được.

| Quyết định ở mức sơ đồ trạng thái | Dấu vết đo được trong netlist |
|---|---|
| 4 trạng thái (không phải 6) | **2** × `dfxtp_1` cho `state` (`_46_`, `_47_`) |
| Mã hoá nhị phân tuần tự | Yosys **không** đổi mã (`yosys.log:187–205`, `FSM_DETECT` rỗng) |
| Đêm là lớp phủ, không phải trạng thái | Đường tổ hợp `night_mode → uo_out[1]`, slack 7,82 ns — dấu hiệu **Mealy** |
| Xuất mã trạng thái ra chân | Thanh ghi hợp nhất với cổng ra: `.Q(uo_out[6])`, `.Q(uo_out[7])` — **0 cell phụ** |
| `PHASE_TICKS = 4` | `pc` chỉ **2** FF; tổng 32 cell thay vì 180–260 như Charter ước |
| An toàn bằng cấu trúc giải mã | `_41_`/`_44_` chia nhau `uo_out[7]` với hai cực tính đối nhau ⇒ INV-1 đúng **vét cạn** |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
