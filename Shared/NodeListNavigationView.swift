//
//  NodeListNavigationView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary
import os

/// Display the list of known nodes, and provide address to `NodeSummaryView`.
/// Needs access to the OLCB network to retrieve the node list.
struct NodeListNavigationView: View {
    let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "NodeListNavigationView")
    
    @ObservedObject var network : OpenlcbNetwork
    
    var nodes : [Node] = []
    
    init (lib: OpenlcbNetwork) { // pass explicitly instead of relying on environment to avoid change loop
        self.network = lib
        nodes = lib.remoteNodeStore.nodes
        nodes.sort { $0.snip.userProvidedNodeName < $1.snip.userProvidedNodeName } // display in name order
        logger.info("init NodeListNavigationView")
    }

    var body: some View {
        // print(Self._printChanges())
        return NavigationView {
            List { // of all the nodes
                ForEach(nodes, id:\.id) { (node) in
                    // how to display each one when selected
                    NavigationLink(destination:
                                    NodeSummaryView(displayNode: node, network: network)
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
                            Divider()
                        }
                    }
                }
            }.navigationTitle("Remote Nodes")
             .listStyle(SidebarListStyle())
             .refreshable {
                 network.refreshAllNodes()
             }
            
            Text("No Selection")
        }
    }
}

struct NodeListNavigation_Previews: PreviewProvider {
    static let openlcblib = OpenlcbNetwork(sample: true)
    static var previews: some View {
        NodeListNavigationView(lib: openlcblib)
            .environmentObject(openlcblib)
    }
}
