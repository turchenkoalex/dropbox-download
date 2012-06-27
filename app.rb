require 'optparse' 
require 'ostruct'
require 'date'
require File.expand_path("../config.rb", __FILE__)
require File.expand_path('../dropbox_sync.rb', __FILE__)

class Application
	VERSION = '0.0.1'
	
	attr_reader :options

	def initialize(arguments, stdin)
		@arguments = arguments
		@stdin = stdin
		
		# Set defaults
		@options = OpenStruct.new
		@options.verbose = false
		@options.quiet = false
	end

	def run
		if parsed_options?

			puts "Start at #{DateTime.now}\n\n" if @options.verbose

			output_options if @options.verbose

			process_command
			
			puts "\nFinished at #{DateTime.now}" if @options.verbose

		else
			output_usage
		end
	end
	
	protected
	
		def parsed_options?

			opts = OptionParser.new 
			opts.on('-v', '--version')    { output_version ; exit 0 }
			opts.on('-h', '--help')       { output_help }
			opts.on('-V', '--verbose')    { @options.verbose = true }
			opts.on('-q', '--quiet')      { @options.quiet = true }
			opts.on('-i','--dropbox DROPBOX') { |path| @options.dropbox = path }
			opts.on('-o','--filepath FILEPATH') { |path| @options.filepath = path }

			opts.parse!(@arguments) rescue return false
			
			process_options
			options_valid?
		end

		# Performs post-parse processing on options
		def process_options
			@options.verbose = false if @options.quiet
		end
		
		def output_options
			puts "Options:\n"
			
			@options.marshal_dump.each do |name, val|
				puts "  #{name} = #{val}"
			end
		end

		def options_valid?
			@options.filepath && @options.dropbox
		end

		def output_help
			output_version
		end
		
		def output_usage
			output_version
			puts "Usage: #{File.basename(__FILE__)} {-o|--filepath=}{FILEPATH} {-i|--dropbox=}{DROPBOX}"
		end
		
		def output_version
			puts "#{File.basename(__FILE__)} version #{VERSION}"
		end
		
		def process_command
			syncer = DropboxSync::DropboxSyncer.new({filepath: @options.filepath, dropbox: @options.dropbox})
			syncer.sync
		end
end