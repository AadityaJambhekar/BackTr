import Foundation

@MainActor
class SavedBacktestsStore: ObservableObject {
    @Published private(set) var items: [SavedBacktest] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("saved_backtests.json")
    }()

    init() { load() }

    func save(_ response: BacktestResponse) {
        items.insert(SavedBacktest(id: UUID(), savedAt: Date(), response: response), at: 0)
        persist()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = (try? decoder.decode([SavedBacktest].self, from: data)) ?? []
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
