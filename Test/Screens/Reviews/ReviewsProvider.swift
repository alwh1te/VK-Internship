import Foundation

/// Класс для загрузки отзывов.
final class ReviewsProvider {

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

}

// MARK: - Internal

extension ReviewsProvider {

    typealias GetReviewsResult = Result<Data, GetReviewsError>

    enum GetReviewsError: Error {

        case badURL
        case badData(Error)

    }

    func getReviews(offset: Int = 0, completion: @escaping (GetReviewsResult) -> Void) {
        guard let url = bundle.url(forResource: "getReviews.response", withExtension: "json") else {
            print("❌ Failed to find JSON file")
            return completion(.failure(.badURL))
        }
        DispatchQueue.global().async {
            // Симулируем сетевой запрос - не менять
            usleep(.random(in: 100_000...1_000_000))

            do {
                let allData = try Data(contentsOf: url)
                
                if offset == 0 {
                    do {
                        let decoder = JSONDecoder()
                        let allReviews = try decoder.decode(Reviews.self, from: allData)
                        
                        let pageLimit = min(20, allReviews.items.count)
                        let pageItems = Array(allReviews.items[0..<pageLimit])
                        let pageReviews = Reviews(items: pageItems, count: allReviews.count)
                        
                        let pageData = try JSONEncoder().encode(pageReviews)
                        completion(.success(pageData))
                    } catch {
                        completion(.success(allData))
                    }
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let allReviews = try decoder.decode(Reviews.self, from: allData)
                    
                    if offset >= allReviews.items.count {
                        let emptyReviews = Reviews(items: [], count: allReviews.count)
                        let emptyData = try JSONEncoder().encode(emptyReviews)
                        completion(.success(emptyData))
                        return
                    }
                    
                    let startIndex = offset
                    let endIndex = min(offset + 20, allReviews.items.count)
                    
                    let pageItems = Array(allReviews.items[startIndex..<endIndex])
                    let pageReviews = Reviews(items: pageItems, count: allReviews.count)
                    
                    let pageData = try JSONEncoder().encode(pageReviews)
                    completion(.success(pageData))
                } catch {
                    completion(.failure(.badData(error)))
                }
            } catch {
                completion(.failure(.badData(error)))
            }
        }
    }
}
