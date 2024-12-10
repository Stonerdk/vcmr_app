import Foundation
import Accelerate
import SwiftPriorityQueue


func computeTopKSimilarities(input: [Float], embeddingsData: MusicEmbeddingsData, topK: Int) -> [MusicInfo] {
    let embeddingDim = 256
    let numEmbeddings = embeddingsData.embeddings.count / embeddingDim
    
    guard input.count == embeddingDim else {
        print("입력 벡터의 차원이 올바르지 않습니다.")
        return []
    }
    
    var similarities = [Float](repeating: 0, count: numEmbeddings)
    
    // 내적 계산
    vDSP_mmul(embeddingsData.embeddings, 1, input, 1, &similarities, 1, vDSP_Length(numEmbeddings), 1, vDSP_Length(embeddingDim))
    
    // 우선순위 큐 생성: 낮은 유사도가 우선 (최소 힙)
    var priorityQueue = PriorityQueue<MusicInfo>(ascending: true)
    
    for i in 0..<numEmbeddings {
        let similarity = similarities[i]
        let musicInfo = MusicInfo(title: embeddingsData.tracks[i], artist: embeddingsData.artists[i], score: similarity)
        
        if priorityQueue.count < topK {
            priorityQueue.push(musicInfo)
        } else if similarity > priorityQueue.peek()?.score ?? Float(-1e9) {
            _ = priorityQueue.pop()
            priorityQueue.push(musicInfo)
        }
    }
    
    var topKResults: [MusicInfo] = []
    while let musicInfo = priorityQueue.pop() {
        topKResults.append(musicInfo)
    }
    
    // 내림차순으로 정렬
    topKResults.sort { $0.score > $1.score }
    
    return topKResults
}
