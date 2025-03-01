/// Модель отзывов.
struct Reviews: Codable {

    /// Модели отзывов.
    let items: [Review]
    /// Общее количество отзывов.
    let count: Int

}
