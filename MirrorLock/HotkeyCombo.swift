import AppKit
import Carbon.HIToolbox

struct HotkeyCombo: Codable, Equatable, Hashable {
    var keyCode: UInt16
    var modifiers: UInt

    static let realModifierMask: CGEventFlags = [
        .maskCommand, .maskShift, .maskAlternate, .maskControl
    ]

    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers & NSEvent.ModifierFlags.command.rawValue != 0 { flags.insert(.maskCommand) }
        if modifiers & NSEvent.ModifierFlags.shift.rawValue != 0 { flags.insert(.maskShift) }
        if modifiers & NSEvent.ModifierFlags.option.rawValue != 0 { flags.insert(.maskAlternate) }
        if modifiers & NSEvent.ModifierFlags.control.rawValue != 0 { flags.insert(.maskControl) }
        return flags
    }

    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if modifiers & NSEvent.ModifierFlags.command.rawValue != 0 { result |= UInt32(cmdKey) }
        if modifiers & NSEvent.ModifierFlags.shift.rawValue != 0 { result |= UInt32(shiftKey) }
        if modifiers & NSEvent.ModifierFlags.option.rawValue != 0 { result |= UInt32(optionKey) }
        if modifiers & NSEvent.ModifierFlags.control.rawValue != 0 { result |= UInt32(controlKey) }
        return result
    }

    var displayString: String {
        var parts: [String] = []
        if modifiers & NSEvent.ModifierFlags.control.rawValue != 0 { parts.append("⌃") }
        if modifiers & NSEvent.ModifierFlags.option.rawValue != 0 { parts.append("⌥") }
        if modifiers & NSEvent.ModifierFlags.shift.rawValue != 0 { parts.append("⇧") }
        if modifiers & NSEvent.ModifierFlags.command.rawValue != 0 { parts.append("⌘") }
        parts.append(keyDisplayName)
        return parts.joined()
    }

    var keyDisplayName: String {
        switch keyCode {
        case UInt16(kVK_ANSI_A): return "A"
        case UInt16(kVK_ANSI_B): return "B"
        case UInt16(kVK_ANSI_C): return "C"
        case UInt16(kVK_ANSI_D): return "D"
        case UInt16(kVK_ANSI_E): return "E"
        case UInt16(kVK_ANSI_F): return "F"
        case UInt16(kVK_ANSI_G): return "G"
        case UInt16(kVK_ANSI_H): return "H"
        case UInt16(kVK_ANSI_I): return "I"
        case UInt16(kVK_ANSI_J): return "J"
        case UInt16(kVK_ANSI_K): return "K"
        case UInt16(kVK_ANSI_L): return "L"
        case UInt16(kVK_ANSI_M): return "M"
        case UInt16(kVK_ANSI_N): return "N"
        case UInt16(kVK_ANSI_O): return "O"
        case UInt16(kVK_ANSI_P): return "P"
        case UInt16(kVK_ANSI_Q): return "Q"
        case UInt16(kVK_ANSI_R): return "R"
        case UInt16(kVK_ANSI_S): return "S"
        case UInt16(kVK_ANSI_T): return "T"
        case UInt16(kVK_ANSI_U): return "U"
        case UInt16(kVK_ANSI_V): return "V"
        case UInt16(kVK_ANSI_W): return "W"
        case UInt16(kVK_ANSI_X): return "X"
        case UInt16(kVK_ANSI_Y): return "Y"
        case UInt16(kVK_ANSI_Z): return "Z"
        case UInt16(kVK_ANSI_0): return "0"
        case UInt16(kVK_ANSI_1): return "1"
        case UInt16(kVK_ANSI_2): return "2"
        case UInt16(kVK_ANSI_3): return "3"
        case UInt16(kVK_ANSI_4): return "4"
        case UInt16(kVK_ANSI_5): return "5"
        case UInt16(kVK_ANSI_6): return "6"
        case UInt16(kVK_ANSI_7): return "7"
        case UInt16(kVK_ANSI_8): return "8"
        case UInt16(kVK_ANSI_9): return "9"
        case UInt16(kVK_Space): return "Space"
        case UInt16(kVK_Return): return "Return"
        case UInt16(kVK_Escape): return "Esc"
        default: return "Key\(keyCode)"
        }
    }

    // Default presets
    static let activate = HotkeyCombo(keyCode: UInt16(kVK_ANSI_M), modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue)
    static let activateWardlume = HotkeyCombo(keyCode: UInt16(kVK_ANSI_L), modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue)
    static let activateOption = HotkeyCombo(keyCode: UInt16(kVK_ANSI_L), modifiers: NSEvent.ModifierFlags([.command, .option]).rawValue)

    static let unlock = HotkeyCombo(keyCode: UInt16(kVK_ANSI_U), modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue)

    static let emergencyExitDefault = HotkeyCombo(keyCode: UInt16(kVK_Escape), modifiers: NSEvent.ModifierFlags([.command, .option, .control]).rawValue)
    static let emergencyExitShiftE = HotkeyCombo(keyCode: UInt16(kVK_ANSI_E), modifiers: NSEvent.ModifierFlags([.command, .shift, .control]).rawValue)
}
