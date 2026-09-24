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
                        // Force view identity to track the log; the entry view seeds a
                        // notesText @State buffer in init that would otherwise stick if
                        // SwiftUI reused the view for a different log.
                        .id(log.persistentModelID)
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
        game.refreshLastRepairLogDate()
    }

    private func deleteLogs(at offsets: IndexSet) {
        let snapshot = sortedLogs
        let doomed = offsets.compactMap { snapshot.indices.contains($0) ? snapshot[$0] : nil }
        let doomedIDs = Set(doomed.map(\.persistentModelID))

        // Detach from the relationship before deleting so the list and the
        // empty-state overlay reflect the removal on this run loop pass
        // rather than waiting on the context.
        game.repairLogs.removeAll { doomedIDs.contains($0.persistentModelID) }
        for log in doomed {
            modelContext.delete(log)
        }

        game.refreshLastRepairLogDate(excluding: doomedIDs)
        try? modelContext.save()
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
