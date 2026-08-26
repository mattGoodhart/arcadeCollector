//
//  BackupView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isExporting = false
    @State private var summary: BackupExporter.Summary?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Text("A backup includes your ownership status, per-component condition, and every repair-log entry with its photos. Game titles, artwork, and hardware specs are not included — those are re-downloaded from the Arcade Database on the next launch.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                if isExporting {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Preparing backup…")
                    }
                    .accessibilityElement(children: .combine)
                } else if let summary {
                    summaryRow(summary)
                    ShareLink(item: summary.fileURL) {
                        Label("Share Backup File", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        startExport()
                    } label: {
                        Label("Create Another Backup", systemImage: "arrow.clockwise")
                    }
                } else if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Button {
                        startExport()
                    } label: {
                        Label("Try Again", systemImage: "arrow.clockwise")
                    }
                } else {
                    Button {
                        startExport()
                    } label: {
                        Label("Create Backup", systemImage: "arrow.down.doc")
                    }
                }
            }
        }
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func summaryRow(_ summary: BackupExporter.Summary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Backup ready", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
            Text("\(summary.gameCount) game\(summary.gameCount == 1 ? "" : "s"), \(summary.repairLogCount) repair log\(summary.repairLogCount == 1 ? "" : "s"), \(summary.photoCount) photo\(summary.photoCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func startExport() {
        errorMessage = nil
        summary = nil
        isExporting = true

        let container = modelContext.container
        Task {
            do {
                let exporter = BackupExporter(modelContainer: container)
                let result = try await exporter.export()
                summary = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isExporting = false
        }
    }
}

#Preview {
    NavigationStack {
        BackupView()
    }
    .modelContainer(PreviewSupport.container)
}
