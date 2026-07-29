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
    @State private var zoomedPhoto: RepairLogPhoto?
    @State private var showingCamera = false

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
                            ForEach(Array(sortedPhotos.enumerated()), id: \.element.id) { index, photo in
                                if let data = photo.imageData, let uiImage = UIImage(data: data) {
                                    Button {
                                        zoomedPhoto = photo
                                    } label: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Photo \(index + 1) of \(sortedPhotos.count)")
                                    .accessibilityHint("Double-tap to view. Touch and hold for delete option.")
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
                    Label("Choose from Library", systemImage: "photo.badge.plus")
                }
                .onChange(of: selectedPhotos) {
                    Task { await loadPhotos() }
                }

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                }
            }
        }
        .navigationTitle(log.date.formatted(.dateTime.month(.abbreviated).day().year()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(item: $zoomedPhoto) { photo in
            if let uiImage = photo.imageData.flatMap(UIImage.init(data:)) {
                ZoomableImageView(image: uiImage, title: "Photo")
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                addCapturedPhoto(image)
            }
            .ignoresSafeArea()
        }
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

    private func addCapturedPhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let nextOrder = (log.photos.map(\.order).max() ?? -1) + 1
        let photo = RepairLogPhoto(order: nextOrder, imageData: data)
        log.photos.append(photo)
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
