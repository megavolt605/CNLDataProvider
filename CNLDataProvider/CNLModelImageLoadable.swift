//
//  CNLModelImageLoadable.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 28/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import UIKit
import CoreTelephony

import CNLFoundationTools

fileprivate var cancelLoadingTaskCallbacksFunc = "cancelLoadingTaskCallbacksFunc"

public protocol CNLModelDataLoadable: class {
    
    func loadData(
        _ fileName: String,
        priority: Float?,
        userData: Any?,
        success: @escaping (_ fileName: String, _ data: Data?, _ userData: Any?) -> Void,
        fail: @escaping (_ fileName: String, _ userData: Any?) -> Void
    )
    func cancelLoading()
}


extension CNLModelDataLoadable {
    
    public func loadData(
        _ fileName: String,
        priority: Float?,
        userData: Any?,
        success: @escaping CNLModelNetworkDownloadFileSuccess,
        fail: @escaping CNLModelNetworkDownloadFileFail
    ) {
        let cancelTask = CNLModelNetworkProvider?.downloadFileFromURL(
            fileName,
            priority: priority ?? 1.0,
            userData: userData,
            success: { fileName, data, userData in
                success(fileName, data, userData)
                self.cancelLoadingTaskCallbacks[fileName] = nil
            },
            fail: { fileName, error, userData in
                fail(fileName, error, userData)
                self.cancelLoadingTaskCallbacks[fileName] = nil
            }
        )
        cancelLoadingTaskCallbacks[fileName] = cancelTask
    }
    
    fileprivate var cancelLoadingTaskCallbacks: [String: CNLModelNetworkDownloadFileCancel] {
        get {
            if let value = (objc_getAssociatedObject(self, &cancelLoadingTaskCallbacksFunc) as? CNLAssociated<[String: CNLModelNetworkDownloadFileCancel]>)?.closure {
                return value
            } else {
                return [:]
            }
        }
        set {
            objc_setAssociatedObject(self, &cancelLoadingTaskCallbacksFunc, CNLAssociated<[String: CNLModelNetworkDownloadFileCancel]>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public func cancelLoading(fileName: String, userData: Any?) {
        for task in cancelLoadingTaskCallbacks {
            task.value(fileName, userData)
        }
        cancelLoadingTaskCallbacks = [:]
    }
    
}

public protocol CNLModelImageLoadable: CNLModelDataLoadable {
    func loadImage(
        _ fileName: String,
        priority: Float?,
        userData: Any?,
        success: @escaping (_ fileName: String, _ image: UIImage, _ imageData: Data, _ userData: Any?) -> Void,
        fail: @escaping (_ fileName: String, _ userData: Any?) -> Void
    )
}

extension CNLModelImageLoadable {
    
    public func loadImage(
        _ fileName: String,
        priority: Float?,
        userData: Any?,
        success: @escaping (_ fileName: String, _ image: UIImage, _ imageData: Data, _ userData: Any?) -> Void,
        fail: @escaping (_ fileName: String, _ userData: Any?) -> Void
        ) {
        let start = Date()
        
        loadData(
            fileName,
            priority: priority,
            userData: userData,
            success: { fileName, fileData, userData in
                let networkStop = Date().timeIntervalSince(start)
                if let data = fileData, let img = UIImage(data: data) {
                    #if DEBUG
                        let stop = Date().timeIntervalSince(start)
                        CNLLog(
                            "\(fileName) loaded, network time: \(floor(networkStop * 1000.0 * 1000.0) / 1000.0), " +
                            "total time: \(floor(stop * 1000.0 * 1000.0) / 1000.0) size: \(img.size.width) x \(img.size.height) \(data.count) ",
                            level: .debug
                        )
                    #endif
                    success(fileName, img, data, userData)
                } else {
                    #if DEBUG
                        CNLLog("\(fileName) loading error", level: .error)
                        if let data = fileData, let dataString = NSString(data: data, encoding: String.Encoding.utf16.rawValue) {
                            CNLLog("Received data:\n\(dataString)", level: .error)
                        }
                    #endif
                    fail(fileName, userData)
                }
        },
            fail: fail
        )
    }
    
}

public protocol CNLModelResizableImageLoadable: CNLModelImageLoadable {
    func loadImage(
        _ fileName: String,
        priority: Float?,
        userData: Any?,
        size: CGSize,
        scale: CGFloat?,
        success: @escaping (_ fileName: String, _ image: UIImage, _ imageData: Data, _ userData: Any?) -> Void,
        fail: @escaping (_ fileName: String, _ userData: Any?) -> Void
    )
}

extension CNLModelResizableImageLoadable {
    
    public func loadImage(
        _ fileName: String,
        priority: Float?,
        userData: Any?,
        size: CGSize = CGSize.zero,
        scale: CGFloat? = nil,
        success: @escaping (_ fileName: String, _ image: UIImage, _ imageData: Data, _ userData: Any?) -> Void,
        fail: @escaping (_ fileName: String, _ userData: Any?) -> Void
        ) {
        let scale = scale ?? 1.0 // imageScale()
        var newFileName = fileName
        if size.width != 0 && size.height != 0 && !fileName.contains(".gif") {
            newFileName = newFileName.appendSuffixBeforeExtension("@\(Int(scale * size.width))x\(Int(scale * size.height))")
        }
        loadImage(
            newFileName,
            priority: priority,
            userData: userData,
            success: success,
            fail: fail
        )
    }
    
    /*
    TODO
    public func imageScale() -> CGFloat {
        var scale: CGFloat = 0.0
        if let rm = CNLNetwork.network.reachabilityManager, !rm.isReachableOnEthernetOrWiFi {
            //if !CNLNetwork.network.managerAPI.reachabilityManager.reachableViaWiFi {
            if let networkType = CTTelephonyNetworkInfo().currentRadioAccessTechnology {
                switch networkType {
                case CTRadioAccessTechnologyGPRS: scale = 1.5
                case CTRadioAccessTechnologyEdge: scale = 1.0
                case CTRadioAccessTechnologyWCDMA: scale = 1.5
                case CTRadioAccessTechnologyHSDPA: scale = 1.5
                case CTRadioAccessTechnologyHSUPA: scale = 1.5
                case CTRadioAccessTechnologyCDMA1x: scale = 0.0
                case CTRadioAccessTechnologyCDMAEVDORev0: scale = 1.0
                case CTRadioAccessTechnologyCDMAEVDORevA: scale = 1.5
                case CTRadioAccessTechnologyCDMAEVDORevB: scale = 1.5
                case CTRadioAccessTechnologyeHRPD: scale = 1.0
                case CTRadioAccessTechnologyLTE: scale = 0.0
                default: scale = 0.0
                }
            }
        }
        if scale < 0.1 {
            scale = UIScreen.main.scale
        }
        return scale
    }*/
    
}
