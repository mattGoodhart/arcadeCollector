//
//  RepairLogEntryView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData
import PhotosUI

struct RepairLogEntryView: View {
    @Bindable var log: RepairLog
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPhotos: [PhotosPickerItem] = []

    private var sortedPhotos: [RepairLogPhoto] {
        log.photos.sorted { $0.order < $1.order }
    }

    var body: some View {
        Form {
            Section("Date") {
                DatePicker("Date", selection: $log.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: log.date) {
                        updateGameTimestamp()
                    }
            }

            Section("Notes") {
                TextEditor(text: $log.notes)
                    .frame(minHeight: 120)
            }

            Section("Photos") {
                if !sortedPhotos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(sortedPhotos) { photo in
                                if let data = photo.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .contextMenu {
                                            Button("Delete Photo", role: .destructive) {
                                                deletePhoto(photo)
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Label("Add Photos", systemImage: "photo.badge.plus")
                }
                .onChange(of: selectedPhotos) {
                    Task { await loadPhotos() }
                }
            }
        }
        .navigationTitle(log.date.formatted(.dateTime.month(.abbreviated).day().year()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func loadPhotos() async {
        let nextOrder = (log.photos.map(\.order).max() ?? -1) + 1

        for (offset, item) in selectedPhotos.enumerated() {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                continue
            }
            let photo = RepairLogPhoto(order: nextOrder + offset, imageData: data)
            log.photos.append(photo)
        }
        selectedPhotos.removeAll()
    }

    private func deletePhoto(_ photo: RepairLogPhoto) {
        modelContext.delete(photo)
    }

    private func updateGameTimestamp() {
        guard let game = log.game else { return }
        game.lastRepairLogDate = game.repairLogs
            .max(by: { $0.date < $1.date })?.date
    }
}
