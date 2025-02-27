import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        viewModel.getReviews()
    }

}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        reviewsView.tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCellConfig.reuseId)
        return reviewsView
    }

    func setupViewModel() {
        viewModel.delegate = self
        viewModel.onStateChange = { [weak self] state in
            print("🔄 Reloading table view with \(state.items.count) items")
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.reviewsView.tableView.reloadData()
                self.viewModel.updateReviewsCount(self.reviewsView.reviewsCounterLabel)
            }
        }
    }
    
    func onTapReview(with vc: UIViewController) {
        present(vc, animated: true)
    }
}

extension ReviewsViewController: ReviewsViewModelDelegate {
    func reviewsViewModel(_ viewModel: ReviewsViewModel, didTapPhotoAt photoIndex: Int, in review: ReviewCellConfig) {
        let galleryVC = PhotoGalleryViewController(
            photoURLs: review.photoURLs,
            reviewText: review.reviewText,
            imageProvider: review.imageProvider,
            initialPhotoIndex: photoIndex
        )
        
        onTapReview(with: galleryVC)
    }
}
