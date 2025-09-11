//
//  TurnoutView.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 10/3/22.
//

import OpenlcbLibrary
import SwiftUI

/// Show and allow control of  DCC turnouts.
struct TurnoutView: View {
    @State var dccAddressInt: Int = 1
    @State var macroAddress: Int = 1
    @ObservedObject var model: TurnoutModel
    var turnoutformatter = NumberFormatter()
    var macroformatter = NumberFormatter()
    @State private var showingDefineSheet: Bool = false
    
    @AppStorage("CUSTOM_TURNOUTS") private var turnoutStorageData: Data = Data()
    
    init(network: OpenlcbNetwork) {
        turnoutformatter.minimum = 1
        turnoutformatter.maximum = 2040
        turnoutformatter.maximumFractionDigits = 0
        macroformatter.minimum = 1
        macroformatter.maximum = 65535
        macroformatter.maximumFractionDigits = 0
        model = network.turnoutModel0
        
        loadAndDecodeTurnoutDefinitions()
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Enter Turnout Number (1-2040):")
                TextField("Number", value: $dccAddressInt, formatter: turnoutformatter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Spacer()
            }
            HStack {
                StandardClickButton(label: "Throw", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    model.setThrown(TurnoutDefinition(dccAddressInt))
                    encodeAndStoreTurnoutDefinitions(newContents: model.turnoutDefinitionArray)
                }
                StandardClickButton(label: "Close", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    model.setClosed(TurnoutDefinition(dccAddressInt))
                    encodeAndStoreTurnoutDefinitions(newContents: model.turnoutDefinitionArray)
                }
            }
            
            StandardHDivider()
            
            // list of previous items
            List {
                ForEach(model.turnoutDefinitionArray, id: \.self) { item in
                    HStack {
                        Spacer()
                        Text("\(String(item.visibleAddress))")
                        StandardClickButton(label: "T", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setThrown(item)
                        }.frame(width: 60)
                        StandardClickButton(label: "C", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setClosed(item)
                        }.frame(width: 80)
                    }
                }.onDelete(perform: deleteTurnoutDefinition)
            }
            
            StandardClickButton(label: "Define Custom Turnout", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                showingDefineSheet = true
            }
            .sheet(isPresented: $showingDefineSheet) {  // show selection in a cover sheet
                TurnoutDefinitionView(parentModel: model) // shows definition sheet
                // .presentationDetents([.fraction(0.25)]) // iOS16 feature
            }
            
            StandardHDivider()
            
            HStack {
                Spacer()
                Text("Enter Macro Number (1-65535):")
                TextField("Number", value: $macroAddress, formatter: macroformatter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Spacer()
            }
            Spacer()
            HStack {
                StandardClickButton(label: "Set", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                    model.setMacro(macroAddress)
                }
            }
            
            StandardHDivider()
            
            // list of previous items
            List {
                ForEach(model.macroArray, id: \.self) { item in
                    HStack {
                        Spacer()
                        Text("\(String(item))")
                        StandardClickButton(label: "S", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT) {
                            model.setThrown(item)
                        }.frame(width: 60)
                    }
                }
            }
        }
    }

    func deleteTurnoutDefinition(at offsets: IndexSet) {
        model.deleteAtOffsets(offsets)
        // need to encode and store here
        encodeAndStoreTurnoutDefinitions(newContents: model.turnoutDefinitionArray)
    }
    
    func loadAndDecodeTurnoutDefinitions( ) {
        // unpack the stored turnout definition values
        let decodedData = try? JSONSerialization.jsonObject(with: turnoutStorageData, options: [])
                
        if let turnoutDataArray = decodedData as? [NSDictionary] {
            for oneTurnoutDataDictionary in turnoutDataArray {
                
                let closedEventItem = oneTurnoutDataDictionary["closedEventID"]
                if let closedEventItem = closedEventItem as? NSDictionary {
                    if let closedEventID = closedEventItem["eventID"] as? UInt64 {

                        let thrownEventItem = oneTurnoutDataDictionary["thrownEventID"]
                        if let thrownEventItem = thrownEventItem as? NSDictionary {
                            if let thrownEventID = thrownEventItem["eventID"] as? UInt64 {
                                
                                let visibleAddress  = oneTurnoutDataDictionary["visibleAddress"]
                                if let visibleAddress  = visibleAddress as? String {
                                    
                                    // have successfully decoded item!
                                    let nextTurnoutDefinition = TurnoutDefinition(visibleAddress,
                                                                                  EventID(closedEventID),
                                                                                  EventID(thrownEventID))
                                    DispatchQueue.main.async {
                                        // store if changed
                                        model.processTurnoutDefinition(nextTurnoutDefinition)
                                    }

                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // This is defined twice, should be refactored
    func encodeAndStoreTurnoutDefinitions(newContents: [TurnoutDefinition] ) {
        // update the storage
        let newDataString = try? JSONEncoder().encode(newContents)
        if let newDataString = newDataString {
            turnoutStorageData = newDataString
        }
    }

    /// Cover sheet for defining a "turnout" with non-standard events
    struct TurnoutDefinitionView: View {
        @Environment(\.dismiss) var dismiss
        
        let model: TurnoutModel
        
        @State var name  = ""
        @State var closedEvent  = ""
        @State var thrownEvent  = ""
        
        @AppStorage("CUSTOM_TURNOUTS") private var turnoutStorageData: Data = Data()
        
        init(parentModel: TurnoutModel) {
            model = parentModel
        }
        
        var body: some View {
            VStack {
                Text("Define Custom Turnout")
                    .font(.largeTitle)
                
                TextField("Enter name", text: $name)
                    .font(.title)
                    .fixedSize()  // limit size to something reasonable
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation) // keyboards not used on macOS
#endif
                
                TextField("Enter EventID for Closed", text: $closedEvent)
                    .font(.title)
                    .fixedSize()  // limit size to something reasonable
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation) // keyboards not used on macOS
#endif
                
                TextField("Enter EventID for Thrown", text: $thrownEvent)
                    .font(.title)
                    .fixedSize()  // limit size to something reasonable
#if os(iOS)
                    .keyboardType(.numbersAndPunctuation) // keyboards not used on macOS
#endif
                
                StandardClickButton(label: "Define", font: SMALL_BUTTON_FONT) {
                    // use entered data to create a TurnoutDefinition and store it
                    let newDefinition = TurnoutDefinition(name, EventID(closedEvent), EventID(thrownEvent))
                    model.processTurnoutDefinition(newDefinition)
                    encodeAndStoreTurnoutDefinitions()
                }
                
#if targetEnvironment(macCatalyst) || os(macOS)
                StandardHDivider()
                StandardClickButton(label: "Dismiss", font: SMALL_BUTTON_FONT) {
                    dismiss()
                }
#else
                Text("Swipe down to close")
#endif
            }
        }
        
        // This is defined twice, should be refactored
        func encodeAndStoreTurnoutDefinitions( ) {
            // update the storage
            let newDataString = try? JSONEncoder().encode(model.turnoutDefinitionArray)
            if let newDataString = newDataString {
                turnoutStorageData = newDataString
            }
        }
    }
}

/// XCode preview for the TurnoutView
struct TurnoutView_Previews: PreviewProvider {
    static var previews: some View {
        TurnoutView(network: OpenlcbNetwork(sample: true))
    }
}
