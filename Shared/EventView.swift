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
    let produced : [EventID] = [EventID("01.02.03.04.05.06.07.08"),EventID("01.02.03.04.05.06.07.10"),EventID("01.02.03.04.05.06.07.12") ]
    let consumed : [EventID] = [EventID("01.02.03.04.05.06.07.08"),EventID("01.02.03.04.05.06.07.10"),EventID("01.02.03.04.05.06.07.12") ]
    
    var body: some View {
        HStack {
            // TODO: Work on left/right margins to make a bit more space in portrait
            List {
                Text("Produces").font(.title).font(.title).frame(alignment: .leading)
                ForEach(produced, id:\.eventID) { (event) in
                    EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                        .padding(.vertical, 0)
                }.listRowSeparator(.hidden)
                Text("     (This is sample data)  ").frame(alignment: .trailing)
            }
            Divider()
            List {
                Text("Consumes").font(.title).font(.title).frame(alignment: .leading)
                ForEach(produced, id:\.eventID) { (event) in
                    EventViewOneEvent(eventID: event).frame(alignment: .trailing)
                        .padding(.vertical, 0)
                }.listRowSeparator(.hidden)
                Text("     (This is sample data)  ").frame(alignment: .trailing)
            }
        }.navigationTitle("Events") // TODO: This seems to be associated with the 2nd (RHS) List on the screen, not even across the screen
    }
}

struct EventViewOneEvent : View {
    
    let eventID : EventID
    
    var body: some View {
        Button(action:{
            DispatchQueue.main.async{ // to avoid "publishing changes from within view updates is not allowed"
                // TODO: action on pressed - runs through the model
            }
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
