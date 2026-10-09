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
    case rumble = "Rumble"
    case odysee = "Odysee"
    case peertube = "PeerTube"
    case mastodon = "Mastodon"
    case bluesky = "Bluesky"
    case threads = "Threads"
    case snapchat = "Snapchat"
    case linkedin = "LinkedIn"
    case pinterest = "Pinterest"
    case telegram = "Telegram"
    case discord = "Discord"
    case imgur = "Imgur"
    case gifur = "Gfycat"
    case streamable = "Streamable"
    case wistia = "Wistia"
    case brightcove = "Brightcove"
    case jwplayer = "JW Player"
    
    public var domain: String {
        switch self {
        case .youtube: return "youtube.com, youtu.be, youtube-nocookie.com"
        case .vimeo: return "vimeo.com"
        case .dailymotion: return "dailymotion.com"
        case .facebook: return "facebook.com, fb.watch, fb.com"
        case .instagram: return "instagram.com, instagr.am"
        case .twitter: return "twitter.com, x.com, mobile.twitter.com"
        case .tiktok: return "tiktok.com, www.tiktok.com"
        case .reddit: return "reddit.com, www.reddit.com, old.reddit.com, new.reddit.com"
        case .twitch: return "twitch.tv, www.twitch.tv"
        case .soundcloud: return "soundcloud.com, www.soundcloud.com"
        case .rumble: return "rumble.com, www.rumble.com"
        case .odysee: return "odysee.com, www.odysee.com"
        case .peertube: return "peertube.tv, peertube.*"
        case .mastodon: return "mastodon.social, mastodon.*"
        case .bluesky: return "bsky.app, blueskyweb.xyz"
        case .threads: return "threads.net, www.threads.net"
        case .snapchat: return "snapchat.com, www.snapchat.com"
        case .linkedin: return "linkedin.com, www.linkedin.com"
        case .pinterest: return "pinterest.com, www.pinterest.com"
        case .telegram: return "t.me, telegram.org, web.telegram.org"
        case .discord: return "discord.com, www.discord.com, discordapp.com"
        case .imgur: return "imgur.com, i.imgur.com"
        case .gifur: return "gfycat.com, www.gfycat.com"
        case .streamable: return "streamable.com, www.streamable.com"
        case .wistia: return "wistia.com, www.wistia.com"
        case .brightcove: return "brightcove.com, www.brightcove.com"
        case .jwplayer: return "jwplayer.com, www.jwplayer.com"
        case .generic: return "*"
        }
    }
    
    public var supportsMultipleQualities: Bool {
        switch self {
        case .youtube, .vimeo, .dailymotion, .facebook, .twitch, .rumble, .peertube, .wistia, .brightcove, .jwplayer:
            return true
        default:
            return false
        }
    }
    
    public var supportedFormats: [String] {
        switch self {
        case .youtube, .vimeo, .dailymotion, .facebook, .instagram, .twitter, .tiktok, .reddit, .rumble, .threads, .linkedin, .pinterest:
            return ["mp4"]
        case .twitch, .peertube:
            return ["mp4", "m3u8"]
        case .soundcloud, .odysee:
            return ["mp3", "aac", "wav", "ogg", "m4a"]
        case .mastodon, .bluesky, .snapchat, .telegram, .discord:
            return ["mp4", "mov"]
        case .imgur, .gifur, .streamable:
            return ["mp4", "gif", "webm"]
        case .wistia, .brightcove, .jwplayer:
            return ["mp4", "webm", "m3u8"]
        case .generic:
            return ["mp4", "webm", "mov", "avi", "mkv", "flv", "wmv"]
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
