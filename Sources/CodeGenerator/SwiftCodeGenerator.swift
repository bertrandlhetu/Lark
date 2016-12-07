struct SwiftCodeGenerator {
    /// This method is used when only one Swift file is being generated.
    static func generateCode(for types: [SwiftMetaType]) -> String {
        return [
            preamble,
            "//",
            "// MARK: - SOAP Structures",
            "//",
            types.map { $0.toSwiftCode(indentedBy: "    ") }.joined(separator: "\n\n"),
            "",
            "//",
            "// MARK: - SOAP Client",
            "//",
            // todo
            ""].joined(separator: "\n")
    }

    private static let preamble = [
        "// This file was generated by Lark. https://github.com/Bouke/Lark",
        "",
        "import Foundation",
        "import LarkRuntime",
        ""].joined(separator: "\n")
}


// MARK: - Implementation

typealias SwiftCode = String
typealias LineOfCode = SwiftCode

struct Indentation {
    private let chars: String
    private let level: Int
    private let value: String

    init(chars: String, level: Int = 0) {
        precondition(level >= 0)
        self.chars = chars
        self.level = level
        self.value = String(repeating: chars, count: level)
    }

    func apply(toLineOfCode lineOfCode: LineOfCode) -> LineOfCode {
        return value + lineOfCode
    }

    func apply(toFirstLine firstLine: LineOfCode,
               nestedLines generateNestedLines: (Indentation) -> [LineOfCode],
               andLastLine lastLine: LineOfCode) -> [LineOfCode] {
        let first  = apply(toLineOfCode: firstLine)
        let middle = generateNestedLines(self.increased())
        let last   = apply(toLineOfCode: lastLine)
        return [first] + middle + [last]
    }

    private func increased() -> Indentation {
        return Indentation(chars: chars, level: level + 1)
    }
}


extension SwiftClass {
    func toSwiftCode(indentedBy indentChars: String = "    ") -> SwiftCode {
        let indentation = Indentation(chars: indentChars)
        let linesOfCode = toLinesOfCode(at: indentation)
        return linesOfCode.joined(separator: "\n")
    }

    func toLinesOfCode(at indentation: Indentation) -> [LineOfCode] {
        return indentation.apply(
            toFirstLine: "class \(name) {",
            nestedLines:      linesOfCodeForMembers(at:),
            andLastLine: "}")
    }

    private func linesOfCodeForMembers(at indentation: Indentation) -> [LineOfCode] {
        return linesOfCodeForProperties(at: indentation)
//            + initializer.toLinesOfCode(at: indentation)
//            + failableInitializer.toLinesOfCode(at: indentation)
            + linesOfCodeForNestedClasses(at: indentation)
    }

    private func linesOfCodeForProperties(at indentation: Indentation) -> [LineOfCode] {
        return sortedProperties.map { property in
            let propertyCode = property.toLineOfCode()
            return indentation.apply(toLineOfCode: propertyCode)
        }
    }

    private var sortedProperties: [SwiftProperty] {
        return properties.sorted { (lhs, rhs) -> Bool in
            return lhs.name.compare(rhs.name) == .orderedAscending
        }
    }

    private func linesOfCodeForNestedClasses(at indentation: Indentation) -> [LineOfCode] {
        return sortedNestedTypes.flatMap { $0.toLinesOfCode(at: indentation) }
    }

    private var sortedNestedTypes: [SwiftMetaType] {
        return nestedTypes.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.name.compare(rhs.name) == .orderedAscending
        })
    }
}

fileprivate extension SwiftType {
    func toSwiftCode() -> SwiftCode {
        switch self {
        case let .identifier(name): return name
        case let .optional(type): return "\(type.toSwiftCode())?"
        case let .array(type): return "[\(type.toSwiftCode())]"
        }
    }
}

fileprivate extension SwiftProperty {
    func toLineOfCode() -> LineOfCode {
        return "let \(name): \(type.toSwiftCode())"
    }
}

extension SwiftEnum {
    func toSwiftCode(indentedBy indentChars: String = "    ") -> SwiftCode {
        let indentation = Indentation(chars: indentChars)
        let linesOfCode = toLinesOfCode(at: indentation)
        return linesOfCode.joined(separator: "\n")
    }

    func toLinesOfCode(at indentation: Indentation) -> [LineOfCode] {
        return indentation.apply(
            toFirstLine: "enum \(name): \(rawType.toSwiftCode()) {",
            nestedLines:      linesOfCodeForCases(at:),
            andLastLine: "}")
    }

    private func linesOfCodeForCases(at indentation: Indentation) -> [LineOfCode] {
        return sortedCases.map { (name, rawValue) in
            return indentation.apply(toLineOfCode: "case \(name): \"\(rawValue)\"")
        }
    }

    private var sortedCases: [(String, String)] {
        return cases.sorted(by: { return $0.key < $1.key } )
    }
}

