//
//  IdentView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 1/22/24.
//

import SwiftUI
import OpenlcbLibrary

struct IdentView: View {
    let displayNode: Node
    let network: OpenlcbNetwork

    init(network: OpenlcbNetwork, displayNode: Node) {
        self.displayNode = displayNode
        self.network = network
    }
    
    var body: some View {
        StandardClickButton(label: "Identify", height: STANDARD_BUTTON_HEIGHT*2, font: STANDARD_BUTTON_FONT) {
            ident()
        }
    }
    
    func ident() {
        network.identify(node: displayNode)
    }
}

/// XCode preview for the PipView
struct IdentView_Previews: PreviewProvider {
    static var previews: some View {
        let olcblibrary = OpenlcbNetwork(localNodeID: NodeID(258))
        IdentView(network: olcblibrary, displayNode: Node(NodeID(258)) )
    }
}
