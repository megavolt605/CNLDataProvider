//
//  CNLDataProvider.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public protocol CNLDataProvider: class {
    associatedtype ModelType: CNLModelObject, CNLDataSourceModel
    
    var dataSource: CNLDataSource<ModelType>! { get set }
    var dataViewer: CNLDataViewer { get }
    var dataProviderVariables: CNLDataProviderVariables<ModelType> { get set }
    
    // content state
    var contentState: CNLDataProviderContentState? { get set }
    var noData: Bool { get }
    func updateContentState()
    func updateCounts()
    
    func beforeFetch()
    func fetchFromStart(completed: ((_ success: Bool) -> Void)?)
    func fetchNext(completed: ((_ success: Bool) -> Void)?)
    func afterFetch()
    
    var sectionCount: Int { get }
    func itemCountInSection(section: Int) -> Int
    
    func sectionForItem(item: ModelType.ArrayElement) -> Int
    func sectionTextForItem(item: ModelType.ArrayElement) -> String
    
    func itemAtIndexPath(indexPath: IndexPath) -> ModelType.ArrayElement?
    func indexPathOfItem(check: (_ modelItem: ModelType.ArrayElement) -> Bool) -> IndexPath?
    func indexPathsOfItems(check: (_ modelItem: ModelType.ArrayElement) -> Bool) -> [IndexPath]
    
    func initializeWith(dataSource: CNLDataSource<ModelType>, fetch: Bool)
}

public extension CNLDataProvider {
    
    public var noData: Bool {
        return dataSource.model.list.count <= 0
    }
    
    public func updateContentState() {
        contentState?.kind = noData ? .noData : .normal
    }
    
    public func sectionForItem(item: ModelType.ArrayElement) -> Int {
        let sectionText = sectionTextForItem(item: item)
        let res = dataProviderVariables.sectionTitles.index(of: sectionText) ?? 0
        return res
    }
    
    public func sectionTextForItem(item: ModelType.ArrayElement) -> String {
        return ""
    }
    
    public var sectionCount: Int {
        return dataProviderVariables.sectionIndexes.count
    }
    
    public func itemCountInSection(section: Int) -> Int {
        let res = (dataProviderVariables.sectionIndexes[section] ?? []).count
        return res
    }
    
    public func itemAtIndexPath(indexPath: IndexPath) -> ModelType.ArrayElement? {
        if let index = dataProviderVariables.dataSourceIndexForIndexPath(indexPath) {
            return dataSource.itemAtIndex(index)
        }
        return nil
    }
    
    public func indexPathOfItem(check: (_ modelItem: ModelType.ArrayElement) -> Bool) -> IndexPath? {
        for (sectionIndex, section) in dataProviderVariables.sectionIndexes.enumerated() {
            for (itemIndex, modelItemIndex) in section.1.enumerated() {
                let modelItem = dataSource.allItems[modelItemIndex]
                if check(modelItem) {
                    return dataViewer.createIndexPath(item: itemIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }
    
    public func indexPathsOfItems(check: (_ modelItem: ModelType.ArrayElement) -> Bool) -> [IndexPath] {
        var res: [IndexPath] = []
        for (sectionIndex, section) in dataProviderVariables.sectionIndexes.enumerated() {
            for (itemIndex, modelItemIndex) in section.1.enumerated() {
                let modelItem = dataSource.allItems[modelItemIndex]
                if check(modelItem) {
                    res.append(dataViewer.createIndexPath(item: itemIndex, section: sectionIndex))
                }
            }
        }
        return res
    }
    
    fileprivate func sectionRowIndexes() -> [IndexPath] {
        return dataProviderVariables.sectionIndexes.flatMap { section, items in
            return items.enumerated().map { (index, item) in
                return self.dataViewer.createIndexPath(item: index, section: section)
            }
        }
    }
    
    fileprivate func sectionIndexes() -> IndexSet {
        var res = IndexSet()
        dataProviderVariables.sectionIndexes.forEach { section, _ in res.insert(section) }
        return res
    }
    
    fileprivate func updateSetcions() {
        dataProviderVariables.sectionTitles = []
        dataSource.forEach { item in
            let text = sectionTextForItem(item: item)
            if !self.dataProviderVariables.sectionTitles.contains(text) {
                self.dataProviderVariables.sectionTitles.append(text)
            }
        }
    }
    
    public func beforeFetch() {
        
    }
    
    public func afterFetch() {
        
    }
    
    public func fetchFromStart(completed: ((_ success: Bool) -> Void)? = nil) {
        beforeFetch()
        dataSource.model.pagingReset()
        dataSource.model.update(
            success: { _, _ in
                self.updateDataViewer { isCompleted in
                    DispatchQueue.main.async {
                        self.updateContentState()
                        completed?(isCompleted)
                    }
                }
        },
            failed: { _, _ in
                completed?(false)
        }
        )
    }
    
    public func fetchNext(completed: ((_ success: Bool) -> Void)?) {
        dataSource.model.fromIndex = dataSource.count - dataSource.model.additionalRecords
        if (dataSource.model.fromIndex != 0) && !dataProviderVariables.isFetching {
            dataProviderVariables.isFetching = true
            beforeFetch()
            dataSource.model.update(
                success: { _, _ in
                    self.updateDataViewerPage { isCompleted in
                        self.updateContentState()
                        completed?(isCompleted)
                        self.dataProviderVariables.isFetching = false
                    }
            },
                failed: { _, _ in
                    completed?(false)
                    self.dataProviderVariables.isFetching = false
            }
            )
        }
    }
    
    public func fullRefresh(showActivity: Bool = true) {
        if let canShowViewActivity = self as? CNLCanShowViewAcvtitity, showActivity {
            canShowViewActivity.startViewActivity(nil, completion: nil)
        }
        self.fetchFromStart { _ in
            if let canShowViewActivity = self as? CNLCanShowViewAcvtitity, showActivity {
                DispatchQueue.main.async {
                    canShowViewActivity.finishViewActivity()
                }
            }
        }
    }
    
    public func updateDataViewer(completed: ((_ success: Bool) -> Void)? = nil) {
        self.dataViewer.batchUpdates(
            updates: {
                let savedSectionIndexes = self.sectionIndexes()
                let savedSectionRowIndexes = self.sectionRowIndexes()
                self.dataSource.reset()
                self.dataSource.requestCompleted()
                self.updateSetcions()
                #if DEBUG
                    do {
                        let info = savedSectionIndexes
                            .map { return $0.toString }
                            .joined(separator: ",")
                        CNLLog("Delete Section\n\(info)", level: .debug)
                    }
                #endif
                self.dataViewer.deleteSections(savedSectionIndexes as IndexSet)
                #if DEBUG
                    do {
                        let info = savedSectionRowIndexes
                            .map { return "\($0.section) - \($0.row)" }
                            .joined(separator: ",")
                        CNLLog("Delete Rows\n\(info)", level: .debug)
                    }
                #endif
                self.dataViewer.deleteItemsAtIndexPaths(savedSectionRowIndexes)
                
                self.updateCounts()
                
                #if DEBUG
                    do {
                        let info = self.sectionIndexes()
                            .map { return $0.toString }
                            .joined(separator: ",")
                        CNLLog("Insert Section\n\(info)", level: .debug)
                    }
                #endif
                self.dataViewer.insertSections(self.sectionIndexes())
                #if DEBUG
                    do {
                        let info = self.sectionRowIndexes()
                            .map { return "\($0.section) - \($0.row)" }
                            .joined(separator: ",")
                        CNLLog("Insert Rows\n\(info)", level: .debug)
                    }
                #endif
                self.dataViewer.insertItemsAtIndexPaths(self.sectionRowIndexes())
                self.dataViewer.reloadData()
        },
            completion: { _ in
                self.afterFetch()
                completed?(true)
        }
        )
    }
    
    public func updateDataViewerPage(completed: ((_ success: Bool) -> Void)?) {
        let savedSections = self.dataProviderVariables.sectionIndexes
        let savedLoadMore = self.dataProviderVariables.loadMore
        
        self.dataSource.requestCompleted()
        self.updateSetcions()
        self.updateCounts()
        
        // append new sections
        var newSectionIndexes = IndexSet()
        var newRowIndexes: [IndexPath] = []
        self.dataProviderVariables.sectionIndexes.forEach { section, items in
            if let oldSection = savedSections[section] {
                items.enumerated().forEach { index, item in
                    if !oldSection.contains(item) {
                        if !savedLoadMore.visible || (section != savedLoadMore.section) || (index != 0) {
                            newRowIndexes.append(self.dataViewer.createIndexPath(item: index, section: section))
                        }
                    }
                }
            } else {
                if savedLoadMore.visible || (section != savedLoadMore.section) {
                    newSectionIndexes.insert(section)
                    items.enumerated().forEach { index, item in
                        newRowIndexes.append(self.dataViewer.createIndexPath(item: index, section: section))
                    }
                }
            }
        }
        #if DEBUG
            do {
                let info1 = newSectionIndexes
                    .map { return $0.toString }
                    .joined(separator: ",")
                CNLLog("PInsert Section\n\(info1)", level: .debug)
                let info2 = newRowIndexes
                    .map { return "\($0.section) - \($0.row)" }
                    .joined(separator: ",")
                CNLLog("PInsert Rows\n\(info2)", level: .debug)
            }
        #endif
        
        UIView.setAnimationsEnabled(false)
        self.dataViewer.batchUpdates(
            updates: {
                if savedLoadMore.visible && !self.dataProviderVariables.loadMore.visible {
                    let loadMoreSectionExists = self.dataProviderVariables.sectionIndexes[savedLoadMore.section] == nil
                    let loadMoreSectionEmpty = self.dataProviderVariables.sectionIndexes[savedLoadMore.section]?.count == 0
                    if loadMoreSectionExists || loadMoreSectionEmpty {
                        let indexPath = self.dataViewer.createIndexPath(item: 0, section: savedLoadMore.section)
                        self.dataViewer.deleteItemsAtIndexPaths([indexPath])
                        self.dataViewer.deleteSections(IndexSet([savedLoadMore.section]))
                    }
                }
                #if DEBUG
                    do {
                        let info = newSectionIndexes
                            .map { $0.toString }
                            .joined(separator: ",")
                        CNLLog("Insert Section\n\(info)", level: .debug)
                    }
                #endif
                
                self.dataViewer.insertSections(newSectionIndexes)
                
                #if DEBUG
                    do {
                        let info = newRowIndexes
                            .map { return "\($0.section) - \($0.row), " }
                            .joined(separator: ",")
                        CNLLog("Insert Rows\n\(info)", level: .debug)
                    }
                #endif
                self.dataViewer.insertItemsAtIndexPaths(newRowIndexes)
        },
            completion: { _ in
                UIView.setAnimationsEnabled(true)
                self.afterFetch()
                completed?(true)
        }
        )
    }
    
    public func initializeWith(dataSource: CNLDataSource<ModelType>, fetch: Bool = true) {
        dataViewer.initializeCells()
        self.dataSource = dataSource
        fullRefresh()
    }
    
    fileprivate func updateCountsCollectItems() -> [Int:[Int]] {
        var res: [Int:[Int]] = [:]
        dataProviderVariables.loadMore.section = 0
        for (index, item) in dataSource.allItems.enumerated() {
            let section = sectionForItem(item: item)
            var items = res[section] ?? []
            items.append(index)
            res[section] = items
            if dataSource.model.isPagingEnabled {
                dataProviderVariables.loadMore.section = max(dataProviderVariables.loadMore.section, section + 1)
            }
        }
        if !(dataSource.model.isPagingEnabled) {
            dataProviderVariables.loadMore.visible = false
        }
        return res
    }
    
    public func updateCounts() {
        let totalCount = dataSource.model.totalRecords
        let additionalCount = dataSource.model.additionalRecords
        #if DEBUG
            CNLLog("ds.c \(dataSource.count)", level: .debug)
            CNLLog("ac \(additionalCount)", level: .debug)
            CNLLog("tc \(totalCount ?? 0)", level: .debug)
            CNLLog(dataProviderVariables.loadMore.visible, level: .debug)
        #endif
        dataProviderVariables.loadMore.visible = dataSource.model.isPagingEnabled && ((totalCount == nil) || ((dataSource.count - additionalCount) != totalCount))
        
        var res = updateCountsCollectItems()
        if dataProviderVariables.loadMore.visible { res[dataProviderVariables.loadMore.section] = [0] }
        dataProviderVariables.sectionIndexes = res
    }
    
}

extension CNLDataProvider where Self.ModelType: CNLModelMetaArray {

    public func updateCounts() {
        let totalCount = dataSource.model.totalRecords
        let additionalCount = dataSource.model.additionalRecords
        #if DEBUG
            CNLLog("ds.c \(dataSource.count)", level: .debug)
            CNLLog("ac \(additionalCount)", level: .debug)
            CNLLog("tc \(totalCount ?? 0)", level: .debug)
            CNLLog(dataProviderVariables.loadMore.visible, level: .debug)
        #endif
        dataProviderVariables.loadMore.visible = dataSource.model.isPagingEnabled && ((totalCount == nil) || ((dataSource.count - additionalCount) != totalCount))
        
        var res = updateCountsCollectItems()
        if dataProviderVariables.loadMore.visible { res[dataProviderVariables.loadMore.section] = [0] }
        dataProviderVariables.sectionIndexes = res
    }
    
}
