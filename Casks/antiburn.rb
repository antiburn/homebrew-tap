cask "antiburn" do
  arch arm: "aarch64", intel: "x64"

  version "0.9.0"
  sha256 arm:   "c58945894abfc18bfeaf89ada93b5a13a79a76b15ea73c9572923639311d8377",
         intel: "aade5e1baf7c46138dc0310e39bc4fcc465680c4f6da675baa0e659459e66476"

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
    "~/Library/Preferences/ai.antiburn.desktop.plist",
    "~/Library/Saved Application State/ai.antiburn.desktop.savedState",
    "~/Library/WebKit/ai.antiburn.desktop",
  ]
end
