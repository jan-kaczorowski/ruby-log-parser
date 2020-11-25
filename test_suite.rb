require 'minitest/autorun'
require_relative 'parser'

class TestParser < MiniTest::Unit::TestCase 

  # if parser is run without argument - script dies gracefully
  def test_parser_with_no_file
    assert_raises(ArgumentError) { LogFileParser.new(nil) }
  end

  # if parser is run with invalid - script dies gracefully
  def test_parser_with_wrong_path
    assert_raises(ArgumentError) { LogFileParser.new('gibberish') }
  end

  # if parser is run with existing, but corrupt log file - script dies gracefully
  def test_parser_file_has_wrong_format
    assert_raises(LogFileFormatError) { LogFileParser.new('./webserver_bad.log') }
  end
  
  def test_parser_outputs_report_to_stdout
    parser = LogFileParser.new('./webserver.log')
    assert_match(/rows of log processed/, parser.summary )
  end
  
  def test_parser_returning_output
    assert_output(/rows of log processed/,'' ) { LogFileParser.new('./webserver.log') }
  end

  # number of lines processed is equal to number of lines in the file
  def test_lines_in_file_equal_to_lines_processed
    path = './webserver.log'
    lines_count = File.open(path,'r').readlines.size
    parser = LogFileParser.new('./webserver.log')
    assert_equal(lines_count, parser.processed_rows_counter)
    assert_match(Regexp.new("#{lines_count} rows of log processed"), parser.summary )
  end

  # sorting by unique views, most popular page is first match
  def test_ordering_unique_views
    regex = /^(?<page>[a-zA-Z0-9\-\_\/]+)\s+(?<count>[0-9]+)\s(unique views)$/
    parser = LogFileParser.new('./webserver.log')
    matches = parser.summary.match(regex)
    assert_equal(matches[:page], '/index')
    assert_equal(matches[:count].to_i, 23)
  end

  # sorting by visits, most popular page is first match
  def test_ordering_visits
    regex = /^(?<page>[a-zA-Z0-9\-\_\/]+)\s+(?<count>[0-9]+)\s(visits)$/
    parser = LogFileParser.new('./webserver.log')
    matches = parser.summary.match(regex)
    assert_equal(matches[:page], '/about/2')
    assert_equal(matches[:count].to_i, 90)
  end
end