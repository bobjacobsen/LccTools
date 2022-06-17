//
//  FullNodeView.swift
//  OlcbLibDemo
//
//  Created by Bob Jacobsen on 6/15/22.
//

import SwiftUI
import OpenlcbLibrary

struct EventView: View {  // TODO: Put in own file, add useful stuff from traffic
    var body: some View {
        HStack {
            VStack {
                Text("Produces").font(.title).frame(alignment: .leading)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
            }
            Divider()
            VStack {
                Text("Consumes").font(.title).font(.title).frame(alignment: .leading)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
            }
        }
    }
}

struct MonitorView: View {  // TODO: Put in own file, add useful stuff from traffic
    var body: some View {
        Text("This is the Monitor detail view")
    }
}

struct ThrottleView: View {  // TODO: Put in own file, add useful stuff from throttle
    var body: some View {
        Text("This is the throttle detail view")
    }
}

struct CdCdiView: View {  // TODO: Put in own file, add useful stuff to configure
    var body: some View {
        Text("This is the configuration view")
    }
}

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
    static var previews: some View {
        FullNodeView(displayNode: Node(NodeID(0)))
            .previewInterfaceOrientation(.portraitUpsideDown) // TODO: how do we fill this in?
    }
}
