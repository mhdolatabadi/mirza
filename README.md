# حسابدار

اپ اندروید (Flutter) که پیامک‌های بانکی را می‌خواند، تراکنش‌ها را درمی‌آورد، گزارش ماهانه نشان می‌دهد و خروجی اکسل می‌دهد.

- `packages/bank_sms_parser`: پارسر پیامک (Dart خالص، بدون وابستگی). تست: `cd packages/bank_sms_parser && dart test`
- `lib/services/report.dart`: جمع ماهانه و جمع هر دسته
- `lib/services/categories.dart`: دسته‌بندی خودکار بر اساس کلمه‌های پیامک
- `lib/services/ledger_store.dart`: ذخیره‌ی دسته‌بندی‌های دستی و نام حساب‌ها روی گوشی
- `lib/services/excel_export.dart`: ساخت فایل اکسل (شیت‌های تراکنش‌ها، گزارش ماهانه و دسته‌بندی)
- `lib/services/sms_reader.dart`: گرفتن مجوز و خواندن صندوق پیامک

اجرا: `flutter pub get && flutter run` (گوشی اندروید وصل). تست: `flutter test`

قالب‌های پشتیبانی‌شده: بلو، پیامک‌های «مبلغ با علامت + / -» همراه مانده (پایا، حساب‌های نقطه‌دار مثل 10.xxxxxxx.1).
برای اضافه کردن بانک جدید، یک تابع به `_parsers` در `parser.dart` اضافه کنید و نمونه‌ی پیامک را در تست بگذارید.

## CI و APK

هر push به `main` تست‌ها را اجرا می‌کند و یک APK می‌سازد. فایل APK را از صفحه‌ی Actions، داخل اجرای آخر، بخش Artifacts (`hesabdar-apk`) دانلود کنید.
