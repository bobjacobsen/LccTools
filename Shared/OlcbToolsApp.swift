//
//  OlcbToolsApp.swift
//  Shared
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary
import os

@main
struct OlcbToolsApp: App {
    static let openlcblib = OpenlcbLibrary()
    let canphysical = CanPhysicalLayerSimulation()
    
    init () {
        OlcbToolsApp.openlcblib.configureCanTelnet(canphysical)
        OlcbToolsApp.openlcblib.createSampleData()

        //let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "OlcbToolsApp")
     }
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        // iOS has four windows available fom the navigation bar at the bottom
        // macOS puts those in a tab bar at the top of the window
        WindowGroup {
            TabView {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Configure", systemImage: "app.connected.to.app.below.fill")
                    }

                MonitorView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Monitor", systemImage: "figure.stand.line.dotted.figure.stand")
                    }

                ThrottleView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Throttle", systemImage: "train.side.front.car")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
        #if os(macOS)
        // macOS halso as a separate "settings" window as Preferences
        Settings {  // creates a Preferences item in App menu
            SettingsView()
        }
        #endif
    }
}
