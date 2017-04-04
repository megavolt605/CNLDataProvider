//
//  CNLDataSource.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

public protocol CNLDataSourceModel {
    associatedtype ArrayElement: CNLModelDictionary
    var list: [ArrayElement] { get set }
    func reset()
    init()
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
    
    open func requestPrepared() {
        model.reset()
    }
    
}

public extension CNLDataSource where ModelType: CNLModelArray {
    
    func requestCompleted() {
        list.append(contentsOf: model.list)
    }
    
}
