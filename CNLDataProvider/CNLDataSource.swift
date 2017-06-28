//
//  CNLDataSource.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

/// Data source for data providers
public protocol CNLDataSourceModel: class {

    /// Type of assotiated model
    associatedtype ArrayElement: CNLModelDictionary

    /// List of cached model items
    var list: [ArrayElement] { get set }

    /// Offset for paging requests
    var fromIndex: Int { get set }
   
    /// Total number of records in the remote data source
    var totalRecords: Int? { get set }

    /// Number of additional artifical items
    var additionalRecords: Int { get set }

    /// Paging enabled flag. False by default
    var isPagingEnabled: Bool { get }

    /// Resets pagination
    func pagingReset()

    /// Resets data source
    func reset()

    /// Update data source
    func update()
    
    /// Update data source
    ///
    /// - Parameters:
    ///   - success: Callback when operation was successfull
    ///   - failed: Callback when operation was failed
    func update(success: @escaping CNLModel.Success, failed: @escaping CNLModel.Failed)

    /// Data request completed
    func requestCompleted()
    
    /// Default initializer
    init()
}

fileprivate var pagingArrayFromIndex = "fromIndex"
fileprivate var pagingArrayTotalRecords = "totalRecords"
fileprivate var pagingArrayAdditionalRecords = "additionalRecords"

public extension CNLDataSourceModel {
    
    public var defaultPageLimit: Int { return 20 }
    
    public var pageLimit: Int { return isPagingEnabled ? defaultPageLimit : -1 }
    public var isPagingEnabled: Bool { return false }
    
    public func reset() {
        list = []
    }
    
    public func pagingReset() {
        //reset()
        fromIndex = 0
        totalRecords = nil
        additionalRecords = 0
    }
    
    public final var fromIndex: Int {
        get {
            if let value = (objc_getAssociatedObject(self, &pagingArrayFromIndex) as? CNLAssociated<Int>)?.closure {
                return value
            } else {
                return 0
            }
        }
        set {
            objc_setAssociatedObject(self, &pagingArrayFromIndex, CNLAssociated<Int>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public final var totalRecords: Int? {
        get {
            if let value = (objc_getAssociatedObject(self, &pagingArrayTotalRecords) as? CNLAssociated<Int?>)?.closure {
                return value
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &pagingArrayTotalRecords, CNLAssociated<Int?>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public final var additionalRecords: Int {
        get {
            if let value = (objc_getAssociatedObject(self, &pagingArrayAdditionalRecords) as? CNLAssociated<Int>)?.closure {
                return value
            } else {
                return 0
            }
        }
        set {
            objc_setAssociatedObject(self, &pagingArrayAdditionalRecords, CNLAssociated<Int>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public func update() {
        update(success: { _ in }, failed: { _, _ in })
    }
    
    public func requestCompleted() { }

}

open class CNLDataSource<ModelType: CNLDataSourceModel> {
    public typealias ArrayElement = ModelType.ArrayElement
    
    open var model: ModelType
    
    fileprivate var list: [ArrayElement]  = [] // should not be used directly
    
    open func reset() {
        list = []
    }
    
    public init(model: ModelType) {
        self.model = model
    }
    
    public init(model: ModelType.Type) {
        self.model = model.init()
    }
    
    public init() {
        self.model = ModelType()
    }
    
    // for public use
    open var allItems: [ArrayElement] { return list }
    open var count: Int { return list.count }
    
    open func enumerated() -> EnumeratedSequence<[ArrayElement]> {
        return list.enumerated()
    }
    
    open func forEach(_ iterator: (ArrayElement) -> Void) {
        list.forEach(iterator)
    }
    
    open func itemAtIndex(_ index: Int) -> ArrayElement {
        return list[index]
    }
    
    open func replaceList(_ newList: [ArrayElement]) {
        list = newList
    }
    
    open func requestCompleted() {
        list.append(contentsOf: model.list)
    }
    
    var isPagingEnabled: Bool {
        return model.isPagingEnabled
    }
    
    func update(success: @escaping CNLModel.Success, failed: @escaping CNLModel.Failed) {
        model.update(success: success, failed: failed)
    }
    
}
