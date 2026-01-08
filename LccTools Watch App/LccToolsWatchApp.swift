//
//  LccToolsApp.swift
//  LccTools Watch App
//
//  Created by Bob Jacobsen on 2/18/25.
//

import SwiftUI
import WatchConnectivity
import os

private let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "LccToolsWatchAppApp")

public class ExtendedWCSessionDelegate: NSObject, WCSessionDelegate {
    private let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "ExtendedWCSessionDelegate")

    var context: WatchContext = WatchContext()

    // Working method - gets initial context data
    public func session(_ session: WCSession,
                        activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        context.value = session.receivedApplicationContext
        logger.debug("activationDidCompleteWith with \(self.context.value)")
    }

    // We don't use this right now, as we only transfer context
    // Should this be in the extension?
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Receiving messages sent without a reply handler
        logger.debug("didReceiveMessage with \(message)")
    }

    public func initializeWatchCommunications() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = ExtendedWCSessionDelegate.default
            session.activate()
        } else {
            logger.error("This requires WCSession support, e.g. an running with an iPhone")
        }
    }

    // create the default instance
    static public let `default`: ExtendedWCSessionDelegate = ExtendedWCSessionDelegate()
}
extension ExtendedWCSessionDelegate {  // optional method requires presence in extension
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        context.value = session.receivedApplicationContext
        logger.debug("received context \(self.context.value)")
    }
}

class WatchContext: ObservableObject { // need to make an Observable out of a dictionary
    var value: [String: Any] = [:]
}

@main
struct LccToolsWatchApp: App {

    init() {
        // Trigger WCSession activation at the early phase of app launching.
        ExtendedWCSessionDelegate.default.initializeWatchCommunications()
    }

    @Environment(\.scenePhase) var scenePhase  // for .background, etc

    @StateObject var globalClockModel: WatchClockModel = WatchClockModel()

    // Define the main WindowGroup (just one Window)
    var body: some Scene {
        WindowGroup {
            // Just one view - all we show is the clock
            WatchClockView(clockModel: globalClockModel)
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                logger.debug("Scene Active")
                globalClockModel.startUpdates()
            case .inactive:
                logger.debug("Scene Inactive")
                globalClockModel.cancelUpdates()
            case .background:
                logger.debug("Scene Background")
                globalClockModel.cancelUpdates()
            @unknown default:
                logger.warning("Unexpected Scene phase enum")
            }
        }
    }
}
