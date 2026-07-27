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
        .scrollContentBackground(.hidden)
        .background(Color.arcadeAboutBackground)
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
                description: "The primary source for this app, The Arcade Databse maintained by motoschifo provides game metadata, artwork, and hardware information.",
                banner: "About Banners/arcade_database_banner1",
                url: URL(string: "http://adb.arcadeitalia.net")!
            )
            DataSourceRow(
                name: "MAME",
                description: "The Multiple Arcade Machine Emulator project provides driver and hardware specifications. MAME® is a registered trademark of Gregory Ember.",
                banner: "About Banners/logo-mame",
                url: URL(string: "https://www.mamedev.org")!
            )
            DataSourceRow(
                name: "Progetto-SNAPS",
                description: "By Antopisa, Progetto-SNAPS provides game snapshots and media",
                banner: "About Banners/Progetto-snaps banner",
                url: URL(string: "https://www.progettosnaps.net")!
            )
            DataSourceRow(
                name: "Gaming-History",
                description: "Arcade gaming history and documentation © Copyright of Alexis Bousiges",
                banner: "About Banners/Gaming History Banner",
                url: URL(string: "https://www.arcade-history.com")!
            )
            DataSourceRow(
                name: "World of Longplays",
                description: "Arcade game longplays",
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
                description: "Player count and versus mode data © Copyright of Nomax",
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
            VStack(alignment: .leading, spacing: 10) {
                Image(banner)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(description)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
