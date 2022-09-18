//
//  OlcbToolsApp.swift
//  Shared
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary
import TelnetListenerLib
import os

/// Main entry point for OlcbToolsApp
///
///  Contains the basic objects for the TelnetListenerLib and OpenlcbLibrary implementations
///
@main
struct OlcbToolsApp: App {
    // info from settings, see `SettingsView``
    @AppStorage("HUB_IP_ADDRESS") private var ip_address: String = ""
    @AppStorage("HUB_IP_PORT") private var ip_port: String = "12021"
    @AppStorage("THIS_NODE_ID") static private var this_node_ID: String = "05.01.01.01.03.FF"  // static for static openlcnlib

    @StateObject var openlcblib = OpenlcbLibrary(defaultNodeID: NodeID(this_node_ID))
    
    @Environment(\.scenePhase) var scenePhase  // for .background, etc
        
    var tcpConnectionModel = TcpConnectionModel()
    
    let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "OlcbToolsApp")
    
    static var doneStartup = false  // static to avoid "self is immutable" issue
    
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
        // only do once
        guard !OlcbToolsApp.doneStartup else { return }
        OlcbToolsApp.doneStartup = true
        
        // if there's no host name, show settings
        if self.ip_address == "" {
            self.selectedTab = "Settings"
        } else {
            self.selectedTab = "Throttle"
        }
        
        // create, but not yet connect, the Telnet connection to the hub (connection done on transition to Active state below)
        let port = UInt16(self.ip_port) ?? 12021
        tcpConnectionModel.load(hostName: self.ip_address, portNumber: port, receivedDataCallback: canphysical.receiveString, startUpCallback: startUpCallback)
        
        // configure the OLCB processor -> telnet link
        canphysical.setCallBack(callback: tcpConnectionModel.send(string:))
        
        openlcblib.configureCanTelnet(canphysical)
        
        //OlcbToolsApp.openlcblib.createSampleData()  // commented out when real hardware is available and connected
        
    }
    
    // connection call back when link goes to 'ready' for first time, starts OpenLCB processing
    private func startUpCallback() {
        // start the OLCB layer
        logger.debug("starting OpenLCB layer")
        canphysical.physicalLayerUp()
    }
    
    let persistenceController = PersistenceController.shared

    @State private var selectedTab : String = "Throttle"
    
    var body: some Scene {
        // iOS on iPhone has four spots available in the navigation bar at the bottom
        // macOS puts all the tabs in a tab bar at the top of the window
        WindowGroup {
            TabView(selection: $selectedTab) {
                ThrottleView(throttleModel: openlcblib.throttleModel0)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Throttle", systemImage: "train.side.front.car")
                    }.tag("Throttle")

               ClockView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Clocks", systemImage: "clock")
                    }.tag("Clock")
              
                ConsistView(consistModel: openlcblib.consistModel0, selectionModel: openlcblib.throttleModel0)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Consists", systemImage: "forward")
                    }.tag("Consist")

                // This has wierd nav issues if it comes from "More..." so keep it above that
                NodeListNavigationView(lib: openlcblib)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Configure", systemImage: "app.connected.to.app.below.fill")
                    }.tag("NodeListNavigation")
                    .environmentObject(openlcblib)

                // iPhone 12 goes to "More..." at this point

                MonitorView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Monitor", systemImage: "figure.stand.line.dotted.figure.stand")
                    }.tag("Monitor")

#if os(iOS)
                // in iOS, the settings are another tab
                SettingsView(commModel: tcpConnectionModel)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }.tag("Settings")
#endif
                
            }   // TabView
                .environmentObject(openlcblib)
                .onAppear() {
                    // start the connection once you have the display up to receive events
                    self.startup()   // this will only run once, sometimes .active occurs first
                }

        } // WindowGroup
        .onChange(of: scenePhase) { newPhase in
            
            switch (newPhase) {
            case .active:
                logger.debug("Scene Active")
                self.startup()  // this will only run once, sometimes onAppear occurs first
                tcpConnectionModel.start() // TODO: This is not invoked on native macOS, have to start via settings
            case .inactive:
                logger.debug("Scene Inactive")
            case .background:
                logger.debug("Scene Background")
                tcpConnectionModel.stop()
            @unknown default:
                logger.warning("Unexpected Scene phast enum")
            }
        }

#if os(macOS)
        // macOS has a separate "settings" window as Preferences
        Settings {  // creates a Preferences item in App menu
            SettingsView(commModel: tcpConnectionModel)
        }
#endif


    }
}

