cask "mirrorlock" do
  version "1.1.0"
  sha256 "06d88efab4c001328c6f4ab6239cd357a56778df77dfd766cf6b4e4ce943ed6e"

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
