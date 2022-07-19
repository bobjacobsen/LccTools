//
//  NodeListNavigationView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary
import os

struct NodeListNavigationView: View {
    let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "NodeListNavigationView")

    @EnvironmentObject var openlcblib : OpenlcbLibrary {
        didSet(oldvalue) {
            logger.info("published RemoteDataSort did change")
        }
    }
 
    init () {
        logger.info("init NodeListNavigationView")
    }

    var body: some View {
        let _ = Self._printChanges()  // TODO: remove before ship
        NavigationView {
            List { // of all the nodes
                ForEach(openlcblib.remoteNodeStore.nodes, id:\.id) { (node) in
                    // how to display each one when selected
                    NavigationLink(destination:
                                    NodeSummaryView(displayNode: node)
                    ){ // how to display each one in the list
                        VStack {
                            if node.name != "" {
                                Text(node.name)
                                Text(node.snip.userProvidedDescription).font(.footnote)
                                Text(node.id.description).font(.footnote)
                            } else {
                                Text(node.id.description)
                                Text(node.snip.userProvidedDescription).font(.footnote)
                            }
                        }
                    }
                }
            }.navigationTitle("Remote Nodes")
             .listStyle(SidebarListStyle())
            
            Text("No Selection")
        }
    }
}

struct NodeListNavigation_Previews: PreviewProvider {
    static var previews: some View {
        // TODO: this needs openlcblib: OpenlcbLibrary(sample: true) in the EnvironmentObject
        NodeListNavigationView()
    }
}
