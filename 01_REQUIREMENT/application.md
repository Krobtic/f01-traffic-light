# F01 · Bối cảnh ứng dụng



| | |
|---|---|
| Mã đề | **F01** |
| Tên đề | FSM đèn giao thông hai chiều có đèn vàng |
| Nhóm đề | F · Máy trạng thái hữu hạn (FSM) |
| Độ khó | Trung bình (nhẹ) |
| Loại mạch | **Tuần tự** |
| Quy mô ước lượng (Charter) | ~180–260 cell · 1×1 tile |
| Nguồn gốc | Project Charter — F01, mục 1 |

---

## 1. Mục tiêu và bối cảnh ứng dụng

Trích nguyên văn Charter mục 1:

> Phân tích khối số “FSM đèn giao thông hai chiều có đèn vàng” ở mức khối. Bối cảnh ứng dụng: Khối điều khiển đèn tín hiệu cho một ngã tư hai chiều ở khu dân cư, ban đêm chuyển sang nhấp nháy vàng.

## 2. Vị trí khối F01 trong hệ thống

```
   ┌──────────────┐      ┌──────────────────────────────┐      ┌──────────────┐
   │  Nguồn tín   │─────▶│      ►►► KHỐI F01 ◄◄◄        │─────▶│  Tầng tiêu   │
   │  hiệu / dữ   │      │  FSM đèn giao thông hai chiều │      │  thụ kết quả │
   │  liệu vào    │      │  Loại mạch: Tuần tự          │      │              │
   └──────────────┘      └──────────────────────────────┘      └──────────────┘
```

> Sơ đồ chi tiết có chú thích: `03_ARCHITECTURE/system_diagram.md`.

## 3. Phân loại analog / digital / mixed

| Khối | Phân loại | Ghi chú |
|---|---|---|
| Cảm biến / nguồn tín hiệu vật lý (nếu có) | Analog | Đại lượng liên tục |
| Chuyển đổi ADC/DAC (nếu có) | Mixed-signal | Ranh giới analog–số |
| **F01 — FSM đèn giao thông hai chiều có đèn vàng** | **Digital, tuần tự** | Có ô nhớ, hoạt động theo cạnh clock |
| Tầng xử lý phía sau | Digital | Tiêu thụ kết quả của F01 |

Bằng chứng cho dòng phân loại của F01: tổng hợp thật cho **6 flip-flop**
(`06_GDSII/synthesis/synth_stat.txt`).

---

**Truy vết:** yêu cầu sinh từ tài liệu này được đánh số `REQ-F01-0xx` trong
`01_REQUIREMENT/requirements.md`, và truy vết đến bằng chứng trong `07_TRACEABILITY/RTM.csv`.

*Phiên bản: v1.0 · Ngày: 2026-09-24*
