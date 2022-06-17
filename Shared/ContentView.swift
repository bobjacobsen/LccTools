//
//  ContentView.swift
//  OlcbLibDemo
//
//  Created by Bob Jacobsen on 6/10/22.
//

import SwiftUI
import os
import OpenlcbLibrary

struct ContentView: View {
    let openlcblib = OpenlcbLibrary()
    let canphysical = CanPhysicalLayerSimulation()
    
    init () {
        openlcblib.configureCanTelnet(canphysical)
        openlcblib.createSampleData()
        
        var tempnodes = openlcblib.remoteNodeStore.asArray()
        // sort most recent node content
        tempnodes.sort()
        nodes = tempnodes
        
        let logger = Logger(subsystem: "org.ardenwood.OlcbLibDemo", category: "ContentView")
        logger.error("\(tempnodes[0])")
     }

    @State private var nodes : [Node]

    var body: some View {
        NavigationView {
            ScrollView { // of all the nodes
                ForEach(nodes, id:\.id) { (node) in
                    // how to display each one when selected
                    NavigationLink(destination:
                                    FullNodeView(displayNode: node)
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
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
