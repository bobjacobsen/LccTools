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
    @State private var node: Node? = nil // Nothing selected by default.
    
    var nodes: [Node] = []
    
    init (lib: OpenlcbNetwork) { // pass explicitly instead of relying on environment to avoid change loop
        self.network = lib
        nodes = lib.remoteNodeStore.nodes
        nodes.sort { $0.snip.userProvidedNodeName < $1.snip.userProvidedNodeName } // display in name order
        // TODO: consider using the same smart sort as RosterEntry
        NodeListNavigationView.logger.debug("init NodeListNavigationView")
    }

    var body: some View {
        NavigationSplitView {
            // left most column
            List {
                ForEach(nodes, id: \.self) { node in
                    NavigationLink(destination:
                                    NodeSummaryView(displayNode: node, network: network)
                    ) {
                        NodeRowView(node: node)
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
        } content: {
            // second nav section center
            if let node = node {
                NodeSummaryView(displayNode: node, network: network)
            } else {
                VStack {
                    Text("No Selection Yet.")
                    Text("Click in Upper Left.")
                }
            }
        } detail: {
            VStack { // third nav section - right most
                Text("No Selection Yet.")
                Text("Click A Button To Left.")
            }
        }
    }
}

// display a single row in the left-most selection
@ViewBuilder
func NodeRowView(node: Node) -> some View {
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

/// XCode preview for the NodeListNavigationView
struct NodeListNavigationView_Previews: PreviewProvider {
    static let openlcblib = OpenlcbNetwork(sample: true)
    static var previews: some View {
        NodeListNavigationView(lib: openlcblib)
            .environmentObject(openlcblib)
    }
}
