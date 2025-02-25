import UIKit
import Foundation

public protocol ImageCacheType: AnyObject {
    /// Возвращяет изображение по URL
    func image(for url: URL) -> UIImage?
    /// Созраняет в кэш изображение по URL
    func insertImage(_ image: UIImage?, for url: URL)
    /// Удаляет изображение из кэша по URL
    func removeImage(for url: URL)
    /// Удаляет все изображения из кэша
    func removeAllImages()
    /// Доступ к значению (read/write) по ключу (URL)
    subscript(_ url: URL) -> UIImage? { get set }
}
