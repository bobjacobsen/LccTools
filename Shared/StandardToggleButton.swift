//
//  StandardButtons.swift
//  OlcbTools
//
//  Created by Bob Jacobsen on 8/19/22.
//

import SwiftUI

public let STANDARD_BUTTON_CORNER_RADIUS    = 15.0

public let STANDARD_BUTTON_HEIGHT           = 35.0
public let SMALL_BUTTON_HEIGHT              = 25.0

public let STANDARD_BUTTON_FONT             = Font.title
public let SMALL_BUTTON_FONT                = Font.title2

// Button that toggles a state selected / not selected
struct StandardToggleButton: View {
    let label : String
    let height : CGFloat
    @Binding var select : Bool
    let action : () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(
            action: action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: STANDARD_BUTTON_CORNER_RADIUS)
                        .frame(height: height, alignment: .center)
                        .foregroundColor(
                            !isEnabled ? .gray : (
                            select ? .blue : .green)
                        )
                    
                    Text(label)
                        .font(STANDARD_BUTTON_FONT)
                        .foregroundColor(.white)
                }
            } // label
        ) // Button
    }
}

// Button that just goes down and up, calling an action
struct StandardMomentaryButton: View {
    let label : String
    let height : CGFloat
    let font : Font  // c.f. STANDARD_BUTTON_FONT, SMALL_BUTTON_FONT
    let action : () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(
            action: action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: STANDARD_BUTTON_CORNER_RADIUS)
                        .frame(height: height, alignment: .center)
                        .foregroundColor(isEnabled ? .green : .gray)
                    
                    Text(label)
                        .font(font)
                        .foregroundColor(.white)
                }
            } // label
        ) // Button
    }
}



struct StandardButton_Previews: PreviewProvider {
    @State static var forToggle = false
    static var previews: some View {

        VStack {
            StandardMomentaryButton(label: "Momentary", height: 50, font: .title){
                // on pressed
            }
            StandardMomentaryButton(label: "Momentary Disabled", height: 50, font: .title){
                // on pressed
            }.disabled(true)
            StandardToggleButton(label: "Toggle", height: 50, select: $forToggle){
                // on pressed
                forToggle = !forToggle
            }
            StandardToggleButton(label: "Toggle Disabled", height: 50, select: $forToggle){
                // on pressed
                forToggle = !forToggle
            }.disabled(true)
        }
    }
}
