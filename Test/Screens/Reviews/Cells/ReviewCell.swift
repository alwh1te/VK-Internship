import UIKit
import Combine

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)

    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Имя пользователя, которое будет отображено.
    let userName: String
    /// Ссылка на аватарку.
    let avatarURL: URL?
    /// Рейтинг отзыва
    let rating: Int
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    /// Класс для рендеринга рейтинга.
    let ratingRender: RatingRenderer
    /// КЛасс для загрузки кешированных изображений.
    let imageProvider: ImageProvider

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()

}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        
        cell.userNameLabel.text = userName

        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.ratingImageView.image = ratingRender.ratingImage(rating)
        cell.config = self
        
        if maxLines > 0 {
            cell.reviewTextLabel.numberOfLines = 0
            let fullSize = cell.reviewTextLabel.sizeThatFits(
                CGSize(width: cell.contentView.bounds.width - 24, height: CGFloat.greatestFiniteMagnitude)
            )
            
            cell.reviewTextLabel.numberOfLines = maxLines
            let truncatedSize = cell.reviewTextLabel.sizeThatFits(
                CGSize(width: cell.contentView.bounds.width - 24, height: CGFloat.greatestFiniteMagnitude)
            )
            
            let needsShowMoreButton = fullSize.height > truncatedSize.height
            cell.showMoreButton.isHidden = !needsShowMoreButton
        } else {
            cell.showMoreButton.isHidden = true
        }
        
        cell.showMoreButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.showMoreButton.addAction(UIAction { [id, onTapShowMore] _ in
            onTapShowMore(id)
        }, for: .touchUpInside)

        if let url = avatarURL {
            cell.avatarCancellable = imageProvider.loadImage(from: url)
                .sink { [weak cell] image in
                    cell?.userImageView.image = image ?? UIImage(named: "default_avatar")
                }
        } else {
            cell.userImageView.image = UIImage(named: "default_avatar")
        }
        cell.updateCreatedLabelConstraints(showMoreButtonVisible: !cell.showMoreButton.isHidden)
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        return UITableView.automaticDimension
    }

}

// MARK: - Private

private extension ReviewCellConfig {

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    fileprivate var config: Config?

    fileprivate var avatarCancellable: AnyCancellable?

    fileprivate let userImageView = UIImageView()
    fileprivate let userNameLabel = UILabel()
    fileprivate let ratingImageView = UIImageView()
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()
    
    private var createdLabelTopToShowMoreConstraint: NSLayoutConstraint!
    private var createdLabelTopToReviewTextConstraint: NSLayoutConstraint!

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarCancellable?.cancel()
        userImageView.image = nil
        userNameLabel.text = nil
        reviewTextLabel.attributedText = nil
        createdLabel.attributedText = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
    }

}

// MARK: - Private

private extension ReviewCell {

    func setupCell() {
        addSubviews()
        setupUserImageView()
        setupUserNameLabel()
        setupRatingView()
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
        setupLayout()
    }
    
    func addSubviews() {
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(ratingImageView)
        contentView.addSubview(reviewTextLabel)
        contentView.addSubview(createdLabel)
        contentView.addSubview(showMoreButton)
    }
    
    func setupLayout() {
        let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
        
        createdLabelTopToShowMoreConstraint = createdLabel.topAnchor.constraint(
            equalTo: showMoreButton.bottomAnchor, constant: 8)
        
        createdLabelTopToReviewTextConstraint = createdLabel.topAnchor.constraint(
            equalTo: reviewTextLabel.bottomAnchor, constant: 8)
        
        NSLayoutConstraint.activate([
            userImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
            userImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
            userImageView.widthAnchor.constraint(equalToConstant: Layout.avatarSize.width),
            userImageView.heightAnchor.constraint(equalToConstant: Layout.avatarSize.height),
            
            userNameLabel.topAnchor.constraint(equalTo: userImageView.topAnchor),
            userNameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 8),
            userNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -insets.right),
            
            ratingImageView.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 4),
            ratingImageView.leadingAnchor.constraint(equalTo: userNameLabel.leadingAnchor),
            
            reviewTextLabel.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 12),
            reviewTextLabel.leadingAnchor.constraint(equalTo: userNameLabel.leadingAnchor),
            reviewTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
            
            showMoreButton.topAnchor.constraint(equalTo: reviewTextLabel.bottomAnchor, constant: 4),
            showMoreButton.leadingAnchor.constraint(equalTo: reviewTextLabel.leadingAnchor),
            
            createdLabel.topAnchor.constraint(equalTo: showMoreButton.bottomAnchor, constant: 8),
            createdLabel.leadingAnchor.constraint(equalTo: userNameLabel.leadingAnchor),
            createdLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
            createdLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom)
        ])
        
        updateCreatedLabelConstraints(showMoreButtonVisible: !showMoreButton.isHidden)
    }
    
    func setupUserImageView() {
        userImageView.contentMode = .scaleAspectFill
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = ReviewCellLayout.avatarCornerRadius
        userImageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupUserNameLabel() {
        userNameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupRatingView() {
        ratingImageView.contentMode = .left
        ratingImageView.clipsToBounds = true
        ratingImageView.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupReviewTextLabel() {
        reviewTextLabel.numberOfLines = 0
        reviewTextLabel.translatesAutoresizingMaskIntoConstraints = false
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }

    func setupCreatedLabel() {
        createdLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupShowMoreButton() {
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func updateCreatedLabelConstraints(showMoreButtonVisible: Bool) {
        createdLabelTopToShowMoreConstraint.isActive = false
        createdLabelTopToReviewTextConstraint.isActive = false
        
        if showMoreButtonVisible {
            createdLabelTopToShowMoreConstraint.isActive = true
        } else {
            createdLabelTopToReviewTextConstraint.isActive = true
        }
    }

}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0

    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()

    // MARK: - Фреймы

    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0

    // MARK: - Расчёт фреймов и высоты ячейки

    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - insets.left - insets.right

        var maxY = insets.top
        var showShowMoreButton = false

        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight

            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: insets.left, y: maxY),
                size: config.reviewText.boundingRect(width: width, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: insets.left, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        createdLabelFrame = CGRect(
            origin: CGPoint(x: insets.left, y: maxY),
            size: config.created.boundingRect(width: width).size
        )

        return createdLabelFrame.maxY + insets.bottom
    }

}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
