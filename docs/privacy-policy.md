# MIHRAB — Политика конфиденциальности / Privacy policy

Версия / Version: 0.9.7 — 2026-11-24

## Данные и хранение

MIHRAB не требует регистрации. Настройки, выбранный город, избранное, история тасбиха, дневник намазов, позиция чтения и кеш сохраняются локально, если функция поддерживается платформой. Системные резервные копии могут включать данные приложения. Дневник отражает религиозную практику; на мобильных устройствах его сводка может отображаться в системном виджете.

## Геолокация

При выборе GPS приложение запрашивает координаты для расчёта направления Киблы на устройстве. Можно использовать выбранный город без GPS. В просмотренной реализации Киблы координаты GPS не отправляются в API. При загрузке расписания ДУМК запрос может содержать координаты и год.

## Сеть и внешние сервисы

Для расписания используется api.muftyat.kz, для текста Корана и переводов — api.alquran.cloud, для аудио — cdn.islamic.network. Эти сервисы и веб-хостинг получают технические данные запросов, включая IP-адрес, и могут вести собственные журналы. MIHRAB не управляет их сроками хранения. В просмотренной реализации не обнаружен отдельный сервер учётных записей или рекламный SDK; это не является гарантией отсутствия обработки данных сторонними библиотеками.

## Разрешения

Геолокация нужна для Киблы, уведомления и точные будильники — для напоминаний, воспроизведение в foreground — для азана, восстановление после перезагрузки — для расписания уведомлений. Импорт пользовательского аудио выполняется через системный выбор файлов. Разрешения можно отозвать в настройках ОС.

## Удаление данных

Можно очистить загруженный контент средствами приложения, а все локальные данные — через очистку данных приложения или его удаление. Для веб-версии очистите данные сайта в браузере. Системные резервные копии и журналы сторонних сервисов управляются отдельно.

## Обратная связь

Вопросы по конфиденциальности: https://github.com/drycov/MIHRAB/issues. Не публикуйте персональные данные в открытых обращениях.

# English

## Data and storage

MIHRAB does not require an account. Settings, selected city, bookmarks, tasbih history, prayer diary, reading position and caches are stored locally where supported. Operating system backups may include app data. Prayer diary records reflect religious practice; summaries may appear in mobile home-screen widgets.

## Location

GPS is requested when you choose GPS-based Qibla. The inspected Qibla implementation calculates direction on the device and does not send GPS coordinates to an API. You can use a selected city instead. DUMK timetable requests may include coordinates and a year.

## Network services

Timetables use api.muftyat.kz, Quran text and translations use api.alquran.cloud, audio uses cdn.islamic.network. These services and the web host receive technical request data such as IP addresses and may retain their own logs. MIHRAB does not control their retention. The inspected implementation has no identified account server or advertising SDK; this does not guarantee that dependencies process no data.

## Permissions

Location supports Qibla; notifications and exact alarms support reminders; foreground media playback supports adhan; boot recovery restores reminders. User audio is imported through a system file picker. Permissions can be revoked in OS settings.

## Deletion

Remove downloads in the app. Clear app data or uninstall to remove local data; on web, clear site data in your browser. OS backups and third-party logs are managed separately.

## Contact

Privacy questions: https://github.com/drycov/MIHRAB/issues. Do not publish personal information in public issues.
