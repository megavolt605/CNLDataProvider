//
//  CNLModelMetaArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public protocol CNLModelMetaArray: class, CNLModelObject, CNLModelArray {
    associatedtype MetaArrayItem = CNLModelMetaArrayItem
    
    var list: [ArrayElement] { get set }
    var metaItems: [MetaArrayItem] { get set }
    var ignoreFails: Bool { get }
}

fileprivate var ignoreFailsKey = "ignoreFails"

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

    public func update(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed) {
        updateMetaArray(success: success, failed: failed)
    }
    
    public func updateMetaArray(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed) {
        
        var count = metaItems.count
        
        let sem = DispatchSemaphore(value: 0)
        let signal: () -> Void = { count -= 1; if count == 0 { sem.signal() } }
        
        var wasFailed = false
        var wasFailedError: CNLModelError?
        var successStatus: CNLModelError?
        
        list = []
        
        metaItems.forEach { item in
            item.update(
                success: { model, status in
                    successStatus = status
                    signal()
                },
                failed: { model, error in
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
                    self.list = self.metaItems.flatMap { return $0.list }
                    self.totalRecords = self.list.count
                    if let status = successStatus {
                        success(self, status)
                    }
                }
            }
        }
    }

}

public protocol CNLModelMetaArrayItem: CNLModelArray {
    
}
