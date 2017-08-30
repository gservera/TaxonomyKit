//
//  LineageAlignment.swift
//  TaxonomyKit
//
//  Created by Guillem Servera Negre on 7/6/17.
//  Copyright © 2017 Guillem Servera. All rights reserved.
//

import Foundation

public class LineageAlignment {
    
    public class Column: CustomDebugStringConvertible {
        public var rank: TaxonomicRank? = nil
        public var nodes: [LineageTree.Node] = []
        init(rank: TaxonomicRank?) {
            self.rank = rank
        }
        
        public var debugDescription: String {
            return "[\(nodes.count):\(rank?.rawValue ?? "no rank")]: \(nodes.map{$0.name}.joined(separator:", "))"
        }
        
        public var span: Int {
            return nodes.reduce(0) { $0 + $1.span }
        }
        
        public var count: Int {
            return nodes.count
        }
        
        public subscript(index: Int) -> LineageTree.Node {
            return nodes[index]
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
        return grid.filter{ $0.nodes.count > 0 }
    }
    
    public init(lineageTree: LineageTree) {
        let root = lineageTree.rootNode
        parseNode(root, depth: 0)
    }
    
    private func parseNode(_ node: LineageTree.Node, depth: Int) {
        // Check if node has rank
        if let rank = node.rank {
            // Node has rank
            let currentDepth = self.currentDepth(for: rank)
            if currentDepth == depth {
                grid[depth].nodes.append(node)
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
                grid[depth].nodes.append(node)
                for child in node.children {
                    parseNode(child, depth: depth + 1)
                }
            }
        }
    }
    
}
