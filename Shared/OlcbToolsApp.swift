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
    @AppStorage("THIS_NODE_ID") private var this_node_ID: String = "05.01.01.01.03.FF"
    
    let openlcblib : OpenlcbLibrary
    let canphysical = CanPhysicalLayerSimulation() //  TODO: figure out how to make this a real (not simulated) connection even while testingx
    
    init () {
        
        openlcblib = OpenlcbLibrary(defaultNodeID: NodeID("05.01.01.01.03.FF")) // TODO: Using this_node_id causes "self used before all stored properties are initialized"
        
        openlcblib.configureCanTelnet(canphysical)
        openlcblib.createSampleData()

        //let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "OlcbToolsApp")
     }
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        // iOS has four windows available fom the navigation bar at the bottom
        // macOS puts those in a tab bar at the top of the window
        WindowGroup {
            TabView {
//                ContentView()
//                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
//                    .tabItem {
//                        Label("Nodes", systemImage: "app.connected.to.app.below.fill")
//                    }

                NodeListNavigationView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Nodes", systemImage: "app.connected.to.app.below.fill")
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
        // macOS also has a separate "settings" window as Preferences
        Settings {  // creates a Preferences item in App menu
            SettingsView()
        }
        #endif
    }
}
