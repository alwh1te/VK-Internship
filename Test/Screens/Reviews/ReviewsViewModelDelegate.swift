
protocol ReviewsViewModelDelegate: AnyObject {
    func reviewsViewModel(_ viewModel: ReviewsViewModel, didTapPhotoAt photoIndex: Int, in review: ReviewCellConfig)
}
