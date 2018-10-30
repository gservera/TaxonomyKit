import Foundation

/**
    This class is inherited from `NCBIXMLElement` and has a few addons to represent **XML Document**.
    XML Parsing is also done with this object.
*/
internal final class NCBIXMLDocument: NSObject, XMLParserDelegate {

    /// A type representing error value that can be thrown or inside `error` property of `NCBIXMLElement`.
    enum XMLError: Error {

        /// This will be inside `error` property of `NCBIXMLElement` when subscript is used for not-existing element.
        case elementNotFound

        /// `NCBIXMLDocument` can throw this error on `init` if parsing with `XMLParser` was not successful.
        case parsingFailed
    }

    /**
     This is base class for holding XML structure.
     
     You can access its structure by using subscript like this: `element["foo"]["bar"]` which would
     return `<bar></bar>` element from `<element><foo><bar></bar></foo></element>` XML as an `NCBIXMLElement` object.
     */
    internal class Element {

        /// Every `NCBIXMLElement` should have its parent element instead of `NCBIXMLDocument` which parent is `nil`.
        private(set) weak var parent: Element?

        /// Child XML elements.
        private(set) var children = [Element]()

        /// XML Element name.
        var name: String

        /// XML Element value.
        var value: String?

        /// Error value (`nil` if there is no error).
        var error: XMLError?

        /// Read integer value.
        func readInt() -> Int? {
            guard let stringValue = value else { return nil }
            return Int(stringValue)
        }

        // MARK: - Lifecycle

        /**
         Designated initializer - all parameters are optional.
         - parameter name: XML element name.
         - parameter value: XML element value (defaults to `nil`).
         - returns: An initialized `NCBIXMLElement` object.
         */
        init(name: String, value: String? = nil, error: XMLError? = nil) {
            self.name = name
            self.value = value
            self.error = error
        }

        // MARK: - XML Read

        /// The first element with given name **(Empty element with error if not exists)**.
        subscript(key: String) -> Element {
            guard let first = children.first(where: { $0.name == key }) else {
                let errorElement = Element(name: key)
                errorElement.error = XMLError.elementNotFound
                return errorElement
            }
            return first
        }

        /// Returns all of the elements with equal name as `self` **([] if not exists)**.
        var all: [Element] {
            return parent?.children.filter { $0.name == name } ?? ((error != .elementNotFound) ? [self] : [])
        }

        // MARK: - XML Write

        /**
         Adds child XML element to `self`.
         - parameter name: Child XML element name.
         - parameter value: Child XML element value (defaults to `nil`).
         - returns: Child XML element with `self` as `parent`.
         */
        @discardableResult
        func addChild(name: String, value: String? = nil) -> Element {
            let child = Element(name: name, value: value)
            child.parent = self
            children.append(child)
            return child
        }
    }

    /// Root (the first child element) element of XML Document **(Empty element with error if not exists)**.
    var root: Element!

    // MARK: - Lifecycle

    /**
     Initializer used for parsing XML data.
     - parameter xml: XML data to parse.
     - returns: Initialized XML Document object containing parsed data. Throws error if data could not be parsed.
     */
    init(xml: Data) throws {
        super.init()
        try parse(data: xml)
    }

    private var currentParent: Element?
    private var currentElement: Element?
    private var currentValue = String()
    private var parseError: Error?

    private func parse(data: Data) throws {
        let parser = XMLParser(data: data)
        parser.delegate = self
        let success = parser.parse()
        currentParent = nil
        if !success {
            throw XMLError.parsingFailed
        } else if root == nil {
            throw XMLError.elementNotFound
        }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        currentValue = String()
        if root == nil {
            root = Element(name: elementName)
            currentElement = root
        } else {
            currentElement = currentParent?.addChild(name: elementName)
        }
        currentParent = currentElement
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
        let newValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        currentElement?.value = newValue == String() ? nil : newValue
    }

    func parser(_ parser: XMLParser, didEndElement: String, namespaceURI: String?, qualifiedName: String?) {
        currentParent = currentParent?.parent
        currentElement = nil
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
