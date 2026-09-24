import AppKit
import Testing

struct AssignableSymbolsTests {
    @Test
    func everySymbolResolves() {
        // Arrange
        let symbols = AssignableSymbols.groups.flatMap(\.self)

        // Act
        let unresolved = symbols.filter { NSImage(systemSymbolName: $0, accessibilityDescription: nil) == nil }

        // Assert
        #expect(unresolved.isEmpty)
    }

    @Test
    func noSymbolIsOfferedTwice() {
        // Arrange
        let symbols = AssignableSymbols.groups.flatMap(\.self)

        // Act
        let distinct = Set(symbols)

        // Assert
        #expect(distinct.count == symbols.count)
    }
}
