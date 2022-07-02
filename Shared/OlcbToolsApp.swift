//
//  OlcbToolsApp.swift
//  Shared
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary
import TelnetListenerLib
import Network
import os

@main
struct OlcbToolsApp: App {
    @AppStorage("HUB_IP_ADDRESS") private var ip_address: String = "localhost"          // see ``SettingsView``
    @AppStorage("THIS_NODE_ID") private var this_node_ID: String = "05.01.01.01.03.FF"  // see ``SettingsView``

    static let openlcblib = OpenlcbLibrary(defaultNodeID: NodeID("05.01.01.01.03.FF")) // TODO: using this_node_ID results in "Cannot use instance member 'this_node_ID' within property initializer; property initializers run before 'self' is available"
    
    let telnetclient : TelnetClient
    
    let canphysical : CanPhysicalLayerGridConnect
    
    // TODO: figure out how to make this a real (not simulated) connection even while testing
    
    let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "OlcbToolsApp")
    
    init () {
         
        // create, but not yet connect, the Telnet connection to the hub
        telnetclient = TelnetClient(host: "192.168.1.206", port: 12021) // TODO: connection to AppStorage ip_address

        // initialize the OLCB processor
        canphysical = CanPhysicalLayerGridConnect(callback: telnetclient.sendString)
        OlcbToolsApp.openlcblib.configureCanTelnet(canphysical)
        OlcbToolsApp.openlcblib.createSampleData()
        
        // log some info
        let temp_this_node_ID = self.this_node_ID   // avoid "capture of mutating self" compile error
        logger.info("at startup, this program's default node ID is set to: \(temp_this_node_ID)")
        let temp_hub_ip_address = self.ip_address   // avoid "capture of mutating self" compile error
        logger.info("at startup, default hub IP address is set to: \(temp_hub_ip_address)")

        telnetclient.connection.receivedDataCallback = canphysical.receiveString // TODO: needs a better way to set this callback, too much visible here
        // start the connection
        telnetclient.start()
        
        // start the OLCB layer // TODO: should wait for connectionStarted callback to do this.
        canphysical.physicalLayerUp()
     }
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        // iOS has four windows available fom the navigation bar at the bottom
        // macOS puts those in a tab bar at the top of the window
        WindowGroup {
            TabView {
//                // We're no longer using the default ContentView name for the base view
//                ContentView()
//                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
//                    .tabItem {
//                        Label("Nodes", systemImage: "app.connected.to.app.below.fill")
//                    }

                NodeListNavigationView(openlcblib: OlcbToolsApp.openlcblib)
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
