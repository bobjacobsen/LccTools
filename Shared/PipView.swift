//
//  PipView.swift
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

/// Display the PIP info from a node in human-readable format.
struct PipView: View {
    
    var elements: [String]
    let displayNode: Node

    init(displayNode: Node) {
        self.displayNode = displayNode
        elements = Array(PIP.contentsNames(displayNode.pipSet))
        elements.sort() // put PIP contents in alphabetic order
    }
    
    var body: some View {
        VStack {
            ForEach(elements, id: \.description) { (pip) in
                Text(pip)  // contains pretty name of each member of the supported set
            }
        }.navigationTitle("\(displayNode.name) Supported Protocols")
    }
}

/// XCode preview for the PipView
struct PipView_Previews: PreviewProvider {
    static var previews: some View {
        PipView(displayNode: Node(NodeID(0),
                                  pip: Set([PIP.DATAGRAM_PROTOCOL,
                                            PIP.SIMPLE_NODE_IDENTIFICATION_PROTOCOL,
                                            PIP.EVENT_EXCHANGE_PROTOCOL])))
    }
}
