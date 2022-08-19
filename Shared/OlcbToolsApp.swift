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

/// Main entry point for OlcbToolsApp
///
///  Contains the basic objects for the TelnetListenerLib and OpenlcbLibrary implementations
///
@main
struct OlcbToolsApp: App {
    // info from settings, see `SettingsView``
    @AppStorage("HUB_IP_ADDRESS") private var ip_address: String = "localhost"
    @AppStorage("HUB_IP_PORT") private var ip_port: String = "12021"
    @AppStorage("THIS_NODE_ID") static private var this_node_ID: String = "05.01.01.01.03.FF"  // static for static openlcnlib

    @StateObject var openlcblib = OpenlcbLibrary(defaultNodeID: NodeID(this_node_ID))
    
    // TODO: figure out how to make this a real (not simulated) connection even while running tests; add tests
    
    let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "OlcbToolsApp")
    
    /// Only logging at creation time, see `startup()` for configuration
    init () {
        // log some info at creation time
        let temp_this_node_ID = OlcbToolsApp.this_node_ID   // avoid "capture of mutating self" compile error
        logger.info("at startup, this program's default node ID is set to: \(temp_this_node_ID)")
        let temp_hub_ip_address = self.ip_address   // avoid "capture of mutating self" compile error
        logger.info("at startup, default hub IP address is set to: \(temp_hub_ip_address)")
        let temp_hub_ip_port = self.ip_port   // avoid "capture of mutating self" compile error
        logger.info("at startup, default hub port is set to: \(temp_hub_ip_port)")
    }
    
    var canphysical = CanPhysicalLayerGridConnect()
    
    /// Configure the various libraries and connections, then start the network access
    func startup() {
        // create, but not yet connect, the Telnet connection to the hub
        let port = UInt16(self.ip_port) ?? 12021
        let telnetclient : TelnetClient! = TelnetClient(host: self.ip_address, port: port)
        
        // initialize the OLCB processor
        canphysical.setCallBack(callback: telnetclient!.sendString)
        openlcblib.configureCanTelnet(canphysical)
        
        //OlcbToolsApp.openlcblib.createSampleData()  // commented out when real hardware is available and connected
        
        // route TelnetListenerLib incoming data to OpenlcbLib
        telnetclient.connection.receivedDataCallback = canphysical.receiveString // TODO: needs a better way to set this callback, too much visible here
        telnetclient.setStopCallback(telnetDidStopCallback(error:))

        // start the connection
        telnetclient.start()
        
        // start the OLCB layer // TODO: should wait for connectionStarted callback from telnetclient to do this.
        canphysical.physicalLayerUp()
    }
    
    // TODO: this restart only works once - maybe due to restart inside callback? Really need a better keep-alive solution
    func restartTelnet() {
        let telnetclient : TelnetClient! = TelnetClient(host: self.ip_address, port: 12021)
        canphysical.setCallBack(callback: telnetclient!.sendString)
        telnetclient.connection.receivedDataCallback = canphysical.receiveString // TODO: needs a better way to set this callback, too much visible here
        telnetclient.start()
    }
    
    public func telnetDidStopCallback(error: Error?) {
        if error == nil {
            // exit(EXIT_SUCCESS)
            logger.info("Connection exited with SUCCESS, restarting")
            restartTelnet()
        } else {
            // exit(EXIT_FAILURE)
            logger.info("Connection exited with ERROR: \(error!, privacy: .public)")
        }
    }

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        // iOS has four windows available fom the navigation bar at the bottom
        // macOS puts those in a tab bar at the top of the window
        WindowGroup {
            TabView {
                NodeListNavigationView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Nodes", systemImage: "app.connected.to.app.below.fill")
                    }
                    .environmentObject(openlcblib)

                MonitorView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Monitor", systemImage: "figure.stand.line.dotted.figure.stand")
                    }

                ClockView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Clocks", systemImage: "clock")
                    }

                ThrottleView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Throttle", systemImage: "train.side.front.car")
                    }
                    // TODO: add 2nd throttle on iPad?  See ContentView.swift for example code
#if os(iOS)
                // in iOS, the settings are another tab
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
#endif

            }   // TabView
                .environmentObject(openlcblib)
                .onAppear() {
                    // start the connection once you have the display up to receive events
                    self.startup()
                }

        } // WindowGroup
        
#if os(macOS)
        // macOS has a separate "settings" window as Preferences
        Settings {  // creates a Preferences item in App menu
            SettingsView()
        }
#endif

    }
}
