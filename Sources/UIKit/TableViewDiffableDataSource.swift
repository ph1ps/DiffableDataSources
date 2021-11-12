#if os(iOS) || os(tvOS)

import UIKit
import DifferenceKit

/// A class for backporting `UITableViewDiffableDataSource` introduced in iOS 13.0+, tvOS 13.0+.
/// Represents the data model object for `UITableView` that can be applies the
/// changes with automatic diffing.
open class TableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: NSObject, UITableViewDataSource where SectionIdentifierType: Differentiable, SectionIdentifierType: Hashable, ItemIdentifierType: Differentiable, ItemIdentifierType: Hashable {
    /// The type of closure providing the cell.
    public typealias CellProvider = (UITableView, IndexPath, ItemIdentifierType) -> UITableViewCell?

    /// The default animation to updating the views.
    public var defaultRowAnimation: UITableView.RowAnimation = .automatic

    private weak var tableView: UITableView?
    private let cellProvider: CellProvider
    private let core = DiffableDataSourceCore<SectionIdentifierType, ItemIdentifierType>()

    /// Creates a new data source.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance to be managed.
    ///   - cellProvider: A closure to dequeue the cell for rows.
    public init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        self.tableView = tableView
        self.cellProvider = cellProvider
        super.init()

        tableView.dataSource = self
    }

    /// Applies given snapshot to perform automatic diffing update.
    ///
    /// - Parameters:
    ///   - snapshot: A snapshot object to be applied to data model.
    ///   - animatingDifferences: A Boolean value indicating whether to update with
    ///                           diffing animation.
    ///   - completion: An optional completion block which is called when the complete
    ///                 performing updates.
    public func apply(_ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, completion: (() -> Void)? = nil) {
        core.apply(
            snapshot,
            view: tableView,
            performUpdates: { tableView, changeset, setSections in
                tableView.reload(using: changeset, with: self.defaultRowAnimation, setData: setSections)
        },
            completion: completion
        )
    }

    /// Returns a new snapshot object of current state.
    ///
    /// - Returns: A new snapshot object of current state.
    public func snapshot() -> DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        return core.snapshot()
    }
    
    /// Returns an section identifier for given section index.
    ///
    /// - Parameters:
    ///   - section: An section index for the section identifier.
    ///
    /// - Returns: An section identifier for given section index.
    public func sectionIdentifier(for section: Int) -> SectionIdentifierType? {
        return core.sectionIdentifier(for: section)
    }

    /// Returns an item identifier for given index path.
    ///
    /// - Parameters:
    ///   - indexPath: An index path for the item identifier.
    ///
    /// - Returns: An item identifier for given index path.
    public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        return core.itemIdentifier(for: indexPath)
    }

    /// Returns an index path for given item identifier.
    ///
    /// - Parameters:
    ///   - itemIdentifier: An identifier of item.
    ///
    /// - Returns: An index path for given item identifier.
    public func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        return core.indexPath(for: itemIdentifier)
    }

    /// Returns the number of sections in the data source.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///
    /// - Returns: The number of sections in the data source.
    public func numberOfSections(in tableView: UITableView) -> Int {
        return core.numberOfSections()
    }

    /// Returns the number of items in the specified section.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - section: An index of section.
    ///
    /// - Returns: The number of items in the specified section.
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return core.numberOfItems(inSection: section)
    }

    /// Returns the title for the specified section's header.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - section: An index of section.
    ///
    /// - Returns: The title for the specified section's header, or `nil` for no title.
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    /// Returns the title for the specified section's footer.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - section: An index of section.
    ///
    /// - Returns: The title for the specified section's footer, or `nil` for no title.
    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }

    /// Returns a cell for row at specified index path.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - indexPath: An index path for cell.
    ///
    /// - Returns: A cell for row at specified index path.
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemIdentifier = core.unsafeItemIdentifier(for: indexPath)
        guard let cell = cellProvider(tableView, indexPath, itemIdentifier) else {
            universalError("UITableView dataSource returned a nil cell for row at index path: \(indexPath), tableView: \(tableView), itemIdentifier: \(itemIdentifier)")
        }

        return cell
    }

    /// Returns whether it is possible to edit a row at given index path.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - section: An index of section.
    ///
    /// - Returns: A boolean for row at specified index path.
    open func tableView(_ tableView: UITableView, canEditRowAt: IndexPath) -> Bool {
        return false
    }

    /// Returns whether it is possible to move a row at given index path.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - section: An index of section.
    ///
    /// - Returns: A boolean for row at specified index path.
    open func tableView(_ tableView: UITableView, canMoveRowAt _: IndexPath) -> Bool {
        return false
    }

    /// Performs the edit action for a row at given index path.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - editingStyle: An action for given edit action.
    ///   - indexPath: An index path for cell.
    ///
    /// - Returns: Void.
    open func tableView(_ tableView: UITableView, commit _: UITableViewCell.EditingStyle, forRowAt _: IndexPath) {
        // Empty implementation.
    }

    /// Moves a row at given index path.
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - source: An index path for given cell position.
    ///   - target: An index path for target cell position.
    ///
    /// - Returns: Void.
    open func tableView(_ tableView: UITableView, moveRowAt _: IndexPath, to _: IndexPath) {
        // Empty implementation.
    }

    /// Return list of section titles to display in section index view (e.g. "ABCD...Z#").
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///
    /// - Returns: The list of section titles to display.
    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }

    /// Tell table which section corresponds to section title/index (e.g. "B",1)).
    ///
    /// - Parameters:
    ///   - tableView: A table view instance managed by `self`.
    ///   - title: The title as displayed in the section index of tableView.
    ///   - section: An index number identifying a section title in the array returned by sectionIndexTitles(for tableView:).
    ///
    /// - Returns: The list of section titles to display.
    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle _: String, at section: Int) -> Int {
        return section
    }
}

#endif
