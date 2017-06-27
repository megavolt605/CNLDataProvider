//
//  CNLDataSource.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public protocol CNLDataSourceModel: class {
    associatedtype ArrayElement: CNLModelDictionary
    var list: [ArrayElement] { get set }
    var fromIndex: Int { get set }
    var totalRecords: Int? { get set }
    var additionalRecords: Int { get set }
    var isPagingEnabled: Bool { get }
    func pagingReset()
    func reset()
    func update()
    func update(success: @escaping CNLModel.Success, failed: @escaping CNLModel.Failed)
    func requestCompleted()
    
    init()
}

fileprivate var pagingArrayFromIndex = "fromIndex"
fileprivate var pagingArrayTotalRecords = "totalRecords"
fileprivate var pagingArrayAdditionalRecords = "additionalRecords"

public extension CNLDataSourceModel {
    
    public var pageLimit: Int { return isPagingEnabled ? kCNLModelDefaultPageLimit : -1 }
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
