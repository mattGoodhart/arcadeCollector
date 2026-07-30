//
//  AboutView.swift
//  ArcadeCollector
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            appSection
            basicInfoSection
            dataSection
            disclaimerSection
            dataSourcesSection
            acknowledgmentsSection
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.arcadeAboutBackground)
    }

    private var dataSection: some View {
        Section("Your Data") {
            NavigationLink {
                BackupView()
            } label: {
                Label("Backup Collection", systemImage: "arrow.down.doc")
            }
        }
    }

    private var appSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "arcade.stick.console")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

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
        Section("Data Sources & Acknowledgements") {
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
    
    private var basicInfoSection: some View {
        Section("Basic Info") {
            Text("This App was designed for arcade game enthusiasts who want to easily reference and track their game collection. \n\nThis app is particularly focused on game repair by providing an easy way to create and manage repair logs, and track the overall working status of each game. Specific hardware information from the Arcade Database is provided here to further assist that effort. \n\nInitially, the app provides a list of 3,855 games focused on older, raster and vector monitor-based games. Newer games designed for flat panel displays are typically PC-based and less interesting to maintian, so they are not included here (for now).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var disclaimerSection: some View {
        Section("Disclaimer") {
            Text("This app is NOT an emulator, a way to play games, or a way to source game ROMs or any other protected intellectual property. This app is only a reference tool for tracking and maintaining your collection.\n\nAll names and images are used here for informational purposes only ('Fair Use' usage, per 17 U.S.C. Section 107), Their use neither detracts value nor inhibits sales in any way. \n\nAll copyrights and trademarks belong to their respective copyright and trademark holders.")
                .font(.subheadline)
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
                    .accessibilityHidden(true)

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
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name). \(description)")
        .accessibilityHint("Opens website")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
