final class ReviewsScreenFactory {
    
    private weak var cachedReviewsController: ReviewsViewController?
    private let reviewsProvider = ReviewsProvider()

    /// Создаёт контроллер списка отзывов, проставляя нужные зависимости.
    func makeReviewsController() -> ReviewsViewController {
        if let cachedController = cachedReviewsController {
            return cachedController
        }
        
        let viewModel = ReviewsViewModel(reviewsProvider: reviewsProvider)
        let controller = ReviewsViewController(viewModel: viewModel)
        
        cachedReviewsController = controller
        
        return controller
    }

}
