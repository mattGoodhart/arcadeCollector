//
//  RepairLogListView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData

struct RepairLogListView: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var modelContext

    private var sortedLogs: [RepairLog] {
        game.repairLogs.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            ForEach(sortedLogs) { log in
                NavigationLink {
                    RepairLogEntryView(log: log)
                } label: {
                    RepairLogRow(log: log)
                }
            }
            .onDelete(perform: deleteLogs)
        }
        .navigationTitle("Repair Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addEntry()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if game.repairLogs.isEmpty {
                ContentUnavailableView(
                    "No Repair Entries",
                    systemImage: "wrench.and.screwdriver",
                    description: Text("Tap + to add a repair log entry.")
                )
            }
        }
    }

    private func addEntry() {
        let entry = RepairLog(date: .now, notes: "")
        game.repairLogs.append(entry)
        game.lastRepairLogDate = entry.date
    }

    private func deleteLogs(at offsets: IndexSet) {
        let sorted = sortedLogs
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        DispatchQueue.main.async {
            game.lastRepairLogDate = game.repairLogs
                .max(by: { $0.date < $1.date })?.date
        }
    }
}

private struct RepairLogRow: View {
    let log: RepairLog

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(log.date, format: .dateTime.month(.wide).day().year())
                .font(.subheadline.bold())
            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if !log.photos.isEmpty {
                Label("\(log.photos.count) photo\(log.photos.count == 1 ? "" : "s")", systemImage: "photo")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
