//
//  CNLCanShowViewActivity.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

public protocol CNLCanShowViewAcvtitity {
    func startViewActivity(_ closure: (() -> Void)?, completion: (() -> Void)?)
    func finishViewActivity()
}
