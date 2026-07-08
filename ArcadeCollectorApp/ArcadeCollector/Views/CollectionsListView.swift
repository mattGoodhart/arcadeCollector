//
//  CollectionsListView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData

struct CollectionsListView: View {
    @Query(sort: \GameCollection.sortOrder) private var collections: [GameCollection]
    @Environment(\.modelContext) private var modelContext
    @State private var newCollectionName = ""
    @State private var isAddingCollection = false

    var body: some View {
        List {
            ForEach(collections) { collection in
                NavigationLink {
                    CollectionDetailView(collection: collection)
                } label: {
                    HStack {
                        Label(collection.name, systemImage: "folder")
                        Spacer()
                        Text("\(collection.games.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteCollections)
        }
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingCollection = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if collections.isEmpty {
                ContentUnavailableView(
                    "No Collections",
                    systemImage: "folder",
                    description: Text("Tap + to create a collection.")
                )
            }
        }
        .alert("New Collection", isPresented: $isAddingCollection) {
            TextField("Name", text: $newCollectionName)
            Button("Cancel", role: .cancel) {
                newCollectionName = ""
            }
            Button("Create") {
                createCollection()
            }
        }
    }

    private func createCollection() {
        let name = newCollectionName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            newCollectionName = ""
            return
        }
        let nextOrder = (collections.last?.sortOrder ?? -1) + 1
        let collection = GameCollection(name: name, sortOrder: nextOrder)
        modelContext.insert(collection)
        newCollectionName = ""
    }

    private func deleteCollections(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(collections[index])
        }
    }
}
