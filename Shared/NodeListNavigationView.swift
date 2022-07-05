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
    init (openlcblib : OpenlcbLibrary) {
        var tempnodes = openlcblib.remoteNodeStore.asArray()
        // sort most recent node content
        tempnodes.sort()
        nodes = tempnodes
        
        let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "NodeListNavigationView")
        if (!tempnodes.isEmpty) {
            logger.info("Node[0] in view startup: \(tempnodes[0], privacy: .public)")
        } else {
            logger.info("No nodes at startup")
        }
     }

    @State private var nodes : [Node]

    var body: some View {
        NavigationView {
            List { // of all the nodes
                ForEach(nodes, id:\.id) { (node) in
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
        NodeListNavigationView(openlcblib: OpenlcbLibrary(defaultNodeID: NodeID("05.01.01.01.03.FF")))
    }
}
