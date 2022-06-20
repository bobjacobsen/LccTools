//
//  CdCdiView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 6/17/22.
//

import SwiftUI
import OpenlcbLibrary

struct CdCdiView: View {

    #if DEBUG
    let data = sampleCdiXmlData()
    #endif
    
    var body: some View {
            List(data, children: \.children) { row in  // "children" makes the nested list
                containedView(item: row)
            }.padding(10)
    }
}

// decode each item (CdiXmlMemo node) and display
func containedView(item : CdiXmlMemo) -> AnyView {
    switch item.type {
    case .SEGMENT :
        if item.description != "" {
             return AnyView(VStack {
                Text(item.name).font(.title)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name).font(.title))
        }
    case .GROUP :
        if item.description != "" {
            return AnyView(VStack {
                Text(item.name).font(.title2)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name).font(.title2))
        }
    default :
        if item.description != "" {
            return AnyView(VStack {
                Text(item.name)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name))
        }
    }
}

// custom for data entry fields
struct EntryView : View {
    init(text: String) {
        entryText = text
    }
    @State private var entryText : String
    
    var body: some View {
        HStack {
            Text("Enter: ")
            TextField(entryText, text : $entryText)
        }
    }
}

struct CdCdiView_Previews: PreviewProvider {
    static var previews: some View {
        CdCdiView()
    }
}
