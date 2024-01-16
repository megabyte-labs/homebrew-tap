class ObsCli < Formula
  desc "CLI for Obsidian, hosted here due to binary name conflicts with OBS Studio"
  homepage "https://github.com/Yakitrak/obsidian-cli"
  version "0.1.6"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/Yakitrak/obsidian-cli/releases/download/v0.1.6/obsidian-cli_0.1.6_darwin_arm64.tar.gz"
      sha256 "868480dc025af31b724a987d071ad38fd139ceda00a944518a47371d5ac4f3a9"

      def install
        bin.install "obs" => "obs-cli"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/Yakitrak/obsidian-cli/releases/download/v0.1.6/obsidian-cli_0.1.6_darwin_amd64.tar.gz"
      sha256 "1293e8a692b893c66cdacd8436d118dc217e96bc4d14ee87ff46edde138584dc"

      def install
        bin.install "obs" => "obs-cli"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/Yakitrak/obsidian-cli/releases/download/v0.1.6/obsidian-cli_0.1.6_linux_amd64.tar.gz"
      sha256 "37c7c9fa2dc2dd115f412bb0cc79ddc8ff203972eebc3a5b22fe3c233c73d3fd"

      def install
        bin.install "obs" => "obs-cli"
      end
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/Yakitrak/obsidian-cli/releases/download/v0.1.6/obsidian-cli_0.1.6_linux_arm64.tar.gz"
      sha256 "cc52eb27dd8a03bb9b44232c968511bc8475d6e5c96808af8e8b92fdef89a170"

      def install
        bin.install "obs" => "obs-cli"
      end
    end
  end
end
