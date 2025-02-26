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
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.avatarStringURL = (try? container.decode(String.self, forKey: .avatarStringURL)) ?? ""
        self.rating = try container.decode(Int.self, forKey: .rating)
        self.text = try container.decode(String.self, forKey: .text)
        self.created = try container.decode(String.self, forKey: .created)
    }
}
