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


/// The `LineageTree` reference type manages a collection of nodes representing
/// the lineage items associated with a particular set of taxa, and can be used
/// to perform calculations based on the relationship between these taxa.
public final class LineageTree {
    
    // MARK: LineageTree.Node Class
    
    /// The `Node` type represents a particular taxon in the lineage tree and
    /// holds references to both its parent and its children (if any).
    public class Node: TaxonRepresenting, Hashable, CustomDebugStringConvertible {
        
        /// The internal NCBI identifier for the node.
        public let identifier: TaxonID
        
        /// The scientific name of the node.
        public let name: String
        
        /// A common name for the node (or nil if not set).
        public var commonName: String? = nil
        
        /// The node's rank or nil if none.
        public let rank: TaxonomicRank?
        
        /// The node's parent (more generic) node or nil for 'origin'.
        public internal(set) weak var parent: Node?
        
        /// A set containing the node's child (more specific) nodes.
        public internal(set) var children: Set<Node> = []
        
        
        /// Initializes a new lineage tree node using its defining parameters and inserts it
        /// to its parent node's children array.
        ///
        /// - Parameters:
        ///   - identifier: The NCBI identifier of the represented taxon.
        ///   - name: The scientific name of the represented taxon.
        ///   - rank: The rank of the represented taxon or nil if the taxon has no rank.
        ///   - parent: The parent node whose children array will hold the new node.
        internal init(identifier: TaxonID, name: String, rank: TaxonomicRank?, parent: Node? = nil) {
            self.identifier = identifier
            self.name = name
            self.rank = rank
            self.parent = parent
            parent?.children.insert(self)
        }
        
        
        /// Initializes a new lineage tree node using the defining parameters taken from a taxon
        /// representing object and inserts the new node to a specified parent node's children array.
        ///
        /// - Parameters:
        ///   - item: The object from which the node identifier, name and rank will be taken.
        ///   - parent: The parent node whose children array will hold the new node.
        internal convenience init<T: TaxonRepresenting>(item: T, parent: Node?) {
            self.init(identifier: item.identifier, name: item.name, rank: item.rank, parent: parent)
        }
        
        
        /// Calculates and returns the number of registered lineage endpoints that descend from this node.
        /// If the node has no children (thus, it is an endpoint itself), 1 is returned.
        internal var span: Int {
            var result: Int = 0
            for child in children {
                result += child.span
            }
            return (result == 0) ? 1 : result
        }
        
        
        /// Generates a string that can be used in an alignment to sort a set of nodes in the same
        /// column while respecting the row order from the previous columns.
        internal lazy var sortString: String = {
            var lineage: [LineageTree.Node] = [self]
            var currentItem: LineageTree.Node? = nil
            currentItem = parent
            while let current = currentItem {
                lineage.append(current)
                currentItem = current.parent
            }
            return lineage.reversed().map{$0.name}.joined(separator: ";")
        }()
        
        
        /// Determines if the node is present in a given node's lineage.
        ///
        /// - Parameter node: The node whose lineage will be tested.
        /// - Returns: `true` if this node is present in the passed node's
        ///            lineage or `false` instead. If both nodes are equal,
        ///            this function returns `true`.
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
        
        
        /// Two nodes are equal when they share the same taxon identifier.
        public static func ==(lhs: LineageTree.Node, rhs: LineageTree.Node) -> Bool {
            return lhs.identifier == rhs.identifier
        }
        
        public var hashValue: Int {
            return identifier
        }
        
        public var debugDescription: String {
            return "<\(identifier):\(name)>"
        }
    }
    
    
    // MARK: Lineage tree basic properties and initializers
    
    
    /// The dictionary that holds all the registered nodes and their lineage.
    private var nodeMap = [Int : Node]()
    
    
    /// Returns the tree's root node. This node's identifier is `-1`, its name is set to
    /// "origin" and its rank property to `TaxonomicRank.origin`.
    private(set) public var rootNode = Node(identifier: -1, name: "origin", rank: .origin)
    
    
    /// Initializes a new empty tree containing the root node only.
    public init() {
        nodeMap[-1] = self.rootNode
    }
    
    
    /// Registers a given taxon with all its lineage items in the lineage tree and returns the
    /// node that was created to represent it.
    ///
    /// - Parameter taxon: The taxon to be registered. If the supplied taxon is already
    ///                    registered in the tree, this method does nothing.
    /// - Returns: A LineageTree.Node object that represents the supplied taxon.
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
    
    
    /// Returns the node that represents a given taxon in the tree.
    ///
    /// - Parameter taxon: The taxon-representing object whose identifier will be looked for.
    /// - Returns: The node that represents `taxon` in the tree or `nil` if there is no
    ///            registered node for the taxon.
    public func node<T: TaxonRepresenting>(for taxon: T) -> Node? {
        return nodeMap[taxon.identifier]
    }
    
    
    // MARK: Tree inspection
    
    /// Returns the number of nodes managed by this tree (including the ones representing
    /// the registered taxa's lineages).
    public var nodeCount: Int {
        return nodeMap.count
    }
    
    /// Returns a set with every node registered in the tree (including their full lineage)
    public var allNodes: Set<Node> {
        return Set(nodeMap.values)
    }
    
    
    /// Returns a set containing the registered nodes that have no children.
    public var endPoints: Set<Node> {
        return Set(nodeMap.values.filter{$0.children.count == 0})
    }
    
    
    // MARK: Tree calculations
    
    
    /// Evaluates whether the tree contains a node representing a given taxon by comparing
    /// their identifiers.
    ///
    /// - Parameter taxon: The taxon-representing object whose identifier will be looked for.
    /// - Returns: `true` if the tree contains a node for the given taxon or `false` instead.
    public func contains<T: TaxonRepresenting>(taxon: T) -> Bool {
        return nodeMap[taxon.identifier] != nil
    }
    
    
    /// Evaluates whether the tree contains a node representing every taxon in a given set
    /// by comparing their identifiers.
    ///
    /// - Parameter taxa: The taxa-representing object set whose identifiers will be looked for.
    /// - Returns: `true` if the tree contains a node for every given taxon or `false` instead.
    public func contains<T: TaxonRepresenting>(taxa: Set<T>) -> Bool {
        for taxon in taxa {
            if !contains(taxon: taxon) {
                return false
            }
        }
        return true
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
