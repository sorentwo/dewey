require 'dewey'
require 'optparse'

module Dewey
  # Dewey command line
  class Command
    def initialize(args)
      @args = args
    end
    
    def run(out, error)
      @output_stream = out
      @error_stream  = error
      @opts = OptionParser.new(&method(:set_opts))
      @opts.parse!(@args)
      exit 0
    end

    private

    def set_opts(opts)
      opts.on_tail('-h', '--help', 'Show this message') do
        @output_stream.puts opts
      end

      opts.on_tail('-v', '--version', 'Print version') do
        @output_stream.puts "Dewey #{Dewey::VERSION}"
      end
    end
  end
end
