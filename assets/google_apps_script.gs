/**
 * میرزا: دریافت تراکنش‌ها از اپ و ثبت در همین گوگل شیت.
 *
 * نصب: Extensions → Apps Script، این کد را جای کد پیش‌فرض بگذارید، بعد
 * Deploy → New deployment → Web app با Execute as: Me و
 * Who has access: Anyone. آدرس Web app را در اپ وارد کنید.
 *
 * اپ هر بار همه‌ی تراکنش‌های جدید یا تغییرکرده را می‌فرستد. هر ردیف با
 * ستون «شناسه» شناخته می‌شود، پس چیزی تکراری ثبت نمی‌شود. ستون‌هایی که
 * خودتان سمت چپ جدول اضافه کنید دست نمی‌خورند.
 */
const SHEET_NAME = 'تراکنش‌ها';

function doPost(e) {
  const body = JSON.parse(e.postData.contents);
  const props = PropertiesService.getScriptProperties();
  const saved = props.getProperty('TOKEN');
  if (!saved) {
    // First request: remember this phone's secret.
    props.setProperty('TOKEN', body.token);
  } else if (saved !== body.token) {
    return json_({ ok: false, error: 'bad token' });
  }

  const lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    return json_(upsert_(body.headers, body.rows));
  } finally {
    lock.releaseLock();
  }
}

function upsert_(headers, rows) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);
  const width = headers.length + 1;
  if (sheet.getLastRow() === 0) setUp_(sheet, ['شناسه'].concat(headers));

  const last = sheet.getLastRow();
  const data = last > 1 ? sheet.getRange(2, 1, last - 1, width).getValues() : [];
  const index = new Map(data.map((r, i) => [String(r[0]), i]));

  const appended = [];
  let updated = 0;
  for (const r of rows) {
    const row = [r.id].concat(r.values.map((v) => (v === null ? '' : v)));
    const at = index.get(r.id);
    if (at === undefined) {
      index.set(r.id, data.length + appended.length);
      appended.push(row);
    } else if (at < data.length) {
      data[at] = row;
      updated++;
    } else {
      appended[at - data.length] = row;
    }
  }
  if (updated) sheet.getRange(2, 1, data.length, width).setValues(data);
  if (appended.length) sheet.getRange(last + 1, 1, appended.length, width).setValues(appended);
  return { ok: true, added: appended.length, updated: updated };
}

function setUp_(sheet, headers) {
  sheet.appendRow(headers);
  sheet.setRightToLeft(true);
  sheet.setFrozenRows(1);
  sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold');
  // Keep dates, times and account numbers as text so Sheets does not
  // reinterpret «1405/08/07» or «10.9554759.1».
  sheet.getRange('A:F').setNumberFormat('@');
  sheet.getRange('G:H').setNumberFormat('#,##0');
  sheet.getRange('I:K').setNumberFormat('@');
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
