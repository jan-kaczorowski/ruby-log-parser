# Prepared by: Jan Kaczorowski <jan.kaczorowski@gmail.com>
# Usage: $ ruby ./parser.rb webserver.log

require 'pathname'
require 'set'

# for the sake of brevity I shall put my classes in this very file
class LogFileProcessor
  def initialize(log_file_path)
    @io = IO.new(IO.sysopen(log_file_path))
    @buffer = ""
  end

  def each(&block)
    # should the file had GBs of data rather than KBs, sysread is 
    # going to give us an advantage over regular read
    @buffer << @io.sysread(512) until @buffer.include?($/)

    line, @buffer = @buffer.split($/, 2)

    block.call(line)
    each(&block)
  rescue EOFError
    @io.close
  end
end

class LogFileFormatError < StandardError; end

class LogFileParser

  attr_reader :processed_rows_counter
  
  def initialize(log_file_arg)
    unless log_file_arg.nil?
      @processed_rows_counter = 0
      @pages = {}
      @log_file_arg = log_file_arg
      parse_file
    else
      raise ArgumentError.new "Provide log file path as an argument"
    end
  end

  def parse_file
    @file_path = Pathname.new(@log_file_arg).expand_path

    if @file_path.file? 
      LogFileProcessor.new(@file_path).each do |line|
        parse_line(line)
      end
      puts summary
    else
      raise ArgumentError.new "Provided path to a log file is not valid"
    end
  end

  def summary
    content = ''
    content << "\nUnique views:\n=============\n\n"
    @pages.sort_by { |k, v| v[:visitor_ips].size }.reverse.each do |page, hash|
      content << "#{page.ljust(20)} #{hash[:visitor_ips].size} unique views\n"
    end

    content << "\nVisits:\n=============\n\n"
    @pages.sort_by { |k, v| v[:counter] }.reverse.each do |page, hash|
      content << "#{page.ljust(20)} #{hash[:counter]} visits\n"
    end

    content << "\n#{@processed_rows_counter} rows of log processed."
  end

  private

  def parse_line(line)
    # normally, I'd probably use regexp, but, since the file is so simple
    # there was little point doing that
    fragmented_line = line.split(' ')
    unless fragmented_line.size == 2
      raise LogFileFormatError.new "Log file format is not parseable. Encountered unknown format on line #{@processed_rows_counter+1}."
    end
    page, ip_address = fragmented_line

    @pages[page] ||= {
      counter: 0,
      visitor_ips: Set.new
    }

    @pages[page][:counter] += 1
    # as set will always hold unique elements, we can conveniently use it to track unique IPs
    @pages[page][:visitor_ips].add(ip_address)

    @processed_rows_counter += 1
  end
end

if __FILE__ == $0	
  begin
    LogFileParser.new(ARGV[0])
  rescue ArgumentError, LogFileFormatError => e
    abort "#{e.class}:: #{e.message}"
  end
end
