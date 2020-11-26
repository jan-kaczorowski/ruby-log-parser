# frozen_string_literal: true

require 'ostruct'

# captures stdout for tests
class Capture
  def self.stdout(&block)
    stdout = StringIO.new
    $stdout = stdout

    result = block.call

    # restore normal output
    $stdout = STDOUT

    OpenStruct.new result: result, stdout_as_string: stdout.string
  end
end
