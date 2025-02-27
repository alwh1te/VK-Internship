import UIKit

final class ReviewsView: UIView {

    let tableView = UITableView()
    let reviewsCounterLabel = UILabel()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
}

// MARK: - Private

private extension ReviewsView {

    func setupView() {
        backgroundColor = .systemBackground
        setupTableView()
        setupReviewsCounterLabel()
    }
    
    func setupReviewsCounterLabel() {
        reviewsCounterLabel.textAlignment = .center
        reviewsCounterLabel.font = .systemFont(ofSize: 14, weight: .regular)
        reviewsCounterLabel.textColor = .gray
        reviewsCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 44))
        footerView.addSubview(reviewsCounterLabel)
        
        NSLayoutConstraint.activate([
            reviewsCounterLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            reviewsCounterLabel.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            reviewsCounterLabel.topAnchor.constraint(equalTo: footerView.topAnchor),
            reviewsCounterLabel.bottomAnchor.constraint(equalTo: footerView.bottomAnchor)
        ])
        
        tableView.tableFooterView = footerView
    }

    func setupTableView() {
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
        
        tableView.separatorStyle = .none
        tableView.allowsSelection = true
        tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCellConfig.reuseId)
    }

}
