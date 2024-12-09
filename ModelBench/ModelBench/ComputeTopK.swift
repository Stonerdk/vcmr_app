//
//  ComputeTopK.swift
//  ModelBench
//
//  Created by kdk on 12/9/24.
//

import Foundation
import Accelerate

struct Heap<Element> {
    var elements: [Element]
    let priorityFunction: (Element, Element) -> Bool
    
    init(priorityFunction: @escaping (Element, Element) -> Bool) {
        self.elements = []
        self.priorityFunction = priorityFunction
    }
    
    var isEmpty: Bool { return elements.isEmpty }
    var count: Int { return elements.count }
    
    func peek() -> Element? { return elements.first }
    
    mutating func insert(_ value: Element) {
        elements.append(value)
        siftUp(from: elements.count - 1)
    }
    
    mutating func remove() -> Element? {
        guard !elements.isEmpty else { return nil }
        if elements.count == 1 {
            return elements.removeFirst()
        } else {
            let value = elements[0]
            elements[0] = elements.removeLast()
            siftDown(from: 0)
            return value
        }
    }
    
    mutating private func siftUp(from index: Int) {
        var childIndex = index
        let child = elements[childIndex]
        var parentIndex = (childIndex - 1) / 2
        
        while childIndex > 0 && priorityFunction(child, elements[parentIndex]) {
            elements[childIndex] = elements[parentIndex]
            childIndex = parentIndex
            parentIndex = (childIndex - 1) / 2
        }
        elements[childIndex] = child
    }
    
    mutating private func siftDown(from index: Int) {
        var parentIndex = index
        let count = elements.count
        let parent = elements[parentIndex]
        
        while true {
            let leftChildIndex = 2 * parentIndex + 1
            let rightChildIndex = leftChildIndex + 1
            var candidate = parentIndex
            
            if leftChildIndex < count && priorityFunction(elements[leftChildIndex], elements[candidate]) {
                candidate = leftChildIndex
            }
            if rightChildIndex < count && priorityFunction(elements[rightChildIndex], elements[candidate]) {
                candidate = rightChildIndex
            }
            if candidate == parentIndex { break }
            elements[parentIndex] = elements[candidate]
            parentIndex = candidate
        }
        elements[parentIndex] = parent
    }
}

func computeTopKSimilarities(input: [Float], embeddingsData: MusicEmbeddingsData, topK: Int) -> [(String, String)]? {
    let embeddingDim = 256
    let numEmbeddings = embeddingsData.embeddings.count / embeddingDim
    
    guard input.count == embeddingDim else {
        print("입력 벡터의 차원이 올바르지 않습니다.")
        return nil
    }
    
    var similarities = [Float](repeating: 0, count: numEmbeddings)
    
    vDSP_mmul(embeddingsData.embeddings, 1, input, 1, &similarities, 1, vDSP_Length(numEmbeddings), 1, 256)

    var minHeap = Heap<(Float, Int)>(priorityFunction: { $0.0 < $1.0 })
    
    for i in 0..<numEmbeddings {
        let similarity = similarities[i]
        if minHeap.count < topK {
            minHeap.insert((similarity, i))
        } else if similarity > minHeap.peek()!.0 {
            _ = minHeap.remove()
            minHeap.insert((similarity, i))
        }
    }
    
    var topKResults: [(String, String)] = []
    while let element = minHeap.remove() {
        topKResults.append((embeddingsData.tracks[element.1], embeddingsData.artists[element.1]))
    }
    
    topKResults.sort { $0 > $1 }
    
    return topKResults
}

// 사용 예시

//if let musicEmbeddings = loadMusicEmbeddingsOptimized() {
//    let inputVector: [Float] = Array(repeating: 0.5, count: 256) // 실제 입력 벡터로 대체
//    let topK = 5
//    if let topKResults = computeTopKSimilarities(input: inputVector, embeddingsData: musicEmbeddings, topK: topK) {
//        print("Top-\(topK) 유사도 결과:")
//        for result in topKResults {
//            print("파일명: \(result.0), 유사도: \(result.1)")
//        }
//    } else {
//        print("유사도 계산 실패")
//    }
//} else {
//    print("임베딩 데이터를 로드할 수 없습니다.")
//}
