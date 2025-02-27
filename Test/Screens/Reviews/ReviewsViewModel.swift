import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?
    
    weak var delegate: ReviewsViewModelDelegate?

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder
    private let imageProvider: ImageProvider

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder(),
        imageProvider: ImageProvider = ImageProvider.shared
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
        self.imageProvider = imageProvider
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }

    /// Метод обновления счетчика отзывов.
    func updateReviewsCount(_ label: UILabel) {
        let count = state.items.count
        label.text = "\(count) \(pluralizeReviews(count))"
    }
    
    private func pluralizeReviews(_ count: Int) -> String {
        let cases = ["отзыв", "отзыва", "отзывов"]
        let remainder100 = count % 100
        let remainder10 = count % 10
        
        if remainder100 >= 11 && remainder100 <= 19 {
            return cases[2]
        }
        
        switch remainder10 {
            case 1: return cases[0]
            case 2...4: return cases[1]
            default: return cases[2]
        }
    }
}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            print("📦 Got data: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            let reviews = try decoder.decode(Reviews.self, from: data)
            print("✅ Decoded reviews count: \(reviews.items.count)")
            
            let newItems = reviews.items.map(makeReviewItem)
            print("🔄 Created items count: \(newItems.count)")
            
            state.items += newItems
            print("📊 Total items in state: \(state.items.count)")
            
            state.offset += state.limit
            state.shouldLoad = state.offset < reviews.count
        } catch {
            print("❌ Decoding error: \(error)")
            state.shouldLoad = true
        }
        onStateChange?(state)
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }

}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let userName = "\(review.firstName) \(review.lastName)"
        let reviewText = review.text.attributed(font: .systemFont(ofSize: 14))
        let created = review.created.attributed(font: .systemFont(ofSize: 12), color: .gray)
        
        let avatarURL = URL(string: review.avatarStringURL)
        let photoURLs = review.photoURLs.compactMap { URL(string: $0) }

        let item = ReviewItem(
            userName: userName,
            avatarURL: avatarURL,
            rating: review.rating,
            reviewText: reviewText,
            created: created,
            photoURLs: photoURLs,
            onTapPhoto: { [weak self] uuid, index in
                guard let self = self else { return }
                if let reviewItem = self.state.items.first(where: { ($0 as? ReviewItem)?.id == uuid }) as? ReviewItem {
                    self.delegate?.reviewsViewModel(self, didTapPhotoAt: index, in: reviewItem)
                }
            },
            onTapShowMore: { [weak self] uuid in
                self?.showMoreReview(with: uuid)
            },
            ratingRender: ratingRenderer,
            imageProvider: imageProvider
        )
        return item
    }
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
