class Macdownloader < Formula
  desc "A powerful, open-source video downloader for macOS"
  homepage "https://github.com/MrFlappy0/MacDownloader"
  url "https://github.com/MrFlappy0/MacDownloader/archive/refs/tags/v1.0.0.tar.gz"
  sha256 ""
  license "MIT"

  depends_on :macos => :ventura

  def install
    # Build the CLI
    system "swift", "build", "-c", "release", "--arch", "x86_64", "--arch", "arm64"
    
    # Create universal binary
    mkdir_p "#{buildpath}/.build/universal"
    system "lipo", "-create", 
           "#{buildpath}/.build/x86_64-apple-macosx/release/macdownloader",
           "#{buildpath}/.build/arm64-apple-macosx/release/macdownloader",
           "-output", "#{buildpath}/.build/universal/macdownloader"
    
    # Install binary
    bin.install "#{buildpath}/.build/universal/macdownloader"
    
    # Install documentation
    doc.install "#{buildpath}/Documentation/README.md" => "README.md"
    doc.install "#{buildpath}/Documentation/LICENSE" => "LICENSE"
    
    # Install shell completions
    bash_completion.install "#{buildpath}/scripts/completions/macdownloader.bash" => "macdownloader"
    zsh_completion.install "#{buildpath}/scripts/completions/_macdownloader" => "_macdownloader"
    fish_completion.install "#{buildpath}/scripts/completions/macdownloader.fish" => "macdownloader.fish"
  end

  def caveats
    <<~EOS
      MacDownloader has been installed!
      
      To get started:
        macdownloader --help
      
      For GUI application:
        Open the project in Xcode and build the MacDownloaderApp target
      
      Supported sites:
        YouTube, Vimeo, Dailymotion, Facebook, Instagram, Twitter/X, TikTok, Reddit, Twitch, SoundCloud
    EOS
  end

  test do
    system "#{bin}/macdownloader", "--help"
  end
end
