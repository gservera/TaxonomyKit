//
//  LineageAlignment.swift
//  TaxonomyKit
//
//  Created by Guillem Servera Negre on 7/6/17.
//  Copyright © 2017 Guillem Servera. All rights reserved.
//

import Foundation

internal class LineageAlignment {
    
    internal class Pair: CustomDebugStringConvertible {
        var rank: TaxonomicRank? = nil
        var nodes: [LineageTree.Node] = []
        init(rank: TaxonomicRank?) {
            self.rank = rank
        }
        
        var debugDescription: String {
            return "[\(nodes.count):\(String(describing: rank))]: \(nodes.map{$0.name}.joined(separator:", "))"
        }
    }
    
    var table: [Pair] = TaxonomicRank.hierarchy.map { Pair(rank: $0) }
    
    private func currentDepth(for rank: TaxonomicRank) -> Int {
        var i = 0
        for pair in table {
            if pair.rank == rank {
                return i
            }
            i += 1
        }
        return -1
    }
    
    var cleanedUp: [[LineageTree.Node]] {
        return table.filter{ $0.nodes.count > 0 }.map{$0.nodes}
    }
    
    init(lineageTree: LineageTree) {
        let root = lineageTree.rootNode
        parseNode(root, depth: 0)
    }
    
    private func parseNode(_ node: LineageTree.Node, depth: Int) {
        if let rank = node.rank {
            let currentDepth = self.currentDepth(for: rank)
            if currentDepth == depth {
                table[depth].nodes.append(node)
                for child in node.children {
                    parseNode(child, depth: depth + 1)
                }
            } else if currentDepth < depth {
                let emptyPair = Pair(rank: nil)
                table.insert(emptyPair, at: depth)
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
                if table[i].rank != nil {
                    let emptyPair = Pair(rank: nil)
                    table.insert(emptyPair, at: depth)
                    willRecall = true
                    break
                }
            }
            if willRecall {
                parseNode(node, depth: depth)
            } else {
                table[depth].nodes.append(node)
                for child in node.children {
                    parseNode(child, depth: depth + 1)
                }
            }
        }
    }
    
}