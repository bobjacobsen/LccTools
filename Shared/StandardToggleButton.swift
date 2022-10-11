//
//  StandardButtons.swift
//
//  Created by Bob Jacobsen on 8/19/22.
//

import SwiftUI

public let STANDARD_BUTTON_CORNER_RADIUS    = 15.0

public let STANDARD_BUTTON_HEIGHT           = 35.0
public let SMALL_BUTTON_HEIGHT              = 25.0

public let STANDARD_BUTTON_FONT             = Font.title    // make this numeric to match HEIGHT?
public let SMALL_BUTTON_FONT                = Font.title2   // make this numeric to match HEIGHT?

/// Button that toggles a state selected / not selected
struct StandardToggleButton: View {
    let label : String
    let height : CGFloat
    let font : Font = STANDARD_BUTTON_FONT
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
                        .font(height >= (STANDARD_BUTTON_HEIGHT+SMALL_BUTTON_HEIGHT)/2 ? STANDARD_BUTTON_FONT : SMALL_BUTTON_FONT)
                        .foregroundColor(.white)
                }
            } // label
        ) // Button
        .buttonStyle(.borderless)  // for macOS
    }
}

/// Button that just goes down and up, calling an action
// TODO: This doesn't _show_ the click on macOS (you can't see that you clicked it) - see Event and Turnout displays. Does show the down/up on iOS OK.
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
                        .frame(height: height, alignment: .center)
                }
            } // label
        ) // Button
        .buttonStyle(.borderless)  // for macOS
    }
}

/// This centralizes horizontal dividers.
struct StandardHDivider : View {
    var body : some View {
        Divider()
            .frame(height: 1)
            .overlay(.gray)
    }
}


struct StandardButton_Previews: PreviewProvider {
    @State static var forToggle = false
    static var previews: some View {

        VStack {
            StandardMomentaryButton(label: "Momentary", height: STANDARD_BUTTON_HEIGHT, font: STANDARD_BUTTON_FONT){
                // on pressed
            }
            StandardMomentaryButton(label: "Momentary Disabled", height: STANDARD_BUTTON_HEIGHT, font: STANDARD_BUTTON_FONT){
                // on pressed
            }.disabled(true)
            StandardToggleButton(label: "Toggle", height: STANDARD_BUTTON_HEIGHT, select: $forToggle){
                // on pressed
                forToggle = !forToggle
            }
            StandardToggleButton(label: "Toggle Disabled", height: STANDARD_BUTTON_HEIGHT, select: $forToggle){
                // on pressed
                forToggle = !forToggle
            }.disabled(true)
            StandardMomentaryButton(label: "Small Momentary", height: SMALL_BUTTON_HEIGHT, font: SMALL_BUTTON_FONT){
                // on pressed
            }
            StandardToggleButton(label: "Small Toggle", height: SMALL_BUTTON_HEIGHT, select: $forToggle){
                // on pressed
                forToggle = !forToggle
            }
        }
    }
}
