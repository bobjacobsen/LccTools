//
//  PipView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

struct PipView: View {  // TODO: Put in own file, add useful stuff from node
    let displayNode : Node
    var body: some View {
        VStack {
            ForEach(PIP.contentsNames(displayNode.pipSet), id: \.description) { (pip) in
                Text(pip)  // contains pretty name of each member of the supported set // TODO: think about order
            }
        }.navigationTitle("Supported Protocols")
    }
}

struct PipView_Previews: PreviewProvider {
    static var previews: some View {
        PipView(displayNode: Node(NodeID(0)))
    }
}
