/// Модель отзыва.
struct Review: Codable {
    var firstName: String
    var lastName: String
    var avatarStringURL: String
    var rating: Int
    var text: String
    var created: String
    var photoURLs: [String]
    var isValid: Bool

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarStringURL = "avatar_url"
        case rating
        case text
        case created
        case photoURLs = "photo_urls"
    }
    
    init(from decoder: any Decoder) {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.firstName = try container.decode(String.self, forKey: .firstName)
            self.lastName = try container.decode(String.self, forKey: .lastName)
            self.avatarStringURL = (try? container.decode(String.self, forKey: .avatarStringURL)) ?? ""
            self.rating = try container.decode(Int.self, forKey: .rating)
            self.text = try container.decode(String.self, forKey: .text)
            self.created = try container.decode(String.self, forKey: .created)
            self.photoURLs = (try? container.decode([String].self, forKey: .photoURLs)) ?? []
            if photoURLs.count > 5 {
                self.photoURLs = Array(photoURLs[..<5])
            }
            self.isValid = true
        } catch {
            self.firstName = ""
            self.lastName = ""
            self.avatarStringURL = ""
            self.rating = 0
            self.text = ""
            self.created = ""
            self.photoURLs = []
            self.isValid = false
        }
    }
}
