import SwiftUI
import WidgetKit

private struct Prayer: Decodable {
    let name: String
    let epoch: Double
    var date: Date { Date(timeIntervalSince1970: epoch / 1000) }
}
private struct PrayerDay: Decodable {
    let date: String
    let hijri: String
    let prayers: [Prayer]
    let source: String
    let completed: Int?
}
private struct Snapshot: Decodable {
    let version: Int
    let city: String
    let zone: String
    let language: String?
    let labels: [String:String]?
    func label(_ key: String, _ fallback: String) -> String { labels?[key] ?? fallback }
    let generated: Double
    let days: [PrayerDay]
    static func load() -> Snapshot? {
        guard let raw = UserDefaults(suiteName: "group.kz.mihrab.mihrab.widgets")?.string(forKey: "snapshot"),
              let data = raw.data(using: .utf8), data.count <= 65536,
              let value = try? JSONDecoder().decode(Snapshot.self, from: data),
              value.version == 1, (1...7).contains(value.days.count),
              TimeZone(identifier: value.zone) != nil,
              value.days.allSatisfy({ $0.prayers.count == 5 }) else { return nil }
        return value
    }
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? .gmt
        return calendar
    }
    func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = calendar.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    func clock(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = calendar.timeZone
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
private struct Entry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot?
    var today: PrayerDay? {
        guard let s = snapshot else { return nil }
        return s.days.first { $0.date == s.dayKey(date) }
    }
    var next: Prayer? {
        guard today != nil, let s = snapshot else { return nil }
        return s.days.flatMap(\.prayers).filter { $0.date > date }.min { $0.date < $1.date }
    }
}
private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), snapshot: nil) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), snapshot: Snapshot.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date()
        guard let s = Snapshot.load() else {
            completion(Timeline(entries: [Entry(date: now, snapshot: nil)], policy: .after(now.addingTimeInterval(1800))))
            return
        }
        var dates = Set([now])
        for prayer in s.days.flatMap(\.prayers) where prayer.date > now {
            dates.insert(prayer.date)
        }
        let start = s.calendar.startOfDay(for: now)
        for offset in 1...7 {
            if let midnight = s.calendar.date(byAdding: .day, value: offset, to: start) {
                dates.insert(midnight)
            }
        }
        let entries = dates.sorted().map { Entry(date: $0, snapshot: s) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
private struct PrayerView: View {
    let entry: Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme
    private var background: Color { scheme == .dark ? Color(red: 0.06, green: 0.24, blue: 0.20) : Color(red: 0.95, green: 0.94, blue: 0.89) }
    private var ink: Color { scheme == .dark ? .white : Color(red: 0.06, green: 0.24, blue: 0.20) }
    var body: some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(background, for: .widget)
        } else {
            content.padding(12).background(background)
        }
    }
    private var content: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("MIHRAB").font(.caption.bold())
            if let s = entry.snapshot, let day = entry.today {
                Text(s.city + " · " + day.source).font(.caption2).lineLimit(1)
                Text(day.hijri).font(.caption2).lineLimit(1)
                if let next = entry.next {
                    Text(next.name + " " + s.clock(next.date)).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                    if s.dayKey(next.date) != day.date { Text(s.label("tomorrow","Завтра")).font(.caption2) }
                } else { Text(s.label("refresh","Обновите расписание")).font(.caption) }
                if family != .systemSmall {
                    HStack(spacing: 5) {
                        ForEach(day.prayers.indices, id: \.self) { i in
                            VStack(spacing: 2) {
                                Text(day.prayers[i].name).font(.caption2).lineLimit(1).minimumScaleFactor(0.6)
                                Text(s.clock(day.prayers[i].date)).font(.caption.bold())
                            }.frame(maxWidth: .infinity)
                        }
                    }
                }
                if let completed = day.completed {
                    Text(s.label("diary","Дневник") + ": \(completed)/5").font(.caption2).privacySensitive()
                }
            } else {
                Text(entry.snapshot?.label("openMihrab","Откройте MIHRAB") ?? "Откройте MIHRAB").font(.headline)
                Text(entry.snapshot?.label("refreshHint","Для обновления расписания") ?? "Для обновления расписания").font(.caption2)
            }
            Spacer(minLength: 0)
        }.environment(\.layoutDirection, entry.snapshot?.language == "ar" ? .rightToLeft : .leftToRight).foregroundColor(ink).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
@main
struct MihrabPrayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MihrabPrayerWidget", provider: Provider()) { entry in
            PrayerView(entry: entry)
        }
        .configurationDisplayName("MIHRAB")
        .description("Расписание и ближайший намаз")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
