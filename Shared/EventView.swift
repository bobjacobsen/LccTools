//
//  EventView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

struct EventView: View {  // TODO: Add specific node's view of events
    var body: some View {
        HStack {
            VStack {
                Text("Produces").font(.title).frame(alignment: .leading)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     (This is sample data)  ").frame(alignment: .trailing)
            }
            Divider()
            VStack {
                Text("Consumes").font(.title).font(.title).frame(alignment: .leading)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     01.02.03.04.05.06.07.08").frame(alignment: .trailing)
                Text("     (This is sample data)  ").frame(alignment: .trailing)
            }
        }.navigationTitle("Events")
    }
}

struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        EventView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
