import Foundation
import DifferenceKit

final class DiffableDataSourceCore<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType: Differentiable, SectionIdentifierType: Hashable, ItemIdentifierType: Differentiable, ItemIdentifierType: Hashable {
    typealias Section = SnapshotStructure<SectionIdentifierType, ItemIdentifierType>.Section

    private let dispatcher = MainThreadSerialDispatcher()
    private var currentSnapshot = DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
    private var sections: [Section] = []

    func apply<View: AnyObject>(
        _ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        view: View?,
        performUpdates: @escaping (View, StagedChangeset<[Section]>, @escaping ([Section]) -> Void) -> Void,
        completion: (() -> Void)?
        ) {
        dispatcher.dispatch { [weak self] in
            guard let self = self else {
                return
            }

            self.currentSnapshot = snapshot

            let newSections = snapshot.structure.sections

            guard let view = view else {
                return self.sections = newSections
            }
            
            let changeset = StagedChangeset(source: self.sections, target: newSections)
            performUpdates(view, changeset) { sections in
                self.sections = sections
            }
            completion?()
        }
    }

    func snapshot() -> DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        var snapshot = DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        snapshot.structure.sections = currentSnapshot.structure.sections
        return snapshot
    }
    
    func sectionIdentifier(for section: Int) -> SectionIdentifierType? {
        guard 0..<sections.endIndex ~= section else {
            return nil
        }
        
        return sections[section].section
    }
    
    func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        guard 0..<sections.endIndex ~= indexPath.section else {
            return nil
        }

        let items = sections[indexPath.section].elements

        guard 0..<items.endIndex ~= indexPath.item else {
            return nil
        }

        return items[indexPath.item].item
    }

    func unsafeItemIdentifier(for indexPath: IndexPath, file: StaticString = #file, line: UInt = #line) -> ItemIdentifierType {
        guard let itemIdentifier = itemIdentifier(for: indexPath) else {
            universalError("Item not found at the specified index path(\(indexPath)).")
        }

        return itemIdentifier
    }

    func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        let indexPathMap: [ItemIdentifierType: IndexPath] = sections.enumerated()
            .reduce(into: [:]) { result, section in
                for (itemIndex, item) in section.element.elements.enumerated() {
                    result[item.item] = IndexPath(
                        item: itemIndex,
                        section: section.offset
                    )
                }
        }
        return indexPathMap[itemIdentifier]
    }

    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfItems(inSection section: Int) -> Int {
        return sections[section].elements.count
    }
}
