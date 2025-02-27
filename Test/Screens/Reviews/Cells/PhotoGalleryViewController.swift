import UIKit
import Combine

final class PhotoGalleryViewController: UIViewController {
    
    // MARK: - Properties
    private let photoURLs: [URL]
    private let reviewText: NSAttributedString
    private let imageProvider: ImageProvider
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 0
    private let initialPhotoIndex: Int
    
    private lazy var pageViewController: UIPageViewController = {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageVC.dataSource = self
        pageVC.delegate = self
        return pageVC
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = photoURLs.count
        pageControl.currentPage = initialPhotoIndex
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.attributedText = reviewText
        textView.isEditable = false
        textView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        textView.textColor = .white
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(dismissGallery), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(photoURLs: [URL], reviewText: NSAttributedString, imageProvider: ImageProvider, initialPhotoIndex: Int = 0) {
        self.photoURLs = photoURLs
        self.reviewText = reviewText
        self.imageProvider = imageProvider
        self.initialPhotoIndex = min(initialPhotoIndex, max(0, photoURLs.count - 1))
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let initialPhotoVC = photoViewController(at: initialPhotoIndex) {
            currentPage = initialPhotoIndex
            pageViewController.setViewControllers([initialPhotoVC], direction: .forward, animated: false)
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.didMove(toParent: self)
        
        view.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        view.addSubview(textView)
        let textViewHeight = min(200, view.bounds.height / 3)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -8),
            textView.heightAnchor.constraint(equalToConstant: textViewHeight)
        ])
        
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Actions
    @objc private func dismissGallery() {
        dismiss(animated: true)
    }
    
    // MARK: - Helpers
    private func photoViewController(at index: Int) -> UIViewController? {
        guard index >= 0 && index < photoURLs.count else { return nil }
        
        let photoVC = PhotoPageViewController(url: photoURLs[index], imageProvider: imageProvider)
        photoVC.pageIndex = index
        return photoVC
    }
    
    private func updatePageControl() {
        pageControl.currentPage = currentPage
    }
}

// MARK: - UIPageViewControllerDataSource
extension PhotoGalleryViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let photoVC = viewController as? PhotoPageViewController else { return nil }
        let prevIndex = photoVC.pageIndex - 1
        return photoViewController(at: prevIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let photoVC = viewController as? PhotoPageViewController else { return nil }
        let nextIndex = photoVC.pageIndex + 1
        return photoViewController(at: nextIndex)
    }
}

// MARK: - UIPageViewControllerDelegate
extension PhotoGalleryViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let currentPhotoVC = pageViewController.viewControllers?.first as? PhotoPageViewController {
            currentPage = currentPhotoVC.pageIndex
            updatePageControl()
        }
    }
}

// MARK: - PhotoPageViewController
final class PhotoPageViewController: UIViewController {
    var pageIndex = 0
    private let url: URL
    private let imageProvider: ImageProvider
    private var cancellable: AnyCancellable?
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    init(url: URL, imageProvider: ImageProvider) {
        self.url = url
        self.imageProvider = imageProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadImage() {
        activityIndicator.startAnimating()
        
        cancellable = imageProvider.loadImage(from: url)
            .sink { [weak self] image in
                self?.imageView.image = image
                self?.activityIndicator.stopAnimating()
            }
    }
}
