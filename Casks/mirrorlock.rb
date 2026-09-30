cask "mirrorlock" do
  version "1.2.0"
  sha256 "1a524049b57c97fb1f11e3023584df1517135dbe0d0bb24b028560de17da54fd"

  url "https://github.com/shubhransh-gupta/mirrorLock/releases/download/v#{version}/MirrorLock-#{version}.pkg"
  name "MirrorLock"
  desc "Lock keyboard & mouse behind a live desktop mirror for AI botsitting"
  homepage "https://github.com/shubhransh-gupta/mirrorLock"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  pkg "MirrorLock-#{version}.pkg"

  uninstall pkgutil: "com.shubhranshgupta.mirrorlock",
            quit:    "com.shubhranshgupta.mirrorlock"

  zap trash: [
    "~/Library/Application Support/com.shubhranshgupta.mirrorlock",
    "~/Library/Caches/com.shubhranshgupta.mirrorlock",
    "~/Library/Containers/com.shubhranshgupta.mirrorlock",
    "~/Library/Preferences/com.shubhranshgupta.mirrorlock.plist",
  ]
end
