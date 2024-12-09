//
//  Utils.swift
//  ModelBench
//
//  Created by kdk on 12/9/24.
//

import CoreML

func convertMLMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
    let count = multiArray.count
    var floatArray = [Float](repeating: 0, count: count)
    guard multiArray.dataType == .float32 else {
        fatalError("MLMultiArray 데이터 타입이 Float32가 아닙니다.")
    }
    
    for i in 0..<count {
        floatArray[i] = multiArray[i].floatValue
    }
    
    return floatArray
}
