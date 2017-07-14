#!/usr/bin/env ruby

require 'set'
require 'yaml'

class ItunesFileExporter
  def initialize
    @songs = Set.new
    @headers = nil
    load_config
    playlist_to_hash
  end

  def run
    copy_files
  end

  private

  def load_config(config_path = './config.yml')
    @config = YAML.load_file(config_path)
  end

  def playlist_to_hash
    File.readlines(@config['playlist_path'], "\r").each do |line|
      cols = line.strip.split("\t")
      if @headers.nil?
        @headers = cols
      else
        @songs << song_data(cols)
      end
    end
  end

  def song_data(cols)
    hsh = Hash[@headers.zip(cols)]
    file_extension = hsh['Location'].split(/\./).last
    hsh['Location'] = hsh['Location'].tr(':', '/').gsub(/^Macintosh HD/, '')
    file_parts_joined = @config['output_parts']
                        .each_with_object([]) { |part, arr| arr << hsh[part] }
                        .join(@config['output_delimiter'])
                        .tr('/', '_')
    hsh['_output_path'] = "#{@config['export_path']}/#{file_parts_joined}.#{file_extension}"
    hsh
  end

  def copy_files
    @songs.each do |song|
      puts "Copying: #{song['_output_path']}"
      if File.exist?(song['_output_path'])
        puts 'File already exists.'
        next
      end
      FileUtils.cp(song['Location'], song['_output_path'])
    end
  end
end

ItunesFileExporter.new.run
