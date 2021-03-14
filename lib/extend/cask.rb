# frozen_string_literal: true

# For backward-compatibility
# See https://github.com/buo/homebrew-cask-upgrade/issues/97
CASKROOM = Cask.methods.include?(:caskroom) ? Cask.caskroom.freeze : Cask::Caskroom.path.freeze

module Cask
  def self.installed_apps
    # Manually retrieve installed apps instead of using Cask.installed because
    # it raises errors while iterating and stops.
    installed = Dir["#{CASKROOM}/*"].map { |e| File.basename e }

    installed = installed.map do |token|
      versions = installed_versions(token)
      current_version = DSL::Version.new(versions.first)
      begin
        cask = load_cask(token)
        {
          :cask               => cask,
          :name               => cask.name.first,
          :token              => cask.token,
          :version_full       => cask.version.to_s,
          :version            => cask.version.before_separators.to_s,
          :current_full       => current_version.to_s,
          :current            => current_version.before_separators.to_s,
          :outdated?          => cask.instance_of?(Cask) && versions.exclude?(cask.version.to_s),
          :auto_updates       => cask.auto_updates,
          :homepage           => cask.homepage,
          :installed_versions => versions,
          :tap                => cask.tap&.name,
          :mas                => false,
        }
      rescue CaskUnavailableError
        {
          :cask               => nil,
          :name               => nil,
          :token              => token,
          :version_full       => nil,
          :version            => nil,
          :current_full       => current_version.to_s,
          :current            => current_version.before_separators.to_s,
          :outdated?          => false,
          :auto_updates       => false,
          :homepage           => nil,
          :installed_versions => versions,
          :tap                => nil,
          :mas                => false,
        }
      end
    end

    installed.sort_by { |a| a[:token] }
  end

  # See: https://github.com/buo/homebrew-cask-upgrade/issues/43
  def self.load_cask(token)
    begin
      cask = CaskLoader.load(token)
    rescue NoMethodError
      cask = Cask.load(token)
    end
    cask
  end

  # Retrieves currently installed versions on the machine.
  def self.installed_versions(token)
    Dir["#{CASKROOM}/#{token}/*"].map { |e| File.basename e }
  end

  def self.brew_update(verbose)
    if verbose
      SystemCommand.run(HOMEBREW_BREW_FILE, args: %w[update --verbose], print_stderr: true, print_stdout: true)
    else
      SystemCommand.run(HOMEBREW_BREW_FILE, args: ["update"], print_stderr: true, print_stdout: false)
    end
  end
end
