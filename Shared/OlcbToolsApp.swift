//
//  OlcbToolsApp.swift
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
    @AppStorage("HUB_SERVICE")    private var selectedHubAddress = ModelPeerBrowserDelegate.PeerBrowserDelegateNoHubSelected
    @AppStorage("HUB_IP_ADDRESS") private var ip_address: String = ""
    @AppStorage("HUB_IP_PORT") private var ip_port: String = "12021"
    @AppStorage("THIS_NODE_ID") static private var this_node_ID: String = ""  // static for static openlcnlib

    @StateObject var openlcblib = OpenlcbNetwork(localNodeID: NodeID(this_node_ID))
    
    @Environment(\.scenePhase) var scenePhase  // for .background, etc
        
    @StateObject var tcpConnectionModel = TcpConnectionModel()
    
    private let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "OlcbToolsApp")
    
    static var doneStartup = false  // static to avoid "self is immutable" issue

    // create a NodeID using random numbers for low 20 bits and an allocated top 28 bits
    static internal func selectThisNodeID() -> String {
        let intGroup0 = Int.random(in: 2...253) // range to avoid obvious end points
        let intGroup1 = Int.random(in: 2...253) // range to avoid obvious end points
        let intGroup2 = Int.random(in: 0...15)  // range to avoid obvious end points

        let group0 = String(format: "%02X", intGroup0)
        let group1 = String(format: "%02X", intGroup1)
        let group2 = String(format: "%1X", intGroup2)

        return "02.02.04.0\(group2).\(group1).\(group0)"
    }
    
    /// Only logging at creation time, see `startup()` for configuration
    init () {
        // log some info at creation time
        let temp_this_service = selectedHubAddress   // avoid "capture of mutating self" compile error
        logger.info("at startup, this program's default service is set to: \(temp_this_service)")
        let temp_this_node_ID = OlcbToolsApp.this_node_ID   // avoid "capture of mutating self" compile error
        logger.info("at startup, this program's default node ID is set to: \(temp_this_node_ID)")
        let temp_hub_ip_address = self.ip_address   // avoid "capture of mutating self" compile error
        logger.info("at startup, default hub IP address is set to: \(temp_hub_ip_address)")
        let temp_hub_ip_port = self.ip_port   // avoid "capture of mutating self" compile error
        logger.info("at startup, default hub port is set to: \(temp_hub_ip_port)")
        
        if OlcbToolsApp.this_node_ID.isEmpty {
            OlcbToolsApp.this_node_ID = OlcbToolsApp.selectThisNodeID()
            logger.info("  updated default node id to \(OlcbToolsApp.this_node_ID)")
        }
    }
    
    var canphysical = CanPhysicalLayerGridConnect()
    
    /// Configure the various libraries and connections, then start the network access
    func startup() {
        // only do once
        guard !OlcbToolsApp.doneStartup else { return }
        OlcbToolsApp.doneStartup = true
        
        // if there's no host name, show settings
        // This only works for iOS.  macOS has a separate preferences screen, shown in onAppear below.
        if self.ip_address.isEmpty && self.selectedHubAddress == ModelPeerBrowserDelegate.PeerBrowserDelegateNoHubSelected {
            self.selectedTab = "Settings"
        }
        
        // create, but not yet connect, the Telnet connection to the hub (connection done on transition to Active state below)
        let port = UInt16(self.ip_port) ?? 12021
        tcpConnectionModel.load(serviceName: selectedHubAddress, hostName: self.ip_address,
                                portNumber: port, receivedDataCallback: canphysical.receiveString,
                                startUpCallback: startUpCallback, restartCallback: restartCallback)
        
        // configure the OLCB processor -> telnet link
        canphysical.setCallBack(callback: tcpConnectionModel.send(string:))
        
        openlcblib.configureCanTelnet(canphysical)
        
        // OlcbToolsApp.openlcblib.createSampleData()  // commented out when real hardware is available and connected
        
    }
    
    /// Connection call back when link goes to 'ready' for first time, starts OpenLCB processing.
    /// Note this is _only_ for the first time the link comes up.
    private func startUpCallback() {
        // start the OLCB layer
        logger.debug("starting OpenLCB layer")
        canphysical.physicalLayerUp()
    }

    /// Connection call back when link goes to 'ready' after the first time. Restarts OpenLCB processing.
    /// Note this is _only_ after the first time the link comes up.
    private func restartCallback() {
        // restart the OLCB layer
        logger.debug("restarting OpenLCB layer")
        canphysical.physicalLayerRestart()
    }

    let persistenceController = PersistenceController.shared

    @State private var selectedTab: String = "Throttle"
    
    var body: some Scene {
        // iOS on early/small iPhone has four spots available in the navigation bar at the bottom
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
                        Label("Clock", systemImage: "timer")
                    }.tag("Clock")
              
                TurnoutView(network: openlcblib)
                    .tabItem {
                        Label("Turnouts", systemImage: "arrow.triangle.branch")
                    }.tag("Turnouts")
                
                // This has wierd nav issues if it comes from "More..." so keep it above that
                NodeListNavigationView(lib: openlcblib)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Nodes", systemImage: "app.connected.to.app.below.fill")
                    }.tag("NodeListNavigation")
                    .environmentObject(openlcblib)

                // iPhone 12 goes to "More..." at this point
                
                ConsistView(consistModel: openlcblib.consistModel0, selectionModel: openlcblib.throttleModel0)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Consists", systemImage: "forward")
                    }.tag("Consist")
                
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
                .onAppear {
                    logger.debug("onAppear happens")
                    // start the connection once you have the display up to receive events
                    self.startup()   // this will only run once, sometimes .active occurs first
                    tcpConnectionModel.start()
                    
#if os(macOS)
                    // if no connection info, show the Preference (nee Settings) pane
                    if self.ip_address.isEmpty && self.selectedHubAddress == ModelPeerBrowserDelegate.PeerBrowserDelegateNoHubSelected {
                        // delay a bit in hopes of putting this in front
                        let deadlineTime = DispatchTime.now() + .milliseconds(500)
                        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                        }
                    }
#endif
                }

        } // WindowGroup
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // Scene does not change on macOS
                logger.debug("Scene Active")
                self.startup()  // this will only run once, sometimes onAppear occurs first
                tcpConnectionModel.start()
#if os(iOS)
                // Disable idle timer to keep app from going to sleep and missing requests
                // In iOS 13+, idle timer needs to be set in scene to override default
                UIApplication.shared.isIdleTimerDisabled = true
#endif
            case .inactive:
                logger.debug("Scene Inactive")
                openlcblib.appInactive()
            case .background:
                logger.debug("Scene Background")
                tcpConnectionModel.stop()
            @unknown default:
                logger.warning("Unexpected Scene phase enum")
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
