//
//  AboutView.swift
//  ArcadeCollector
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            appSection
            dataSourcesSection
            acknowledgmentsSection
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "arcade.stick.console")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)

                Text("Arcade Collector")
                    .font(.title2.bold())

                Text("Version \(appVersion)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("by Matt Goodhart")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private var dataSourcesSection: some View {
        Section("Data Sources") {
            DataSourceRow(
                name: "Arcade Database",
                description: "Game metadata, artwork, and hardware information",
                banner: "About Banners/arcade_database_banner1",
                url: URL(string: "http://adb.arcadeitalia.net")!
            )
            DataSourceRow(
                name: "MAME",
                description: "Driver and hardware specifications",
                banner: "About Banners/logo-mame",
                url: URL(string: "https://www.mamedev.org")!
            )
            DataSourceRow(
                name: "Progetto-SNAPS",
                description: "Game snapshots and media",
                banner: "About Banners/Progetto-snaps banner",
                url: URL(string: "https://www.progettosnaps.net")!
            )
            DataSourceRow(
                name: "Gaming-History",
                description: "Arcade gaming history and documentation",
                banner: "About Banners/Gaming History Banner",
                url: URL(string: "https://www.arcade-history.com")!
            )
            DataSourceRow(
                name: "World of Longplays",
                description: "Gameplay recordings",
                banner: "About Banners/wolheader",
                url: URL(string: "https://www.longplays.org")!
            )
            DataSourceRow(
                name: "MAME Icons",
                description: "Game icons",
                banner: "About Banners/MAMUIconsBanner",
                url: URL(string: "http://icons.mameworld.info")!
            )
            DataSourceRow(
                name: "NPlayers",
                description: "Player count and versus mode data",
                banner: "About Banners/titre",
                url: URL(string: "https://nplayers.arcadebelgium.be")!
            )
        }
    }

    private var acknowledgmentsSection: some View {
        Section("Acknowledgments") {
            Text("Game data sourced from the community-driven Arcade Database at adb.arcadeitalia.net. All ROM set names, titles, and driver information originate from the MAME project.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

private struct DataSourceRow: View {
    let name: String
    let description: String
    let banner: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            VStack(alignment: .leading, spacing: 8) {
                Image(banner)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.body)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
