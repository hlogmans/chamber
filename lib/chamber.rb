require 'singleton'
require 'forwardable'
require 'chamber/file_set'
require 'chamber/rails'

class  Chamber
  include Singleton

  class << self
    extend Forwardable

    def_delegators  :instance,  :[],
                                :basepath,
                                :load,
                                :filenames,
                                :namespaces,
                                :settings,
                                :to_environment

    alias_method    :env,       :instance
  end

  attr_accessor :basepath,
                :files

  def load(options)
    self.settings = nil
    self.basepath = options[:basepath] || ''
    file_patterns = options[:files] || [
                      self.basepath + 'credentials*.yml',
                      self.basepath + 'settings*.yml',
                      self.basepath + 'settings' ]
    self.files    = FileSet.new files:      file_patterns,
                                namespaces: options.fetch(:namespaces, {})
  end

  def filenames
    self.files.filenames
  end

  def namespaces
    settings.namespaces
  end

  def settings
    @settings ||= -> do
      @settings = Settings.new

      files.to_settings do |parsed_settings|
        @settings.merge! parsed_settings
      end

      @settings
    end.call
  end

  def method_missing(name, *args)
    if settings.respond_to?(name)
      return settings.public_send(name, *args)
    end

    super
  end

  def respond_to_missing?(name, include_private = false)
    settings.respond_to?(name, include_private)
  end

  protected

  attr_writer :settings

  private

  def basepath=(pathlike)
    @basepath = pathlike == '' ? '' : Pathname.new(::File.expand_path(pathlike))
  end
end
