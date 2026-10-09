import Foundation

public enum SupportedSite: String, CaseIterable {
    case youtube = "YouTube"
    case vimeo = "Vimeo"
    case dailymotion = "Dailymotion"
    case facebook = "Facebook"
    case instagram = "Instagram"
    case twitter = "Twitter/X"
    case tiktok = "TikTok"
    case reddit = "Reddit"
    case twitch = "Twitch"
    case soundcloud = "SoundCloud"
    case generic = "Generic"
    
    public var domain: String {
        switch self {
        case .youtube: return "youtube.com, youtu.be"
        case .vimeo: return "vimeo.com"
        case .dailymotion: return "dailymotion.com"
        case .facebook: return "facebook.com, fb.watch"
        case .instagram: return "instagram.com"
        case .twitter: return "twitter.com, x.com"
        case .tiktok: return "tiktok.com"
        case .reddit: return "reddit.com"
        case .twitch: return "twitch.tv"
        case .soundcloud: return "soundcloud.com"
        case .generic: return "*"
        }
    }
    
    public var supportsMultipleQualities: Bool {
        switch self {
        case .youtube, .vimeo, .dailymotion, .facebook, .twitch:
            return true
        default:
            return false
        }
    }
    
    public var supportedFormats: [String] {
        switch self {
        case .youtube, .vimeo, .dailymotion, .facebook, .instagram, .twitter, .tiktok, .reddit:
            return ["mp4"]
        case .twitch:
            return ["mp4", "m3u8"]
        case .soundcloud:
            return ["mp3"]
        case .generic:
            return ["mp4", "webm", "mov", "avi", "mkv"]
        }
    }
    
    public static func site(from urlString: String) -> SupportedSite? {
        guard let url = URL(string: urlString) else { return nil }
        let host = url.host?.lowercased() ?? ""
        
        for site in SupportedSite.allCases {
            let domains = site.domain.components(separatedBy: ", ")
            for domain in domains {
                if host.contains(domain.replacingOccurrences(of: ".", with: "")) || 
                   host.hasSuffix(domain) ||
                   domain == "*" {
                    return site
                }
            }
        }
        
        return nil
    }
}
