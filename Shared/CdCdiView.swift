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
    static let data = CdiSampleDataAccess.sampleCdiXmlData()[0].children! // start with Segment elements
    #endif
    
    var body: some View {
        List(CdCdiView.data, children: \.children) { row in  // "children" makes the nested list
            containedView(item: row)
        }.padding(10).navigationTitle("Node Configuration")
    }
}

// decode each item (CdiXmlMemo node) and display for all types of nodes
func containedView(item : CdiXmlMemo) -> AnyView {
    switch item.type {
    case .SEGMENT :
        if item.description != "" {
             return AnyView(VStack(alignment: .leading) {
                Text(item.name).font(.title)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name).font(.title))
        }
    case .GROUP :
        if item.description != "" {
            return AnyView(VStack(alignment: .leading) {
                Text(item.name).font(.title2)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name).font(.title2))
        }
    case .INPUT_EVENTID :
        if (item.properties.count == 0 ) { // no map
            return AnyView(CdiEventView(item: item))
        } else {
            return AnyView(CdiEventView(item: item)) // TODO: add CdiEventMapView here
        }
    case .INPUT_INT :
        if (item.properties.count == 0 ) { // no map
            return AnyView(CdiIntView(item: item))
        } else {
            return AnyView(CdiIntMapView(item: item))
        }
    default :
        if item.description != "" {
            return AnyView(VStack(alignment: .leading) {
                Text(item.name)
                Text(item.description).font(.footnote)
            })
        } else {
            return AnyView(Text(item.name))
        }
    }
}

// view for an eventID value entry
struct CdiEventView : View {
    @State var eventValue : String = "00.00.00.00.00.00.00.00" // TODO:  initial value vs read?
    var item : CdiXmlMemo
    init(item : CdiXmlMemo) {
        self.item = item
        print ("Int init starts")
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(item.name) ") // display name next to value
                
                TextField("Enter \(item.name)", text: $eventValue) // TODO: needs custom formatter
                    .onAppear {
                        print ("EventID appears with \(eventValue) current: \(self.item.currentIntValue)")
                        eventValue = item.currentStringValue
                    }
                    .onSubmit {
                        print ("EventID submits with \(eventValue) prior current: \(self.item.currentIntValue)")
                        item.currentStringValue = eventValue  // TODO: capture this to do a write
                    }
            }
            if item.description != "" {
                Text(item.description).font(.footnote)

                // Text("Debug: eventValue is \(eventValue)").font(.footnote)    // TODO: rm Debug output
                // Text("Debug: currentValue is \(item.currentValue)").font(.footnote) // TODO: rm Debug output
            }
        }
    }
}

// view for an int value entry
struct CdiIntView : View {
    @State var intValue : Int = -1 // -1 so we can see what it does here
    var formatter = NumberFormatter()
    var item : CdiXmlMemo
    init(item : CdiXmlMemo) {
        self.item = item
        formatter.minimum = NSNumber(integerLiteral: item.minValue)
        formatter.maximum = NSNumber(integerLiteral: item.maxValue)
        formatter.maximumFractionDigits = 0
        print ("Int init starts")
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(item.name) ") // display name next to value
                
                TextField("Enter \(item.name)", value: $intValue,  formatter: formatter)
                    .onAppear {
                        print ("Int appears with \(intValue) current: \(self.item.currentIntValue)")
                        intValue = item.currentIntValue
                    }
                    .onSubmit {
                        print ("Int submits with \(intValue) prior current: \(self.item.currentIntValue)")
                        item.currentIntValue = intValue  // TODO: capture this to do a write
                    }
            }
            if item.description != "" {
                Text(item.description).font(.footnote)

                // Text("Debug: intValue is \(intValue)").font(.footnote)    // TODO: rm Debug output
                // Text("Debug: currentValue is \(item.currentValue)").font(.footnote) // TODO: rm Debug output
            }
        }
    }
}

// view for an int value map entry
struct CdiIntMapView : View {
    @State var intValue : Int = -1 // -1 so we can see what it does here
    @State var stringValue : String = "<initial internal content>" // so we can see what it does here

    var item : CdiXmlMemo
    var startUpIgnoreReceive = true // true while onReceive should be ignored untiul first onAppear
    
    init(item : CdiXmlMemo) {
        self.item = item
        print ("Int map init starts \(self.item.defaultValue) \(self.item.currentIntValue)")
        intValue = item.currentIntValue
        stringValue = propertyToValue(property: intValue)
        print (" Int map init done with stringValue is \(stringValue)")
    }
    
    func valueToProperty(value : String ) -> Int {
        // find index of matching value
        let index = self.item.values.firstIndex(of: value) ?? 0  // really supposed to match
        return Int(self.item.properties[index]) ?? 0 // 0 if process fails
    }
    func propertyToValue(property : Int ) -> String {
        // find index of matching property
        let index = self.item.properties.firstIndex(of: String(property)) ?? 0  // really supposed to match
        return self.item.values[index]
   }

    var body : some View {
        VStack(alignment: .leading) {
            Picker("\(item.name)", selection: $stringValue) {
                ForEach(item.values, id: \.self) { valueName in
                    Text(valueName)
                }
            } // default is no picker style, see https://developer.apple.com/documentation/swiftui/pickerstyle
            //.pickerStyle(WheelPickerStyle())
            //.pickerStyle(MenuPickerStyle())  // TODO: This seems to be causing a hard crash
            .onAppear { // initialize from model value
                print ("IntMap appears with \(intValue) \(stringValue) current: \(self.item.currentIntValue)")
                print ("   int \(item.currentIntValue) maps to \(propertyToValue(property: item.currentIntValue))")
                intValue = item.currentIntValue
                stringValue = propertyToValue(property: intValue)
            }
            .onReceive([self.stringValue].publisher.first()) { (value) in  // store back to model
                print ("onReceive with \(value)")
                print ("    start with \(intValue) \(stringValue) current: \(self.item.currentIntValue)")
                print ("    string maps to \(valueToProperty(value: stringValue))")
                if (stringValue == "<initial internal content>") {
                    print ("  and returning initially")
                    return
                }
                intValue = valueToProperty(value: stringValue)
                item.currentIntValue = intValue  // TODO: do we need @ObservedObject for this?
           }
            Text(item.description).font(.footnote)
            //Text("Debug: intValue is \(intValue)").font(.footnote)    // TODO: rm Debug output
            //Text("Debug: stringValue is \(stringValue)").font(.footnote) // TODO: rm Debug output
            //Text("Debug: currentValue is \(item.currentValue)").font(.footnote) // TODO: rm Debug output


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
