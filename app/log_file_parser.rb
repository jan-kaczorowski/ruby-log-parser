# frozen_string_literal: false

require 'pathname'
require 'set'

# runs Parser app
class LogFileParser
  class LogFileFormatError < StandardError; end

  def initialize(log_file_arg)
    raise ArgumentError, 'provide log file as a param' if log_file_arg.nil?

    @processed_rows_counter = 0
    @pages = {}
    @file_path = Pathname.new(log_file_arg).expand_path

    raise ArgumentError, 'path is invalid' unless @file_path.file?
  end

  def call
    log_file_reader.each { |line| parse_line(line) }

    print_summary

    self
  end

  def print_summary
    SummaryPrinter.new(pages, processed_rows_counter).call
  end

  private

  attr_reader :processed_rows_counter, :file_path, :pages

  def parse_line(line)
    fragmented_line = line.split(' ')

    raise LogFileFormatError, 'line structure invalid' unless fragmented_line.length == 2

    page, ip_address = fragmented_line

    pages[page] ||= { counter: 0, visitor_ips: Set.new }

    pages[page][:counter] += 1

    pages[page][:visitor_ips].add(ip_address)

    @processed_rows_counter += 1
  end

  def log_file_reader
    @log_file_reader ||= LogFileBufferedReader.new(file_path)
  end
end
