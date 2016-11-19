/*
 *  TaxonTree.swift
 *  TaxonomyKit
 *
 *  Created:    Guillem Servera on 16/11/2016.
 *  Copyright:  © 2016 Guillem Servera (https://github.com/gservera)
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

/// A value type that encapsulates functionality that allows to build a tree
/// structure based on the lineages of a set of taxons.
public struct TaxonTree {
    
    /// The class that represents each concrete unit in a taxon tree.
    public class Node: TaxonRepresenting {
        
        public private(set) var identifier: TaxonID
        
        public private(set) var name: String
        
        public private(set) var rank: TaxonomicRank?
        
        /// The depth of the node in the tree (zero-based).
        public fileprivate(set) var depth: Int = 0
        
        /// The nodes which have this node as their parent taxon.
        public private(set) var children: [Node] = []
        
        /// The node that represents this node's parent item in the lineage, or
        /// `nil` in case of the origin node. Use `addChild(node:)` on the parent
        /// node to set this property.
        public private(set) weak var parent: Node?
        
        
        /// Initializes a new instance using its three defining parameters.
        ///
        /// - Parameters:
        ///   - identifier: The internal NCBI identifier for the record.
        ///   - name: The scientific name of the record.
        ///   - rank: The rank of the record or `nil` if not set.
        internal init(identifier: TaxonID, name: String, rank: TaxonomicRank?) {
            self.identifier = identifier
            self.name = name
            self.rank = rank
        }
        
        
        /// Initializes a tree node using the `identifier`, `name` and `rank`
        /// properties from any other `TaxonRepresenting` value.
        ///
        /// - Parameter valuesFrom: The source value.
        convenience init<T: TaxonRepresenting>(valuesFrom src: T) {
            self.init(identifier: src.identifier, name: src.name, rank: src.rank)
        }
        
        /// Adds a particular node to the `children` array of this instance and
        /// sets its parent value to this node.
        ///
        /// - Parameter node: The node to be added as a child.
        func addChild(node: Node) {
            children.append(node)
            node.parent = self
        }
        
        
        /// Evaluates whether this node represents another particular node, which
        /// is true when the two nodes are equal or when the second node is
        /// included in the first node's descendants.
        ///
        /// - Parameter node: The node to be evaluated as represented.
        /// - Returns: `true` if this node represents `node`, or `false` instead.
        public func represents(node: Node) -> Bool {
            if self == node || children.contains(node) {
                return true
            }
            for child in children {
                if child.represents(node: node) {
                    return true
                }
            }
            return false
        }
        
        
        /// Evaluates whether this node is represented by another particular node, 
        /// which is true when the two nodes are equal or when the second node is
        /// included in the first node's ancestors.
        ///
        /// - Parameter node: The node to be evaluated as an ancestor.
        /// - Returns: `true` if `node` represents this node, or `false` instead.
        public func isRepresented(by node: Node) -> Bool {
            return node.represents(node: self)
        }
        
    }
    
    /// The complete set of nodes included in the tree.
    public private(set) var allNodes: Set<Node> = []
    
    /// The tree's root node, from which other nodes can be added. Its identifier
    /// is always -1 and both rank and name properties are set to "origin".
    /// However, this value does not represent any NCBI record.
    ///
    /// - Warning: Avoid passing this node or its identifier as a parameter for
    ///            networking methods, since these values are not valid in the 
    ///            NCBI scope.
    public let origin = Node(identifier: "-1", name: "origin", rank: .origin)
    
    /// The depth of the longest branch in the tree (zero-based).
    private(set) var depth: Int = 0
    
    /// The taxons used to build the tree.
    public private(set) var taxons: [Taxon]
    
    /// Initializes a tree structure based on the lineages of a set of taxons.
    ///
    /// - Parameter taxons: The taxons to be included in the tree.
    public init(taxons: [Taxon]) {
        self.taxons = taxons
        allNodes.insert(origin)
        for taxon in taxons {
            var lastNode: Node = origin
            for (index, lineageItem) in taxon.lineageItems.enumerated() {
                let node = Node(valuesFrom: lineageItem)
                node.depth = index + 1
                if let setIndex = allNodes.index(of: node) {
                    lastNode = allNodes[setIndex]
                } else {
                    allNodes.insert(node)
                    lastNode.addChild(node: node)
                    lastNode = node
                }
            }
            let node = Node(valuesFrom: taxon)
            node.depth = lastNode.depth + 1
            if !allNodes.contains(node) {
                allNodes.insert(node)
                lastNode.addChild(node: node)
            }
            if depth < node.depth {
                depth = node.depth
            }
        }
    }
    
}
