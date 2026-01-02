//
//  NodeListNavigationView.swift
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary
import os

/// Display the list of known nodes, and provide address to `NodeSummaryView`.
/// 
/// Needs access to the OLCB network to retrieve the node list.
struct NodeListNavigationView: View {
    private static let logger = Logger(subsystem: "us.ardenwood.OlcbTools", category: "NodeListNavigationView")
    
    @ObservedObject var network: OpenlcbNetwork
    
    var nodes: [Node] = []
    
    init (lib: OpenlcbNetwork) { // pass explicitly instead of relying on environment to avoid change loop
        self.network = lib
        nodes = lib.remoteNodeStore.nodes
        nodes.sort { $0.snip.userProvidedNodeName < $1.snip.userProvidedNodeName } // display in name order
        // TODO: consider using the same smart sort as RosterEntry
        NodeListNavigationView.logger.info("init NodeListNavigationView")
    }

    var body: some View {
        return NavigationView {
            List { // of all the nodes
                ForEach(nodes, id: \.id) { (node) in
                    // how to display each one when selected
                    NavigationLink(destination:
                                    NodeSummaryView(displayNode: node, network: network)
                    ) { // how to display each one in the list
                        VStack {
                            if !node.name.isEmpty {
                                Text(node.name)
                                if !node.snip.userProvidedDescription.isEmpty {
                                    Text(node.snip.userProvidedDescription).font(.footnote)
                                }
                                Text(node.id.description).font(.footnote)
                            } else if !node.snip.userProvidedDescription.isEmpty {
                                Text(node.snip.userProvidedDescription)
                                Text(node.id.description).font(.footnote)
                            } else if !node.snip.modelName.isEmpty {
                                Text(node.snip.modelName)
                                Text(node.id.description).font(.footnote)
                            } else {
                                Text(node.id.description)
                            }
#if os(macOS)
                            Divider()  // divider not needed on iOS
#endif
                        }
                    }
                }
#if os(macOS)
                HStack {
                    Spacer()
                    Button("Refresh") {
                        network.refreshAllNodes()
                    }
                    Spacer()
                }
#endif
            }.navigationTitle("Remote Nodes")
                .listStyle(SidebarListStyle())
                .refreshable {
                    network.refreshAllNodes()
                }
            
            VStack { // second nav section center
                Text("No Selection Yet.")
                Text("Click in Upper Left.")
            }
            
            VStack { // third nav section - right most
                Text("No Selection Yet.")
                Text("Click in Upper Left.")
            }
        }
    }
}

/// XCode preview for the NodeListNavigationView
struct NodeListNavigationView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbNetwork(sample: true)
    static var previews: some View {
        NodeListNavigationView(lib: openlcblib)
            .environmentObject(openlcblib)
    }
}
