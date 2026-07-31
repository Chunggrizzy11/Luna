# Luna Full-Stack Design

## 1. Mục tiêu

Xây dựng Luna thành ứng dụng Flutter và NestJS chạy end-to-end cho UAT, hỗ trợ theo dõi chu kỳ, nhật ký sức khỏe, chăm sóc hằng ngày, ghép đôi hai thiết bị ẩn danh, đồng bộ gần thời gian thực, thông báo, thống kê và backup dữ liệu.

Phạm vi gồm hai project:

- `Luna_FE`: Flutter mobile app cho người theo dõi chu kỳ và người đồng hành.
- `Luna_BE`: NestJS modular monolith, MongoDB và Socket.IO.

## 2. Quyết định kiến trúc

### Frontend

- Kiến trúc feature-first; mỗi feature tách `data`, `domain`, `presentation` khi có nghiệp vụ riêng.
- Riverpod quản lý state và dependency injection.
- GoRouter điều hướng theo vai trò thiết bị và trạng thái onboarding/pairing.
- Dio gọi REST API; Socket.IO nhận cập nhật gần thời gian thực.
- SharedPreferences chỉ lưu thiết lập không nhạy cảm. `deviceId` và token 256-bit được lưu bằng Android Keystore/iOS Keychain qua secure storage; local database/cache giữ snapshot cần thiết để app đọc được dữ liệu gần nhất khi mất mạng.
- Theme sáng/tối, localization tiếng Việt và các widget dùng chung nằm trong `core`.

### Backend

- NestJS modular monolith với module theo miền nghiệp vụ.
- MongoDB qua Mongoose; database UAT mặc định là `mongodb://127.0.0.1:27017/luna_uat` và có thể kiểm tra bằng MongoDB Compass.
- REST API cho command/query thông thường; Socket.IO phát sự kiện sau các thay đổi cần đồng bộ.
- Swagger mô tả API; class-validator kiểm tra request; response/error được chuẩn hóa.
- Scheduler tạo nhắc nhở, daily care và thông báo chu kỳ.

## 3. Danh tính, ghép đôi và quyền truy cập

- Không dùng tài khoản người dùng.
- Lần chạy đầu, app đăng ký thiết bị và nhận `deviceId` cùng bearer token ngẫu nhiên.
- Thiết bị chọn vai trò `owner` hoặc `partner`.
- Owner tạo mã ghép đôi 8 ký tự hoặc QR dùng một lần, có thời hạn 5 phút. Partner nhập/quét mã để tham gia cùng `pairId`; mã bị hủy ngay sau khi dùng thành công.
- Mỗi mã chỉ được thử sai tối đa 5 lần; endpoint tạo/nhập mã áp dụng rate limit theo thiết bị và địa chỉ mạng.
- Token được băm ở backend; API xác thực token và chỉ truy cập dữ liệu thuộc đúng thiết bị/pair.
- Owner có toàn quyền với dữ liệu sức khỏe của mình.
- Partner chỉ được đọc trạng thái chu kỳ tóm tắt, mức khó chịu tổng hợp, daily care và thông báo dành cho partner.
- Ghi chú chi tiết mặc định chỉ owner đọc được. Checklist do partner quản lý và owner không sửa được.
- Thu hồi ghép đôi làm mất quyền truy cập của partner nhưng không xóa lịch sử sức khỏe của owner.
- Mọi truy vấn theo ID đều kiểm tra object thuộc đúng `deviceId`/`pairId`; backend không dùng ID từ client làm căn cứ duy nhất để cấp quyền.
- App có khóa sinh trắc học/PIN thiết bị tùy chọn. Đây là khóa cục bộ, không tạo tài khoản và không thay đổi token backend.
- Owner có thể thu hồi token thiết bị cũ; thiết bị bị thu hồi phải đăng ký lại và ghép đôi lại.

Giới hạn chấp nhận cho MVP: nếu gỡ ứng dụng mà chưa xuất backup, thiết bị phải đăng ký và ghép lại; không có quy trình phục hồi danh tính qua email.

## 4. Mô hình dữ liệu

### Device

`deviceId`, `tokenHash`, `role`, `pairId`, `platform`, `fcmToken`, `lastSeenAt`, timestamps.

Token thô chỉ trả về một lần khi đăng ký, không ghi log và không lưu trong database; backend chỉ lưu hash. Token có thể được rotate/revoke theo thiết bị.

### Pair

`ownerDeviceId`, `partnerDeviceId`, `pairingCodeHash`, `pairingCodeExpiresAt`, `status`, timestamps.

### Cycle

`pairId`, `ownerDeviceId`, `startDate`, `endDate`, `periodLength`, `cycleLength`, `source`, timestamps.

Cycle đang hoạt động có `endDate = null`. Không cho phép hai cycle đang hoạt động cùng lúc. Độ dài cycle là khoảng cách giữa hai ngày bắt đầu liên tiếp; `periodLength` tính cả ngày bắt đầu và kết thúc.

### DailyLog

`pairId`, `ownerDeviceId`, `date`, `mood`, `symptoms[]`, `discomfortLevel`, `note`, timestamps. Mỗi owner chỉ có một log cho một ngày; cập nhật mood, triệu chứng và note dùng upsert.

### Checklist

`pairId`, `partnerDeviceId`, `date`, `items[]`, timestamps. Các item chuẩn gồm hỏi thăm, gọi điện, video call, ôm, mua đồ ăn, mua thuốc, nhắc uống nước và chúc ngủ ngon.

### Notification

`pairId`, `recipientDeviceId`, `type`, `title`, `body`, `data`, `readAt`, `createdAt`.

### Settings

`deviceId`, `defaultCycleLength`, `defaultPeriodLength`, `ovulationEnabled`, `notificationsEnabled`, `reminderPreferences`, `themeMode`, timestamps.

### CareSuggestion

`key`, `audience`, `cyclePhase`, `title`, `message`, `icon`, `active`. Nội dung mặc định được seed để UAT không phụ thuộc CMS.

## 5. Quy tắc nghiệp vụ

- Ngày chu kỳ hiện tại được tính từ cycle gần nhất đã bắt đầu.
- Khi chưa đủ hai cycle hoàn chỉnh, dự đoán dùng `defaultCycleLength`; sau đó dùng trung bình tối đa sáu cycle hoàn chỉnh gần nhất.
- Kỳ tiếp theo dự đoán bằng ngày bắt đầu gần nhất cộng độ dài chu kỳ trung bình.
- Ngày rụng trứng dự đoán là 14 ngày trước kỳ tiếp theo và chỉ hiển thị khi bật tùy chọn.
- Ngày dự đoán kỳ kinh kéo dài theo độ dài kỳ kinh trung bình hoặc giá trị mặc định.
- Dashboard trả về ngày chu kỳ, trạng thái đang hành kinh, số ngày đến kỳ tiếp theo, chu kỳ trung bình, tóm tắt trạng thái và daily care.
- Mood phổ biến và triệu chứng phổ biến được tổng hợp theo khoảng ngày yêu cầu.
- Nhiều triệu chứng hoặc `discomfortLevel` cao tạo thông báo chăm sóc cho partner nhưng không lộ nội dung note.
- Bắt đầu/kết thúc kỳ, trước kỳ, cuối kỳ và nhắc nhập nhật ký là các loại thông báo riêng, chống gửi trùng theo ngày và loại.

## 6. API và realtime contract

Base path: `/api/v1`.

- `POST /devices/register`, `PATCH /devices/me`, `POST /devices/push-token`.
- `POST /partners/codes`, `POST /partners/join`, `GET /partners/status`, `DELETE /partners/unpair`.
- `POST /cycles/start`, `POST /cycles/end`, `GET /cycles`, `GET /cycles/current`, `GET /cycles/prediction`.
- `GET /calendar`, trả ngày có kinh, dự đoán và rụng trứng theo tháng.
- `GET|PUT /moods/:date`, `GET|PUT /symptoms/:date`, `GET|PUT|DELETE /notes/:date`.
- `GET /statistics/summary`, `GET /statistics/cycles`, `GET /statistics/trends`.
- `GET|PUT /settings/me`.
- `GET /health/dashboard`, `GET /health/care/today`.
- `GET|PUT /checklists/:date`.
- `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all`, `DELETE /notifications/:id`.
- `GET /health/journal`.
- `GET /health/backup/export`, `POST /health/backup/import`.
- `GET /health/sync/changes?since=...` cho đồng bộ bù sau khi mất kết nối.

Các route health tổng hợp nằm trong module `health`; checklist nằm trong module `partner`; daily care và tác vụ định kỳ nằm trong module `scheduler`. Ba module `mood`, `symptom` và `note` cùng sử dụng daily-log repository do module `health` export, tránh tạo ba collection rời cho cùng một ngày.

Socket namespace `/sync` xác thực bằng bearer token và phát các event `cycle.updated`, `daily-log.updated`, `checklist.updated`, `notification.created`, `settings.updated`, `pair.updated`. Payload chỉ mang ID, loại thay đổi và `updatedAt`; client gọi API để lấy dữ liệu chuẩn.

## 7. Màn hình Flutter

- Splash và onboarding chọn vai trò.
- Dashboard theo vai trò owner/partner.
- Cycle tracking với nút bắt đầu/kết thúc và dự đoán.
- Calendar theo tháng và bottom sheet nhật ký ngày.
- Mood, symptom và note editor.
- Statistics với history, summary và chart chu kỳ.
- Partner pairing, trạng thái kết nối và thu hồi kết nối.
- Daily care và checklist partner.
- Notification center.
- Health journal.
- Settings, notification preferences và export/import backup.

Widget iPhone đọc snapshot dashboard từ App Group. Flutter cung cấp service cập nhật snapshot; iOS WidgetKit extension, signing và App Group cần được bật bằng Apple Developer team khi chạy thiết bị thật.

## 8. Thông báo

- Local notification hoạt động theo lịch cấu hình trên thiết bị.
- Backend có adapter FCM và biến môi trường mẫu; adapter được vô hiệu hóa an toàn khi thiếu Firebase service-account.
- Khi có credentials, scheduler hoặc nghiệp vụ tạo notification record rồi gửi push đến FCM token của thiết bị nhận.
- UAT không có Firebase vẫn kiểm thử được notification center, local reminders và Socket.IO notification event.

## 9. Xử lý lỗi và đồng bộ

- Response lỗi chứa `code`, `message`, `details`, `timestamp` và `path`.
- Backend không trả stack trace hoặc dữ liệu nhạy cảm ra response; logger che token, mã ghép đôi, FCM token và nội dung ghi chú.
- Production bắt buộc HTTPS. HTTP chỉ được phép trong profile UAT local và phải được khai báo rõ qua biến môi trường.
- Flutter không kết nối trực tiếp MongoDB. MongoDB chỉ bind interface tin cậy, bật authorization và dùng tài khoản `luna_app` có quyền tối thiểu trên database Luna; Compass dùng tài khoản database riêng.
- Client map lỗi mạng, timeout, validation, unauthorized và server error sang Failure có thông báo tiếng Việt.
- Mutation có optimistic UI chỉ với checklist và đánh dấu đã đọc; dữ liệu sức khỏe chờ server xác nhận.
- Sau reconnect, client gọi `sync/changes`, invalidate provider liên quan rồi tải lại nguồn dữ liệu chuẩn.
- Backup import có version, validate toàn bộ trước khi ghi và upsert theo ngày/ID; dữ liệu không hợp lệ không được ghi một phần.

## 10. Kiểm thử và tiêu chí hoàn thành

### Backend

- Unit test tính chu kỳ, dự đoán kỳ tiếp theo, rụng trứng, thống kê và rule thông báo.
- Integration/e2e test đăng ký thiết bị, ghép đôi, phân quyền, start/end cycle, daily log, backup/import.
- App khởi động với MongoDB local, Swagger truy cập được và seed UAT chạy lặp lại không tạo bản ghi trùng.

### Frontend

- Unit test mapper/repository và logic dashboard.
- Widget test splash/onboarding, dashboard, cycle action, daily log và pairing.
- `flutter analyze` không có lỗi; test suite vượt qua.

### Hoàn thành chức năng

- Toàn bộ 17 nhóm chức năng có đường dẫn UI và backend/local implementation tương ứng.
- Hai thiết bị giả lập có thể ghép đôi, ghi dữ liệu và nhận cập nhật Socket.IO.
- Có thể xem dữ liệu UAT bằng Compass tại database `luna_uat`.
- FCM và WidgetKit được triển khai theo contract nhưng cần credentials/signing của chủ dự án để chạy trên hạ tầng thật.

## 11. Ngoài phạm vi

- Đăng nhập email, Google hoặc Apple.
- Portal quản trị/CMS.
- Tư vấn hoặc chẩn đoán y khoa.
- Hạ tầng cloud production, domain, TLS, store deployment và Apple/Firebase credentials.
