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
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
