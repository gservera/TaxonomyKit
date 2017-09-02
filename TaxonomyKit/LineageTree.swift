/*
 *  LineageTree
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 07/06/2017.
 *  Copyright:  © 2017 Guillem Servera (https://github.com/gservera)
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

import Foundation

/// <#Description#>
public class LineageTree {
    
    private static let OriginNodeName = "origin"
    
    /// <#Description#>
    public class Node: TaxonRepresenting, Hashable, CustomDebugStringConvertible {
        
        /// <#Description#>
        public let identifier: TaxonID
        /// <#Description#>
        public let name: String
        /// <#Description#>
        public var commonName: String?
        /// <#Description#>
        public let rank: TaxonomicRank?
        /// <#Description#>
        public internal(set) weak var parent: Node?
        /// <#Description#>
        public internal(set) var children: Set<Node> = []
        
        internal init(identifier: TaxonID, name: String, rank: TaxonomicRank?, commonName: String? = nil, parent: Node? = nil) {
            self.identifier = identifier
            self.name = name
            self.rank = rank
            self.commonName = commonName
            self.parent = parent
            parent?.children.insert(self)
        }
        
        internal convenience init<T: TaxonRepresenting>(item: T, parent: Node?) {
            self.init(identifier: item.identifier, name: item.name, rank: item.rank, parent: parent)
        }
        
        public static func ==(lhs: LineageTree.Node, rhs: LineageTree.Node) -> Bool {
            return lhs.identifier == rhs.identifier
        }
        
        public var hashValue: Int {
            return identifier
        }
        
        public var debugDescription: String {
            return "<\(identifier):\(name)>"
        }
        
        public var span: Int {
            var _span: Int = 0
            for child in children {
                _span += child.span
            }
            return (_span == 0) ? 1 : _span
        }
        
        public lazy var sortString: String = {
            var lineage: [LineageTree.Node] = [self]
            var currentItem: LineageTree.Node? = nil
            currentItem = parent
            while let current = currentItem {
                lineage.append(current)
                currentItem = current.parent
            }
            return lineage.reversed().map{$0.name}.joined(separator: ";")
        }()
        
        public func isPresentInLineageOf(_ node: Node) -> Bool {
            guard node != self else {
                return true
            }
            var testNode: Node? = node.parent
            while testNode != nil {
                if testNode == self {
                    return true
                }
                testNode = testNode?.parent
            }
            return false
        }
    }
    
    private var nodeMap: [Int:Node] = [:]
    
    /// <#Description#>
    public var nodeCount: Int {
        return nodeMap.count
    }
    
    /// <#Description#>
    private(set) public var rootNode = Node(identifier: -1, name: LineageTree.OriginNodeName, rank: .origin)
    
    public init() {
        nodeMap[-1] = self.rootNode
    }
    
    public var allNodes: Set<Node> {
        return Set(nodeMap.values)
    }
    
    public var endPoints: Set<Node> {
        return Set(nodeMap.values.filter{$0.children.count == 0})
    }
    
    private func contains<T: TaxonRepresenting>(taxon: T) -> Bool {
        return nodeMap[taxon.identifier] != nil
    }
    
    private func contains<T: TaxonRepresenting>(taxa: Set<T>) -> Bool {
        for taxon in taxa {
            if !contains(taxon: taxon) {
                return false
            }
        }
        return true
    }
    
    /// <#Description#>
    ///
    /// - Parameter taxon: <#taxon description#>
    /// - Returns: <#return value description#>
    @discardableResult public func register(_ taxon: Taxon) -> Node {
        if let existingNode = nodeMap[taxon.identifier] {
            return existingNode
        }
        var previousNode = rootNode
        for ancestor in taxon.lineageItems {
            if let existingNode = nodeMap[ancestor.identifier] {
                previousNode = existingNode
            } else {
                let node = Node(item: ancestor, parent: previousNode)
                nodeMap[ancestor.identifier] = node
                previousNode = node
            }
        }
        let node = Node(item: taxon, parent: previousNode)
        nodeMap[taxon.identifier] = node
        return node
    }
    
    /// Returns the deepest ancestor common to all elements in a given taxa set.
    ///
    /// - Parameter taxa: The taxa to be evaluated.
    /// - Returns: The deepest ancestor common to all elements in a given taxa set. If no common
    ///            ancestor can be found, the LineageTree's rootNode is returned.
    /// - Throws: `TaxonomyError.unregisteredTaxa` when any of the specified taxa was not
    ///           registered, or `TaxonomyError.insufficientTaxa` when less than 2 taxa were passed.
    public func closestCommonAncestor<T: TaxonRepresenting>(for taxa: Set<T>) throws -> Node {
        guard self.contains(taxa: taxa) else {
            throw TaxonomyError.unregisteredTaxa
        }
        guard taxa.count >= 2 else {
            throw TaxonomyError.insufficientTaxa
        }
        var nodes = taxa.map { nodeMap[$0.identifier]! }
        let sample = nodes.popLast()!
        var currentNode = sample
        while currentNode !== rootNode {
            var presentInEveryOtherNodes = true
            for testNode in nodes {
                var testPtr = testNode
                var testHit = false
                while testPtr !== rootNode {
                    if testPtr == currentNode {
                        testHit = true
                        break
                    } else {
                        testPtr = testPtr.parent!
                    }
                }
                if !testHit {
                    presentInEveryOtherNodes = false
                    break
                }
            }
            if presentInEveryOtherNodes {
                break
            } else {
                currentNode = currentNode.parent!
            }
        }
        return currentNode
    }
}
