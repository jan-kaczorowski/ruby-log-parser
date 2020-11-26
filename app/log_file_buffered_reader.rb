# frozen_string_literal: false

# runs block on each line of the file
class LogFileBufferedReader
  BUFF_SIZE = 512

  def initialize(log_file_path)
    @io = IO.new(IO.sysopen(log_file_path))
    @buffer = ''
  end

  def each(&block)
    @buffer << @io.sysread(BUFF_SIZE) until @buffer.include?($INPUT_RECORD_SEPARATOR)

    line, @buffer = @buffer.split($INPUT_RECORD_SEPARATOR, 2)

    block.call(line)
    each(&block)
  rescue EOFError
    @io.close
  end
end
