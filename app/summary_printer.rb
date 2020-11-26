# frozen_string_literal: true

# prints outcome of log processing to STDOUT
class SummaryPrinter
  def initialize(page_stats, processed_rows_counter)
    @processed_rows_counter = processed_rows_counter
    @page_stats = page_stats
  end

  SPACER = "\n\n"

  def call
    print_unique_views
    print_visits
    print_processed_rows
  end

  private

  attr_reader :page_stats, :processed_rows_counter

  def print_unique_views
    page_stats_iterator('unique views') do |hash|
      hash[:visitor_ips].size
    end
  end

  def print_visits
    page_stats_iterator('visits') { |hash| hash[:counter] }
  end

  def page_stats_iterator(caption, &agregator)
    puts SPACER + caption.capitalize.red + ':'

    sorted_page_stats(&agregator).each do |page, hash|
      puts [
        page.ljust(20).blue,
        agregator.call(hash).to_s.cyan,
        caption
      ].join(' ')
    end
  end

  def sorted_page_stats(&agregator)
    page_stats.sort_by { |_key, value| agregator.call(value) }
              .reverse
  end

  def print_processed_rows
    puts SPACER
    puts [
      processed_rows_counter.to_s.blue,
      'rows of log processed.'.red
    ].join(' ')
  end
end
