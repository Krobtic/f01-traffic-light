# F01 · Sơ đồ hệ thống (System Diagram)

---

## 1. Bối cảnh ứng dụng thật

Charter mục 1: *"Khối điều khiển đèn tín hiệu cho một ngã tư hai chiều ở khu dân cư, ban
đêm chuyển sang nhấp nháy vàng."*

Điểm quan trọng phải hiểu ngay: **F01 không đếm giây.** Nó đếm **tick**. Một tick là bao
nhiêu giây do bộ chia tần **bên ngoài** quyết định. Đây chính là lý do bộ đếm pha chỉ rộng
2 bit thay vì 8 bit như Charter mục 10 dự đoán.

```
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                        TỦ ĐIỀU KHIỂN ĐÈN TÍN HIỆU — tầng ngoài                   │
 │                                                                                  │
 │  ┌──────────┐   clk hệ thống    ┌────────────────┐   clk (≈1 tick)               │
 │  │ Dao động │ ────────────────▶ │  BỘ CHIA TẦN   │ ────────────┐                 │
 │  │ thạch anh│                   │ (KHÔNG thuộc   │             │                 │
 │  └──────────┘                   │  F01)          │             │                 │
 │                                 └────────────────┘             │                 │
 │  ┌──────────┐                                                  │                 │
 │  │ Cảm biến │   night_mode   ╔═════════════════════════════════▼══════════════╗  │
 │  │ ánh sáng │ ─────────────▶ ║                                                ║  │
 │  │ / lịch   │                ║            ███  F01  ███                       ║  │
 │  └──────────┘                ║      FSM 4 pha + lớp phủ đèn đêm               ║  │
 │  ┌──────────┐    ena         ║                                                ║  │
 │  │ Giám sát │ ─────────────▶ ║  ┌────────┐ ┌────┐ ┌────┐ ┌───────────┐        ║  │
 │  │ / bảo trì│                ║  │ state  │ │ pc │ │ nc │ │night_phase│        ║  │
 │  └──────────┘    rst_n       ║  │ 2 bit  │ │2bit│ │1bit│ │  1 bit    │        ║  │
 │  ┌──────────┐ ─────────────▶ ║  └────────┘ └────┘ └────┘ └───────────┘        ║  │
 │  │ Chuỗi    │                ║                                                ║  │
 │  │ reset    │                ╚════════════════════╤═══════════════════════════╝  │
 │  └──────────┘                        uo_out[7:0]  │                              │
 │                                                   │                              │
 │       ┌───────────────────────────────────────────┴───────────────┐              │
 │       │ [2:0] hướng 1    [5:3] hướng 2    [7:6] mã trạng thái      │             │
 │       ▼                  ▼                ▼                                      │
 │  ┌─────────┐        ┌─────────┐      ┌──────────┐                                │
 │  │ MẠCH LÁI│        │ MẠCH LÁI│      │ Đèn chẩn │  ← KHÔNG thuộc F01             │
 │  │ CÔNG    │        │ CÔNG    │      │ đoán /   │     (mức công suất, cách ly)   │
 │  │ SUẤT    │        │ SUẤT    │      │ ghi log  │                                │
 │  └────┬────┘        └────┬────┘      └──────────┘                                │
 └───────┼──────────────────┼───────────────────────────────────────────────────────┘
         ▼                  ▼
    ╔═════════╗        ╔═════════╗
    ║  🔴🟡🟢 ║        ║  🔴🟡🟢 ║      Ngã tư thật: hai hướng vuông góc
    ║ HƯỚNG 1 ║        ║ HƯỚNG 2 ║
    ╚═════════╝        ╚═════════╝
```

## 2. Ranh giới khối — cái gì thuộc F01, cái gì không

| Hạng mục | Thuộc F01? | Ghi chú |
|---|:-:|---|
| Thanh ghi trạng thái pha (2 bit) | ✅ | `state[1:0]`, netlist nối thẳng ra `uo_out[7:6]` |
| Bộ đếm thời lượng pha (2 bit) | ✅ | `pc`, ngưỡng `PHASE_TICKS-1` |
| Bộ đếm nhấp nháy đêm (1 bit) + bit pha nháy | ✅ | `nc`, `night_phase` |
| Bảng giải mã đầu ra 4 pha → 6 đèn | ✅ | 6 cell tổ hợp |
| Lớp phủ chế độ đêm | ✅ | Ghi đè đầu ra, **không** thêm trạng thái |
| **Chia tần từ clock hệ thống xuống tick** | ❌ | Tầng ngoài. **Đây là lý do `pc` chỉ 2 bit** |
| **Quyết định khi nào là "đêm"** | ❌ | Cảm biến ánh sáng / đồng hồ thời gian thực ở tầng ngoài |
| **Mạch lái công suất đèn, cách ly quang** | ❌ | Mạch analog/công suất, không phải khối số |
| **Phát hiện đèn cháy, báo lỗi** | ❌ | Không có cổng vào phản hồi |
| Cảm biến xe · đèn bộ hành · ưu tiên xe ưu tiên · phối hợp nhiều ngã tư | ❌ | Charter mục 3 ghi rõ **ngoài phạm vi** |

### Ánh xạ chân Tiny Tapeout — có một sai lệch phải xử lý

```
   tt_um wrapper                          f01_traffic_fsm_explicit
   ─────────────                          ────────────────────────
   uio_in[0]    ──────────────────────▶   night_mode      ✅ đúng Charter mục 4
   uio_in[1]    ──────────────────────▶   ena             ⚠️ Charter KHÔNG liệt kê chân này
   uo_out[2:0]  ◀──────────────────────   uo_out[2:0]     đèn hướng 1 {R,Y,G}
   uo_out[5:3]  ◀──────────────────────   uo_out[5:3]     đèn hướng 2
   uo_out[7:6]  ◀──────────────────────   uo_out[7:6]     mã trạng thái
   clk, rst_n   ──────────────────────▶   clk, rst_n
```

| | Charter mục 4 | RTL thật |
|---|---:|---:|
| Bit vào | 1 | **2** |
| Bit ra | 8 | 8 |
| Tổng / 24 chân | 9 | **10** |

Ngân sách vẫn dư 14 chân, nhưng bảng ánh xạ của Charter **cần cập nhật** — xem
`functional_spec.md` §0 (W-1). Phương án thay thế: buộc `ena = 1'b1` trong wrapper, khi
đó ánh xạ khớp Charter hoàn toàn nhưng mất chức năng đóng băng.

## 3. Vòng đời RTL → GDSII — trạng thái THẬT

Nguồn: `06_GDSII/physical_report.md` §1 và `05_VERIFICATION/test_matrix.csv`.

```
  ┌──────────────────────┐
  │ 01 Yêu cầu (Charter) │ ✅
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ 02 Đặc tả            │ ✅ interface / timing / functional_spec
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ 03 Kiến trúc + FSM   │ ✅ tài liệu này + fsm.md
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ 04 RTL               │ ✅ f01_traffic_fsm.sv  (mô phỏng)
  │                      │ ✅ f01_traffic_fsm_explicit.sv (tổng hợp)
  └──────────┬───────────┘     ⚠️ HAI MODULE KHÁC NHAU — xem functional_spec §0 W-2
             ▼
  ┌──────────────────────┐
  │ L0 Mô hình chuẩn PY  │ ✅ PASS — reference_model.py
  ├──────────────────────┤     (kiểm tính an toàn trên mọi trạng thái, ngôn ngữ bậc cao)
  │ L2 Mô phỏng RTL      │ ✅ PASS — "F01 TB PASS", $finish tại 256
  ├──────────────────────┤     ⚠️ mô phỏng module f01_traffic_fsm với PHASE_TICKS=2
  │ L3 Tổng hợp logic    │ ✅ PASS — Yosys 0.33, 32 cell, 279,0176 µm², 6 FF
  ├──────────────────────┤     ⚠️ tổng hợp module _explicit với PHASE_TICKS=4
  │    STA sau tổng hợp  │ ✅ PASS — OpenSTA 3.1.0, WNS 0,00 / TNS 0,00
  ├──────────────────────┤
  │    Ước lượng công suất│ ✅ 2,76e-05 W (tuần tự 92,8 % / tổ hợp 7,2 %)
  ├──────────────────────┤
  │ L4 Mô phỏng gate-level│ ⬜ CHƯA CHẠY
  ├──────────────────────┤
  │ L5 Mô phỏng + SDF    │ ⬜ CHƯA CHẠY
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ 06 Floorplan         │ ⬜ chưa chạy
  │    Placement / CTS   │ ⬜ chưa chạy
  │    Routing           │ ⬜ chưa chạy
  │    DRC / LVS / GDS   │ ⬜ chưa chạy
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ Tape-out · chế tạo   │ ⬛ KHÔNG ÁP DỤNG — Charter mục 3
  └──────────────────────┘
```

> ⚠️ **Lỗ hổng chuỗi bằng chứng cần nói thẳng:** mũi tên từ L2 xuống L3 **bị đứt**. Module
> được mô phỏng và module được tổng hợp là hai module khác nhau, với tham số khác nhau.
> Không có bước nào trong gói này nối hai bằng chứng đó lại. Cách vá rẻ nhất: chạy lại
> testbench với `f01_traffic_fsm_explicit #(.PHASE_TICKS(4))`.

## 4. Vì sao chế độ đêm là **lớp phủ** chứ không phải trạng thái thứ 5?

Đây là quyết định kiến trúc quan trọng nhất của F01, và nó là câu trả lời trực tiếp cho
Charter mục 9.

```
   PHƯƠNG ÁN A — thêm trạng thái        PHƯƠNG ÁN B — lớp phủ (ĐÃ CHỌN)
   ───────────────────────────          ──────────────────────────────

   6 trạng thái:                        4 trạng thái + 1 bit lớp phủ:
     NS_G, NS_Y, EW_G, EW_Y,              NS_G, NS_Y, EW_G, EW_Y
     NIGHT_ON, NIGHT_OFF                  (night_phase là thanh ghi riêng)

   ⌈log₂6⌉ = 3 bit trạng thái           ⌈log₂4⌉ = 2 bit trạng thái
   → 3 FF                                → 2 FF + 1 FF night_phase = 3 FF

   ❌ Vào đêm phải NHỚ pha cũ           ✅ Pha cũ tự được giữ trong `state`
      ở đâu đó → cần thêm 2 FF nữa
   ❌ 2 mã thừa (6 trạng thái/8 mã)     ✅ 0 mã thừa (4/4)
   ❌ Đồ thị 6 đỉnh, 10+ cạnh           ✅ Đồ thị 4 đỉnh, 8 cạnh
```

Phương án B thắng ở cả ba mặt: ít FF hơn, không có mã trạng thái bất hợp lệ, và **giữ
được pha đang chạy miễn phí** (INV-6). Cái giá phải trả: đầu ra trở thành **Mealy** thay
vì Moore — phân tích ở `fsm.md` §4.

## 5. Nghĩa vụ hợp đồng của tầng ngoài

| # | Nghĩa vụ | Hậu quả nếu vi phạm |
|---|---|---|
| H-1 | Phát `rst_n = 0` ≥ 1 chu kỳ sau bật nguồn | 6 flip-flop giữ `X`, đèn không xác định — **rủi ro an toàn** |
| H-2 | Cấp `clk` đã chia tần đúng nhịp tick mong muốn | Pha quá ngắn (vài ns) hoặc quá dài |
| H-3 | Đồng bộ `night_mode` nếu đến từ cảm biến bất đồng bộ | Metastability lan vào `night_phase` |
| H-4 | Giữ `ena = 1` trong vận hành bình thường | Đèn đóng băng vĩnh viễn ở một pha |
| H-5 | **Không** tin `uo_out[7:6]` trong chế độ đêm | Mã trạng thái hiện pha *bị giữ*, không phải "đang đêm". Không có bit nào báo "đang ở chế độ đêm" |
| H-6 | Mạch lái công suất phải tự bảo đảm không bật hai xanh nếu F01 hỏng | Phòng thủ nhiều lớp — chuẩn của hệ thống an toàn |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
