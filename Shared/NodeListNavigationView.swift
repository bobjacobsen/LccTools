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
    let logger = Logger(subsystem: "us.ardenwood.OlcbLibDemo", category: "NodeListNavigationView")
    
    let lib : OpenlcbLibrary
    
    var nodes : [Node] = []
    
    init (lib: OpenlcbLibrary) { // pass explicitly instead of relying on environment to avoid change loop
        self.lib = lib
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
                                    NodeSummaryView(displayNode: node, lib: lib)
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
    static let openlcblib = OpenlcbLibrary(sample: true)
    static var previews: some View {
        NodeListNavigationView(lib: openlcblib)
            .environmentObject(openlcblib)
    }
}
