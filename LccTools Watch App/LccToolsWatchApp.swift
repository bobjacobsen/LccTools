//
//  LccToolsApp.swift
//  LccTools Watch App
//
//  Created by Bob Jacobsen on 2/18/25.
//

import SwiftUI
import WatchConnectivity
import os

private let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "LccToolsWatchAppApp")

public class OurWCSessionDelegate: NSObject, WCSessionDelegate {
    var context: OurContext = OurContext()

    // Working method - gets initial context data
    public func session(_ session: WCSession,
                        activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        context.value = session.receivedApplicationContext
        logger.debug("activationDidCompleteWith with \(self.context.value)")
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Receiving messages sent without a reply handler
        logger.debug("didReceiveMessage with \(message)")
    }

    public func initializeWatchCommunications() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = OurWCSessionDelegate.default
            session.activate()
        } else {
            logger.error("This requires WCSession support, e.g. an associated iPhone")
        }
    }

    // create the default instance
    static public let `default`: OurWCSessionDelegate = OurWCSessionDelegate()
}
extension OurWCSessionDelegate {  // optional method requires presence in extension
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        context.value = session.receivedApplicationContext
        logger.debug("received context \(self.context.value)")
    }
}

class OurContext: ObservableObject {
    var value: [String: Any] = [:]
}

@main
struct LccToolsWatchApp: App {

    init() {
        // Trigger WCSession activation at the early phase of app launching.
        OurWCSessionDelegate.default.initializeWatchCommunications()
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
                // request first update from iOS app
                WCSession.default.sendMessage(["Please": "Update"], replyHandler: nil)
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
