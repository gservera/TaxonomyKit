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

public class LineageAlignment {
    
    public class Cell {
        public internal(set) var offset: Int = -1
        public private(set) var node: LineageTree.Node
        
        init(node: LineageTree.Node) {
            self.node = node
        }
        
        /// Calculates and returns the number of registered lineage endpoints that descend from
        /// this cell's node. If the node has no children (thus, it is an endpoint itself), this
        /// property returns 1.
        public var span: Int {
            return node.span
        }
        
    }
    
    public class Column: CustomDebugStringConvertible {
        public var rank: TaxonomicRank? = nil
        public var cells: [Cell] = []
        init(rank: TaxonomicRank?) {
            self.rank = rank
        }
        
        public var debugDescription: String {
            return "[\(cells.count):\(rank?.rawValue ?? "no rank")]: \(cells.map{$0.node.name}.joined(separator:", "))"
        }
        
        public var span: Int {
            return cells.reduce(0) { $0 + $1.node.span }
        }
        
        public var count: Int {
            return cells.count
        }
        
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
        
        public subscript(index: Int) -> Cell {
            return cells[index]
        }
        
    }
    
    public private(set) var grid: [Column] = TaxonomicRank.hierarchy.map { Column(rank: $0) }
    
    private func currentDepth(for rank: TaxonomicRank) -> Int {
        var i = 0
        for pair in grid {
            if pair.rank == rank {
                return i
            }
            i += 1
        }
        return -1
    }
    
    public var cleanedUp: [Column] {
        return grid.filter{ $0.cells.count > 0 }
    }
    
    public init(lineageTree: LineageTree) {
        let root = lineageTree.rootNode
        parseNode(root, depth: 0)
        
        let endPoints = lineageTree.endPoints.sorted{ $0.sortString < $1.sortString }
        for column in grid {
            var elapsedSpan = 0
            for cell in column.cells {
                guard let _ = cell.node.parent else {
                    cell.offset = 0
                    continue
                }
                var offset = elapsedSpan
                for endPoint in endPoints {
                    if endPoint === cell.node {
                        cell.offset = offset
                        break
                    }
                    if !column.participatesInLineageOf(endPoint) {
                        offset += 1
                    } else if !cell.node.isPresentInLineageOf(endPoint) {
                        continue
                    } else {
                        cell.offset = offset
                        break
                    }
                }
                if cell.offset == -1 {
                    cell.offset = offset
                }
                elapsedSpan += cell.node.span
            }
        }
    }
    
    private func parseNode(_ node: LineageTree.Node, depth: Int) {
        // Check if node has rank
        if let rank = node.rank {
            // Node has rank
            let currentDepth = self.currentDepth(for: rank)
            if currentDepth == depth {
                grid[depth].cells.append(Cell(node: node))
                let sortedChildren = node.children.sorted { $0.sortString < $1.sortString }
                for child in sortedChildren {
                    parseNode(child, depth: depth + 1)
                }
            } else if currentDepth < depth {
                let emptyPair = Column(rank: nil)
                grid.insert(emptyPair, at: depth)
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
                if grid[i].rank != nil {
                    let emptyPair = Column(rank: nil)
                    grid.insert(emptyPair, at: depth)
                    willRecall = true
                    break
                }
            }
            if willRecall {
                parseNode(node, depth: depth)
            } else {
                grid[depth].cells.append(Cell(node: node))
                let sortedChildren = node.children.sorted { $0.sortString < $1.sortString }
                for child in sortedChildren {
                    parseNode(child, depth: depth + 1)
                }
            }
        }
    }
    
}
