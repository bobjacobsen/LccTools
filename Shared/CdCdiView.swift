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

// decode each item (CdiXmlMemo node) and display for all types of nodes
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
    case .INPUT_INT :
        if (item.properties.count == 0 ) { // no map
            return AnyView(CdiIntView(item: item))
        } else {
            return AnyView(CdiIntMapView(item: item))
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

// view for an int value entry
struct CdiIntView : View {
    @State var intValue : Int = -1 // -1 so we can see what it does here
    
    var item : CdiXmlMemo
    init(item : CdiXmlMemo) {
        self.item = item
        print ("Int init starts")
    }
    
    var body : some View {
        VStack {
            TextField("Enter \(item.name)", value: $intValue,  formatter: NumberFormatter())
                .onAppear {
                    print ("Int appears with \($intValue) current: self.item.currentValue")
                    intValue = item.currentValue // TODO: dropped in debugging
                }
                .onSubmit {
                    print ("Int submits with \($intValue) current: self.item.currentValue")
                    item.currentValue = intValue  // TODO: do we need @ObservedObject for this? // TODO: dropped in debugging
                }
            if item.description != "" {
                Text(item.description).font(.footnote)
            }
        }
    }
}

// view for an int value map entry
struct CdiIntMapView : View {
    @State var intValue : Int = -1 // -1 so we can see what it does here
    
    var item : CdiXmlMemo
    init(item : CdiXmlMemo) {
        self.item = item
        print ("Int map init starts")
    }
    
    var body : some View {
        VStack {
            Text(item.name)

            Picker("\(item.name)", selection: $intValue) {
                ForEach(item.values, id: \.self) { valueName in
                    Text(valueName)
                }
            }
            // .pickerStyle(WheelPickerStyle())
            .pickerStyle(MenuPickerStyle())

            Text(item.description).font(.footnote)


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