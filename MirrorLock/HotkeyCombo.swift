import AppKit
import Carbon.HIToolbox

struct HotkeyCombo: Codable, Equatable {
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

    private var keyDisplayName: String {
        switch keyCode {
        case UInt16(kVK_ANSI_A): return "A"
        case UInt16(kVK_ANSI_L): return "L"
        case UInt16(kVK_ANSI_M): return "M"
        case UInt16(kVK_ANSI_U): return "U"
        case UInt16(kVK_ANSI_W): return "W"
        case UInt16(kVK_Escape): return "Esc"
        default: return "Key\(keyCode)"
        }
    }

    static let activate = HotkeyCombo(keyCode: UInt16(kVK_ANSI_M), modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue)
    static let unlock = HotkeyCombo(keyCode: UInt16(kVK_ANSI_U), modifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue)
}
