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

    /// The `LineageAlignment.Cell` struct wraps a lineage tree node and the properties
    /// related to its position and dimensions in the alignment.
    public struct Cell: CustomDebugStringConvertible {

        /// The lineage tree node represented by the cell.
        public private(set) var node: LineageTree.Node

        /// Initializes a new lineage alignment cell for a given node.
        ///
        /// - Parameter node: The node represented by the cell.
        internal init(node: LineageTree.Node) {
            self.node = node
        }

        /// Once the alignment has been generated, this property is set to the number of cells
        /// or empty spaces that come before this cell when laying out the column (aka the cell's row).
        public internal(set) var offset: Int = -1

        /// Calculates and returns the number of registered lineage endpoints that descend from
        /// this cell's node. If the node has no children (thus, it is an endpoint itself), this
        /// property returns 1.
        public var span: Int {
            return node.span
        }

        public var debugDescription: String {
            return "<\(node.identifier):\(node.name)@\(offset)(\(span))>"
        }
    }

    // MARK: LineageAlignment.Column Class

    /// The `LineageAlignment.Column` struct holds an array of cells that share the same position
    /// in the alignment's rank hierarchy.
    public struct Column: CustomDebugStringConvertible {

        /// The column's rank (may be nil). All cells in the column share the same rank.
        public private(set) var rank: TaxonomicRank?

        /// The array of cells managed by this column.
        public fileprivate(set) var cells: [Cell] = []

        /// Initializes a new empty column with the given rank.
        ///
        /// - Parameter rank: The rank to be set to the column or nil if the column has no rank.
        internal init(rank: TaxonomicRank?) {
            self.rank = rank
        }

        /// Calculates and returns the sum of the managed cells' span values.
        public var span: Int {
            return cells.reduce(0) { $0 + $1.node.span }
        }

        /// Returns the number of cells in this column.
        public var count: Int {
            return cells.count
        }

        /// Determines if this column contains any node from a given node's lineage,
        /// including that node itself.
        ///
        /// - Parameter endPoint: The node whose lineage will be tested.
        /// - Returns: `true` if this column participates in the supplied node's lineage
        ///            or `false` instead.
        public func participatesInLineageOf(_ endPoint: LineageTree.Node) -> Bool {
            var testNode: LineageTree.Node? = endPoint
            while testNode != nil {
                for cell in cells where testNode === cell.node {
                    return true
                }
                testNode = testNode?.parent
            }
            return false
        }

        public var debugDescription: String {
            let rankDescription = rank?.rawValue ?? "no rank"
            return "[\(cells.count):\(rankDescription)]: \(cells.map { $0.node.name }.joined(separator: ", "))"
        }
    }

    // MARK: Alignment properties

    /// The array of columns in the alignment, sorted by rank.
    public private(set) var columns: [Column]

    /// Returns the index for a column matching a given rank in the column array.
    /// The index of a column with no rank cannot be determined using `nil`, since
    /// there might be multiple columns with no rank.
    ///
    /// - Parameter rank: The rank to be looked for.
    /// - Returns: The index of the column with the passed rank in the column array.
    public func indexOfColumn(for rank: TaxonomicRank) -> Int {
        var index = -1
        for (idx, column) in columns.enumerated() where column.rank == rank {
            index = idx
            break
        }
        return index // We should never get here.
    }

    /// Returns only the columns that contain at least one row.
    public var cleanedUp: [Column] {
        return columns.filter { !$0.cells.isEmpty }
    }

    /// Initializes a new lineage alignment based on the nodes of a given lineage tree.
    ///
    /// - Parameter lineageTree: The lineage tree from which to take the nodes and their
    ///                          connections.
    /// - Parameter automaticallyCleanUp: Set this parameter to `true` to automatically
    ///                                   strip the columns that remain empty after the
    ///                                   alignment process. Default value is `true`.
    public init(lineageTree: LineageTree, automaticallyCleanUp: Bool = true) {
        columns = TaxonomicRank.hierarchy.map { Column(rank: $0) }
        parseNode(lineageTree.rootNode, minimumColumnIndex: 0)
        let endPoints = lineageTree.endPoints.sorted { $0.sortString < $1.sortString }
        updateRowOffsets(with: endPoints)
        if automaticallyCleanUp {
            columns = columns.filter { !$0.cells.isEmpty }
        }
    }

    /// Recursively parses a given node and its children while modifying the column array
    /// in order to place each node in a suitable column accodring to their rank or position
    /// in the rank hierarchy.
    ///
    /// - Parameters:
    ///   - node: The node that is currently being parsed.
    ///   - minimumColumnIndex: The minimum column index in which the node should be placed.
    ///                         Although the initial value used in combination with the 'origin'
    ///                         node is 0, it can be incremented with each recursive call as
    ///                         required to accommodate each node.
    private mutating func parseNode(_ node: LineageTree.Node, minimumColumnIndex depth: Int) {
        // Check if node has rank
        if let rank = node.rank {
            // Node has rank
            let currentDepth = indexOfColumn(for: rank)
            if currentDepth == depth {
                // The column for this node's rank is already placed at the minimum column
                // index required by the caller so it won't be moved. We'll finish by inserting
                // the node in its cell array and then we'll call this method on each of its
                // children, with the next index as the minimum column index.
                finishInsertingNode(node, at: depth)
            } else if currentDepth < depth {
                // The current index for the column with this rank is lower than the minimum
                // required by this node. We'll insert a no-rank column before and call this
                // method with the same node again until the indexes match.
                columns.insert(Column(rank: nil), at: depth)
                parseNode(node, minimumColumnIndex: depth)
            } else {
                // The current index for the column with this rank is already higher than the
                // minimum required by this node, as requested by a previous node with another
                // endpoint. We'll call this method again with that index.
                parseNode(node, minimumColumnIndex: currentDepth)
            }
        } else {
            // Node has no rank. Let's get the index of the previous ranked column
            var offsetToPreviousRanked = 1
            var previousRankedNode: LineageTree.Node? = node.parent
            while previousRankedNode?.rank == nil {
                offsetToPreviousRanked += 1
                previousRankedNode = previousRankedNode?.parent
            }
            let previousRankedNodePos = depth - offsetToPreviousRanked

            // Now we evaluate whether there are enough unranked columns between the
            // previous ranked column and the minimum column index in order to prevent
            // the node from being inserted in the next ranked column.
            var needsMoreUnrankedColumns = false
            for idx in previousRankedNodePos+1...depth where columns[idx].rank != nil {
                // There's no enough room, we'll insert a new empty unranked column
                // and call this method again to re-test.
                let emptyUnrankedColumn = Column(rank: nil)
                columns.insert(emptyUnrankedColumn, at: depth)
                needsMoreUnrankedColumns = true
                break
            }

            guard !needsMoreUnrankedColumns else {
                parseNode(node, minimumColumnIndex: depth)
                return
            }

            // No extra columns are needed. We'll continue parsing
            finishInsertingNode(node, at: depth)
        }
    }

    /// Inserts a node in the column with a given index's cell array and then calls
    /// `parseNode(_:minimumColumnIndex:)` for each children, with the next index as the minimum
    /// column index.
    ///
    /// - Parameters:
    ///   - node: The node being inserted.
    ///   - columnIndex: The index of the column where the node will be inserted.
    private mutating func finishInsertingNode(_ node: LineageTree.Node, at columnIndex: Int) {
        columns[columnIndex].cells.append(Cell(node: node))
        let sortedChildren = node.children.sorted { $0.sortString < $1.sortString }
        for child in sortedChildren {
            parseNode(child, minimumColumnIndex: columnIndex + 1)
        }
    }

    /// Sets the offset for each managed cell according to their relative
    /// position among the lineage tree's endpoints.
    ///
    /// - Parameter endPoints: The lineage tree endpoints (sorted).
    private mutating func updateRowOffsets(with endPoints: [LineageTree.Node]) {
        for (col, column) in columns.enumerated() {
            var elapsedSpan = 0
            for (row, cell) in column.cells.enumerated() {
                var offset = elapsedSpan
                for endPoint in endPoints {
                    if !column.participatesInLineageOf(endPoint) {
                        offset += 1
                    } else if !cell.node.isPresentInLineageOf(endPoint) {
                        continue
                    } else {
                        columns[col].cells[row].offset = offset
                        break
                    }
                }
                if cell.offset == -1 {
                    columns[col].cells[row].offset = offset
                }
                elapsedSpan += cell.node.span
            }
        }
    }
}
