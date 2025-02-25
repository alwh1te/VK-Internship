/// Модель отзыва.
struct Review: Decodable {
    let firstName: String
    let lastName: String
    let avatarStringURL: String
    let rating: Int
    let text: String
    let created: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarStringURL = "avatar_url"
        case rating
        case text
        case created
    }
}
