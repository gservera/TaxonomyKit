/*
 *  LineageAlignment.swift
 *  TaxonomyKitTests
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


/// The `LineageAlignment` struct parses the contents of a lineage tree and aligns
/// its nodes in a succession of "columns" based on each node's rank in a way in
/// which all the nodes with the same rank end up in the same column, while the
/// ones without rank are placed in columns between the closest ranked columns.
///
/// Once generated, the alignment can be used with various purposes, such as
/// serving as a model to draw the tree in a view.
public struct LineageAlignment {
    
    
    // MARK: LineageAlignment.Cell Class
    
    /// <#Description#>
    public struct Cell {
        
        /// <#Description#>
        public private(set) var node: LineageTree.Node
        
        
        /// <#Description#>
        ///
        /// - Parameter node: <#node description#>
        internal init(node: LineageTree.Node) {
            self.node = node
        }
        
        
        /// <#Description#>
        public internal(set) var offset: Int = -1
        

        /// Calculates and returns the number of registered lineage endpoints that descend from
        /// this cell's node. If the node has no children (thus, it is an endpoint itself), this
        /// property returns 1.
        public var span: Int {
            return node.span
        }
        
    }
    
    
    // MARK: LineageAlignment.Column Class
    
    /// <#Description#>
    public struct Column: CustomDebugStringConvertible {
        
        
        /// <#Description#>
        public var rank: TaxonomicRank? = nil
        
        
        /// <#Description#>
        public var cells: [Cell] = []
        
        
        /// <#Description#>
        ///
        /// - Parameter rank: <#rank description#>
        internal init(rank: TaxonomicRank?) {
            self.rank = rank
        }
        
        
        public var debugDescription: String {
            return "[\(cells.count):\(rank?.rawValue ?? "no rank")]: \(cells.map{$0.node.name}.joined(separator:", "))"
        }
        
        
        /// <#Description#>
        public var span: Int {
            return cells.reduce(0) { $0 + $1.node.span }
        }
        
        
        /// <#Description#>
        public var count: Int {
            return cells.count
        }
        
        
        /// <#Description#>
        ///
        /// - Parameter endPoint: <#endPoint description#>
        /// - Returns: <#return value description#>
        public func participatesInLineageOf(_ endPoint: LineageTree.Node) -> Bool {
            var testNode: LineageTree.Node? = endPoint
            while testNode != nil {
                for cell in cells {
                    if testNode === cell.node {
                        return true
                    }
                }
                testNode = testNode?.parent
            }
            return false
        }
        
    }
    
    
    /// <#Description#>
    public private(set) var columns: [Column] = TaxonomicRank.hierarchy.map { Column(rank: $0) }
    
    
    /// <#Description#>
    ///
    /// - Parameter rank: <#rank description#>
    /// - Returns: <#return value description#>
    private func currentDepth(for rank: TaxonomicRank) -> Int {
        for (i, column) in columns.enumerated() {
            if column.rank == rank {
                return i
            }
        }
        return -1
    }
    
    
    /// <#Description#>
    public var cleanedUp: [Column] {
        return columns.filter{ $0.cells.count > 0 }
    }
    
    
    /// <#Description#>
    ///
    /// - Parameter lineageTree: <#lineageTree description#>
    public init(lineageTree: LineageTree) {
        parseNode(lineageTree.rootNode, depth: 0)
        let endPoints = lineageTree.endPoints.sorted{ $0.sortString < $1.sortString }
        updateRowOffsets(with: endPoints)
    }
    
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - node: <#node description#>
    ///   - depth: <#depth description#>
    private mutating func parseNode(_ node: LineageTree.Node, depth: Int) {
        // Check if node has rank
        if let rank = node.rank {
            // Node has rank
            let currentDepth = self.currentDepth(for: rank)
            if currentDepth == depth {
                columns[depth].cells.append(Cell(node: node))
                let sortedChildren = node.children.sorted { $0.sortString < $1.sortString }
                for child in sortedChildren {
                    parseNode(child, depth: depth + 1)
                }
            } else if currentDepth < depth {
                let emptyPair = Column(rank: nil)
                columns.insert(emptyPair, at: depth)
                parseNode(node, depth: depth)
            } else {
                parseNode(node, depth: currentDepth)
            }
        } else {
            var extraIterations = 1
            var previousRankedNode: LineageTree.Node? = node.parent
            while previousRankedNode?.rank == nil {
                extraIterations += 1
                previousRankedNode = previousRankedNode?.parent
            }
            let previousRankedNodePos = depth - extraIterations
            var willRecall = false
            for i in previousRankedNodePos+1...depth {
                if columns[i].rank != nil {
                    let emptyPair = Column(rank: nil)
                    columns.insert(emptyPair, at: depth)
                    willRecall = true
                    break
                }
            }
            if willRecall {
                parseNode(node, depth: depth)
            } else {
                columns[depth].cells.append(Cell(node: node))
                let sortedChildren = node.children.sorted { $0.sortString < $1.sortString }
                for child in sortedChildren {
                    parseNode(child, depth: depth + 1)
                }
            }
        }
    }
    
    
    /// <#Description#>
    ///
    /// - Parameter endPoints: <#endPoints description#>
    private mutating func updateRowOffsets(with endPoints: [LineageTree.Node]) {
        for (c, column) in columns.enumerated() {
            var elapsedSpan = 0
            for (r, cell) in column.cells.enumerated() {
                var offset = elapsedSpan
                for endPoint in endPoints {
                    if !column.participatesInLineageOf(endPoint) {
                        offset += 1
                    } else if !cell.node.isPresentInLineageOf(endPoint) {
                        continue
                    } else {
                        columns[c].cells[r].offset = offset
                        break
                    }
                }
                if cell.offset == -1 {
                    columns[c].cells[r].offset = offset
                }
                elapsedSpan += cell.node.span
            }
        }
    }
    
}
