//
//  FullNodeView.swift
//  OlcbLibDemo
//
//  Created by Bob Jacobsen on 6/15/22.
//

import SwiftUI
import OpenlcbLibrary

struct NodeSummaryView: View {
    let displayNode : Node
    
    var body: some View {

        // TODO: sort out iOS vs macOS here (and also matching bracket below)
//NavigationView { // needed on macOS to activate buttons; creates three column view; but re-pressing buttons still fails
        
        VStack(alignment: .leading) {
            Text(displayNode.name).font(.headline)
            Text(displayNode.snip.userProvidedDescription)
            Text(displayNode.id.description) // nodeID

            HStack{
                NavigationLink(destination: MonitorView()) {
                    Image(systemName:"figure.stand.line.dotted.figure.stand") // TODO: better icon
                            //.resizable().frame(width:50, height:50)
                }
 
                NavigationLink(destination: EventView()) {
                    Image(systemName:"cpu")
                            //.resizable().frame(width:50, height:50)
                }
                
                NavigationLink(destination: ThrottleView()) {
                        Image(systemName:"train.side.front.car") // TODO: better icon
                            //.resizable().frame(width:50, height:50)
                }
                
                NavigationLink(destination: CdCdiView()) {
                        Image(systemName:"square.and.pencil")
                            //.resizable().frame(width:50, height:50)
                }
                
                NavigationLink(destination: PipView(displayNode: displayNode)) {
                    Image(systemName:"gear.badge.questionmark")
                            //.resizable().frame(width:50, height:50)
                }
            }.frame(minHeight: 75)
            
            Text(displayNode.snip.modelName)
            Text(displayNode.snip.manufacturerName)
            Text("Hardware Version: \(displayNode.snip.hardwareVersion)\nSoftware Version: \(displayNode.snip.softwareVersion)")
        }
            
//}.navigationTitle("\(displayNode.name) Summary") // end of macOS-only Navigation view

            
    }
}

struct FullNodeView_Previews: PreviewProvider {
    static let displayNode  = Node(NodeID(0))
    static var previews: some View {
        NodeSummaryView(displayNode: displayNode)// TODO: how do we fill this in better
            .previewInterfaceOrientation(.portraitUpsideDown)
    }
}
