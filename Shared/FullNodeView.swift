//
//  FullNodeView.swift
//  OlcbLibDemo
//
//  Created by Bob Jacobsen on 6/15/22.
//

import SwiftUI
import OpenlcbLibrary

struct FullNodeView: View {
    let displayNode : Node
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(displayNode.name).font(.headline)
            Text(displayNode.snip.userProvidedDescription)
            Text(displayNode.id.description) // nodeID
            HStack{

                NavigationLink(destination: MonitorView()) {
                    Image(systemName:"figure.stand.line.dotted.figure.stand") // TODO: better icon
                            .resizable().frame(width:50, height:50)
                }
                .navigationTitle("Node Summary")
 
                NavigationLink(destination: EventView()) {
                    Image(systemName:"cpu")
                            .resizable().frame(width:50, height:50)
                }.navigationTitle("Node WTF")
                
                NavigationLink(destination: ThrottleView()) {
                        Image(systemName:"train.side.front.car") // TODO: better icon
                            .resizable().frame(width:50, height:50)
                }
                
                NavigationLink(destination: CdCdiView()) {
                        Image(systemName:"square.and.pencil")
                            .resizable().frame(width:50, height:50)
                }
                
                NavigationLink(destination: PipView(displayNode: displayNode)) {
                    Image(systemName:"gear.badge.questionmark")
                            .resizable().frame(width:50, height:50)
                }
            }
            Text(displayNode.snip.modelName)
            Text(displayNode.snip.manufacturerName)
            Text("Hardware Version: \(displayNode.snip.hardwareVersion)\nSoftware Version: \(displayNode.snip.softwareVersion)")
        }
    }
}

struct FullNodeView_Previews: PreviewProvider {
    static let displayNode  = Node(NodeID(0))
    static var previews: some View {
        FullNodeView(displayNode: displayNode)// TODO: how do we fill this in better
            .previewInterfaceOrientation(.portraitUpsideDown)
    }
}
