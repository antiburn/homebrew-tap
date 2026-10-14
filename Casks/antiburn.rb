cask "antiburn" do
  arch arm: "aarch64", intel: "x64"

  version "0.10.0"
  sha256 arm:   "f81521ab5164421a355af5a3401fe8da4fd41ff586f68afa1b970411a28d9fdc",
         intel: "c125c5b0e391ef801d926a3ffb023a2de2e7af71b56b40425d55ea70e78ab74c"

  url "https://github.com/antiburn/antiburn/releases/download/antiburn-v#{version}/antiburn_#{version}_#{arch}.dmg"
  name "antiburn"
  desc "Local analysis of AI coding-agent sessions and token use"
  homepage "https://antiburn.com/"

  livecheck do
    url :url
    regex(/^antiburn-v(\d+\.\d+\.\d+)$/i)
    strategy :github_releases
  end

  auto_updates true
  depends_on macos: :ventura

  app "antiburn.app"

  uninstall quit: "ai.antiburn.desktop"

  zap trash: [
    "~/Library/Application Support/ai.antiburn.desktop",
    "~/Library/Caches/ai.antiburn.desktop",
    "~/Library/Logs/antiburn",
    "~/Library/WebKit/ai.antiburn.desktop",
  ]
end
