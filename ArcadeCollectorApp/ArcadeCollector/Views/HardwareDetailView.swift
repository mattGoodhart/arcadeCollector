//
//  HardwareDetailView.swift
//  ArcadeCollector
//
//  Read-only detail sheet showing a game's hardware and emulation specs.
//  Values are populated opportunistically by ArtworkFetcher — if the user
//  hasn't fetched from the Arcade Database yet, most rows will be empty.
//

import SwiftUI

struct HardwareDetailView: View {
    let game: Game

    var body: some View {
        Form {
            if !emulationSectionEmpty {
                emulationSection
            }
            displaySection
            inputSection
            if !game.cpus.isEmpty {
                cpusSection
            }
            if !game.soundDevices.isEmpty {
                soundSection
            }
            if isFullyUnpopulated {
                unpopulatedHint
            }
        }
        .navigationTitle("Hardware")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: Sections

    private var emulationSection: some View {
        Section("Emulation") {
            if !game.emulationStatus.isEmpty {
                LabeledContent("Status", value: game.emulationStatus)
            }
            if !game.driver.isEmpty {
                NavigationLink {
                    DriverSourceView(driverFileName: game.driver)
                } label: {
                    LabeledContent("Driver", value: game.driver)
                }
            }
        }
    }

    private var displaySection: some View {
        Section("Display") {
            if !game.resolution.isEmpty {
                LabeledContent("Resolution", value: game.resolution)
            }
            LabeledContent("Orientation", value: game.orientation.displayName)
            if game.screens > 0 {
                LabeledContent("Screens", value: "\(game.screens)")
            }
            if game.displayType.lowercased() == "raster", !game.monitorResolutionType.isEmpty {
                LabeledContent("Monitor Type", value: game.monitorResolutionType)
            }
        }
    }

    private var inputSection: some View {
        Section("Input") {
            if !game.players.isEmpty {
                LabeledContent("Players", value: game.players)
            }
            if !game.inputControls.isEmpty {
                LabeledContent("Controls", value: game.inputControls)
            }
            if !game.inputButtons.isEmpty {
                LabeledContent("Buttons", value: game.inputButtons)
            }
        }
    }

    private var cpusSection: some View {
        Section("Processors") {
            ForEach(game.cpus, id: \.self) { cpu in
                Text(cpu)
            }
        }
    }

    private var soundSection: some View {
        Section("Sound") {
            ForEach(game.soundDevices, id: \.self) { device in
                Text(device)
            }
        }
    }

    private var unpopulatedHint: some View {
        Section {
            ContentUnavailableView(
                "No Hardware Details",
                systemImage: "cpu",
                description: Text("Tap “Fetch Artwork” on the previous screen to populate specs from the Arcade Database.")
            )
        }
    }

    // MARK: Derived state

    private var emulationSectionEmpty: Bool {
        game.emulationStatus.isEmpty && game.driver.isEmpty
    }

    private var isFullyUnpopulated: Bool {
        emulationSectionEmpty
            && game.resolution.isEmpty
            && game.inputControls.isEmpty
            && game.inputButtons.isEmpty
            && game.cpus.isEmpty
            && game.soundDevices.isEmpty
    }
}

#Preview("Populated") {
    NavigationStack {
        HardwareDetailView(game: {
            let g = Game(
                romSetName: "pacman",
                title: "Pac-Man",
                manufacturer: "Namco",
                year: "1980",
                players: "2",
                orientation: .vertical
            )
            g.emulationStatus = "GOOD"
            g.driver = "Mame 0.288 (may-29 2026)"
            g.resolution = "288x224px @60.606061Hz R90"
            g.inputControls = "joystick (4-way)"
            g.inputButtons = "0"
            g.cpus = ["Z80 @ 3.072 MHz"]
            g.soundDevices = ["Namco WSG"]
            return g
        }())
    }
}

#Preview("Empty") {
    NavigationStack {
        HardwareDetailView(game: Game(
            romSetName: "flagrall",
            title: "'96 Flag Rally",
            year: "1996",
            players: "1",
            orientation: .horizontal
        ))
    }
}
