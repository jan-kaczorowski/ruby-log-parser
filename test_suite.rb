# frozen_string_literal: true

require 'simplecov'
require 'rubygems'
require 'bundler/setup'
require 'minitest/reporters'
require 'minitest/autorun'

Bundler.require(:default)
Minitest::Reporters.use!

Dir[File.dirname(__FILE__) + '/app/**/*.rb'].sort.each do |file|
  puts 'loading file:'.purple + file
  require file
end

# cleaning temp files
Minitest.after_run do
  Dir[File.dirname(__FILE__) + '/*.temp'].sort.each do |file|
    File.delete file
  end
end

# test suite for app
class TestParser < Minitest::Test
  GOOD_LOG_FILE_PATH = './webserver.log'
  BAD_LOG_FILE_PATH = './webserver_bad.log'

  # if parser is run without argument - script dies gracefully
  def test_parser_with_no_file
    assert_raises(ArgumentError) { ::LogFileParser.new(nil).call }
  end

  # if parser is run with invalid - script dies gracefully
  def test_parser_with_wrong_path
    assert_raises(ArgumentError) { ::LogFileParser.new('gibberish').call }
  end

  # if parser is run with existing, but corrupt log file - script dies gracefully
  def test_parser_file_has_wrong_format
    assert_raises(::LogFileParser::LogFileFormatError) do
      ::LogFileParser.new(BAD_LOG_FILE_PATH).call
    end
  end

  def test_parser_outputs_report_to_stdout
    assert_output(/rows of log processed/) do
      LogFileParser.new(GOOD_LOG_FILE_PATH).call
    end
  end

  # number of lines processed is equal to number of lines in the file
  def test_lines_in_file_equal_to_lines_processed
    lines_count = File.open(GOOD_LOG_FILE_PATH, 'r').readlines.size
    output_line_count = ::LogFileParser.new(GOOD_LOG_FILE_PATH)
                                       .call
                                       .send(:processed_rows_counter)
    assert_equal(lines_count, output_line_count)
  end

  # sorting by unique views, most popular page is first match
  def test_ordering_unique_views
    matches = output_stats_comparator('unique views')

    assert_equal(matches.named_captures,
                 { 'page' => '/help_page/1', 'count' => '2' })
  end

  # sorting by visits, most popular page is first match
  def test_ordering_visits
    matches = output_stats_comparator('visits')

    assert_equal(matches.named_captures,
                 { 'page' => '/help_page/1', 'count' => '3' })
  end

  private

  def temp_log_file
    @temp_log_file ||= File.open("#{SecureRandom.uuid}.temp", 'w') do |tfile|
      tfile << <<~LOGFILE
        /help_page/1 126.318.035.038
        /index 184.123.665.067
        /help_page/1 126.318.035.038
        /login 444.701.448.104
        /help_page/1 722.247.931.582
      LOGFILE
      tfile
    end
  end

  def output_stats_comparator(section)
    parser = ::LogFileParser.new(temp_log_file.path)
    stream = Capture.stdout { parser.call }
    regex = %r{^(?<page>[a-zA-Z0-9\-\_\/]+)\s+(?<count>[0-9]+)\s(#{section})$}
    parser_output = stream.stdout_as_string
                          .split("\n")
                          .map(&:uncolorize)
                          .select { |line| line.include?(section) }
    parser_output[0].match(regex)
  end
end
