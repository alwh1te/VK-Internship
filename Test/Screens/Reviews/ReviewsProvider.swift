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
                let data = try Data(contentsOf: url)
                print("📄 Successfully loaded JSON data: \(String(data: data, encoding: .utf8) ?? "nil")")
                completion(.success(data))
            } catch {
                print("❌ Failed to load JSON data: \(error)")
                completion(.failure(.badData(error)))
            }
        }
    }

}
