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
    // info from settings, see `SettingsView``
    @AppStorage("HUB_IP_ADDRESS") private var ip_address: String = "localhost"
    @AppStorage("THIS_NODE_ID") static private var this_node_ID: String = "05.01.01.01.03.FF"  // static for static openlcnlib

    @StateObject var openlcblib = OpenlcbLibrary(defaultNodeID: NodeID(this_node_ID))

    // var telnetclient : TelnetClient! = nil // making this an Optional var allows reset once ip_address is available
    
    // var canphysical : CanPhysicalLayerGridConnect! = nil
    
    // TODO: figure out how to make this a real (not simulated) connection even while running tests; add tests
    
    let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "OlcbToolsApp")
    
    init () {
        // log some info
        let temp_this_node_ID = OlcbToolsApp.this_node_ID   // avoid "capture of mutating self" compile error
        logger.info("at startup, this program's default node ID is set to: \(temp_this_node_ID)")
        let temp_hub_ip_address = self.ip_address   // avoid "capture of mutating self" compile error
        logger.info("at startup, default hub IP address is set to: \(temp_hub_ip_address)")
    }
    
    func startup() {
        // create, but not yet connect, the Telnet connection to the hub
        let telnetclient : TelnetClient! = TelnetClient(host: self.ip_address, port: 12021)
        
        // initialize the OLCB processor
        let canphysical : CanPhysicalLayerGridConnect! = CanPhysicalLayerGridConnect(callback: telnetclient!.sendString)
        openlcblib.configureCanTelnet(canphysical!)
        
        //OlcbToolsApp.openlcblib.createSampleData()
        
        telnetclient.connection.receivedDataCallback = canphysical.receiveString // TODO: needs a better way to set this callback, too much visible here
        // start the connection
        telnetclient.start()
        
        // start the OLCB layer // TODO: should wait for connectionStarted callback frommes telnetclient to do this.
        canphysical.physicalLayerUp()
}
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        // iOS has four windows available fom the navigation bar at the bottom
        // macOS puts those in a tab bar at the top of the window
        WindowGroup {
            TabView {
//                // TODO: We're no longer using the default ContentView name for the base view
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
                    // when this view initially appears, start up the communication links
                    .onAppear() { self.startup() }
                    .environmentObject(openlcblib)

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
            }.environmentObject(openlcblib)
        }
        #if os(macOS)
        // macOS also has a separate "settings" window as Preferences
        Settings {  // creates a Preferences item in App menu
            SettingsView()
        }
        #endif
    }
}
