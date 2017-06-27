//
//  CNLModelMetaArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public struct CNLModelMetaArrayInfo<T> {
    public var model: T
    public var count: Int = 0
    public init(model: T) {
        self.model = model
    }
}

public protocol CNLModelMetaArray: class, CNLModelObject, CNLModelArray {
    associatedtype MetaArrayItem = CNLModelMetaArrayItem
    //typealias CNLModelMetaArrayInfo = (model: MetaArrayItem, count: Int)
    
    var list: [ArrayElement] { get set }
    var metaInfos: [CNLModelMetaArrayInfo<MetaArrayItem>] { get set }
    var ignoreFails: Bool { get }
}

fileprivate var ignoreFailsKey = "ignoreFails"
fileprivate var pagingArrayFromIndex = "fromIndex"

public extension CNLModelMetaArray where MetaArrayItem: CNLModelMetaArrayItem, MetaArrayItem.ArrayElement == ArrayElement {

    public final var ignoreFails: Bool {
        get {
            if let value = (objc_getAssociatedObject(self, &ignoreFailsKey) as? CNLAssociated<Bool>)?.closure {
                return value
            } else {
                return false
            }
        }
        set {
            objc_setAssociatedObject(self, &ignoreFailsKey, CNLAssociated<Bool>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
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
            if let index = (metaInfos.index { return $0.model.isPagingEnabled }) {
                let pager = metaInfos[index]
                pager.model.fromIndex = newValue//pager.count
            }
        }
    }
    
    public func update(success: @escaping CNLModel.Success, failed: @escaping CNLModel.Failed) {
        updateMetaArray(success: success, failed: failed)
    }
    
    public func updateMetaArray(success: @escaping CNLModel.Success, failed: @escaping CNLModel.Failed) {
        
        var count = metaInfos.count
        
        let sem = DispatchSemaphore(value: 0)
        let signal: () -> Void = { count -= 1; if count == 0 { sem.signal() } }
        
        var wasFailed = false
        var wasFailedError: CNLModel.Error?
        var successStatus: CNLModel.Error?
        
        list = []
        
        metaInfos.forEach { item in
            item.model.update(
                success: { _, status in
                    successStatus = status
                    signal()
                },
                failed: { _, error in
                    wasFailed = true
                    wasFailedError = error
                    signal()
                }
            )
        }
        asyncGlobal {
            sem.wait()
            syncMain {
                if !self.ignoreFails && wasFailed {
                    failed(self, wasFailedError)
                } else {
                    self.list = self.metaInfos.flatMap { return $0.model.list }
                    self.totalRecords = self.metaInfos.reduce(0) {
                        #if DEBUG
                            CNLLog($0.1.model.totalRecords ?? 0, level: .debug)
                        #endif
                        if !$0.1.model.isPagingEnabled {
                            return $0.0 ?? 0
                        }
                        return ($0.0 ?? 0) + ($0.1.model.totalRecords ?? 0)
                    }
                    #if DEBUG
                        CNLLog(self.totalRecords ?? 0, level: .debug)
                    #endif
                    var infos = self.metaInfos
                    self.metaInfos.enumerated().forEach { index, info in
                        #if DEBUG
                            CNLLog(info.model.list.count, level: .debug)
                        #endif
                        infos[index].count += info.model.list.count
                        if !info.model.isPagingEnabled {
                            self.additionalRecords += info.model.list.count
                        }
                    }
                    self.metaInfos = infos
                    if let status = successStatus {
                        success(self, status)
                    }
                }
            }
        }
    }

    public func reset() {
        list = []
        totalRecords = nil
        additionalRecords = 0
        var infos = metaInfos
        metaInfos.enumerated().forEach { index, _ in
            infos[index].count = 0
            infos[index].model.reset()
        }
        metaInfos = infos
    }
    
    public func pagingReset() {
        reset()
    }
    
}

public protocol CNLModelMetaArrayItem: CNLModelArray {
    
}
