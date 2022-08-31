//
//  EventView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

struct EventView: View {  // TODO: Add specific node's view of events
    
    let displayNode : Node

    // TODO: Hook to EventStore in displayNode
    let produced : [EventID] = [EventID("01.02.03.04.05.06.07.08"),EventID("01.02.03.04.05.06.07.08"),EventID("01.02.03.04.05.06.07.08") ]
    let consumed : [EventID] = [EventID("01.02.03.04.05.06.07.08"),EventID("01.02.03.04.05.06.07.08"),EventID("01.02.03.04.05.06.07.08") ]
    
    var body: some View {
        HStack {
            List {
                Text("Produces").font(.title).font(.title).frame(alignment: .leading)
                ForEach(produced, id:\.eventID) { (event) in
                    EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                        .padding(.vertical, 0)
                }
                Text("     (This is sample data)  ").frame(alignment: .trailing)
            }
            Divider()
            List {
                Text("Consumes").font(.title).font(.title).frame(alignment: .leading)
                ForEach(produced, id:\.eventID) { (event) in
                    EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                        .padding(.vertical, 0)
                }
                Text("     (This is sample data)  ").frame(alignment: .trailing)
            }
        }.navigationTitle("Events") // TODO: This seems to be associated with the 2nd (RHS) List on the screen
    }
}

struct EventViewOneEvent : View {
    
    let eventID : EventID
    
    var body: some View {
        Button(action:{
            DispatchQueue.main.async{ // to avoid "publishing changes from within view updates is not allowed"
                // action on pressed
            }
            // TODO: is a momentary press down/up being recorded?
            // https://developer.apple.com/forums/thread/131715
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15.0)
                    .frame(alignment: .center)
                    .foregroundColor(.green)
                //
                
                Text("\(eventID.description)")
                    .font(.body)
                    .foregroundColor(.white)
            }
        }.padding(.vertical, 0)
    }
}

struct EventView_Previews: PreviewProvider {
    static let displayNode = Node(NodeID(12))
    static var previews: some View {
        EventView(displayNode : displayNode)
            //.previewInterfaceOrientation(.landscapeLeft)
    }
}
