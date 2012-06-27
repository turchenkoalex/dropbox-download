module DropboxSync
	require 'dropbox_sdk'

	class DropboxConnector
		def initialize(options = {})
			@token = options[:token]
			@secret = options[:secret]
			@app_mode = options[:app_mode]
			@app_token = options[:app_token]
			@app_secret = options[:app_secret]
		end

		def client
			unless @client
				@client = create_client
			end
			@client
		end

		def new_client
			create_client
		end

	private

		def session
			unless @session
				@session = create_session
			end
			@session
		end

		def create_session
			session = DropboxSession.new(@app_token, @app_secret)
			session.set_access_token(@token, @secret)
			session
		end

		def create_client
			DropboxClient.new(session, @app_mode)
		end
	end

	class SyncItem
		def initialize(options = {})
			@path = options[:path]
			@dropbox_root	=	options[:dropbox_root]
			@filepath_root = options[:filepath_root]
			@client = options[:client]
			@root = options[:root] || false
			@cleanup_dropbox = options[:cleanup_dropbox] || true
			@cleanup_local = options[:cleanup_local] || false
			@folder = true
		end

		def folder?
			@folder
		end

		def set_dropbox(data)
			@folder = data['is_dir']
			@modified = data['modified']
			@bytes = data['bytes']
		end

		def sync
			sync_dropbox
			if folder?
				dropbox_contents.each { |item| get_item(item['path'], item).sync } if dropbox_contents.length > 0
				clean_dropbox if @cleanup_dropbox && !@root
			end
		end

	private
		def clean_dropbox
			@client.file_delete(@dropbox_root)
		end

		def sync_dropbox
			if @folder
				sync_dir
			else
				sync_file
			end
		end

		def sync_dir
			unless Dir.exists?(@filepath_root)
				Dir.mkdir(@filepath_root)
			end
		end

		def sync_file
			io = @client.get_file(@dropbox_root)
			open(@filepath_root, 'w'){ |f| f.puts io }
			clean_dropbox
		end

		def get_item(fullpath, data)
			path = fullpath.gsub(@dropbox_root + '/', '')
			item = SyncItem.new({ 
					client: @client,
					dropbox_root: @dropbox_root + '/' + path,
					filepath_root: @filepath_root + '/' + path,
					cleanup_dropbox: @cleanup_dropbox,
					cleanup_local: @cleanup_local,
					path: path
				})
			item.set_dropbox(data)
			item
		end

		def metadata
			unless @metadata
				@metadata = @client.metadata(@dropbox_root)
			end
			@metadata
		end

		def dropbox_contents
			metadata['contents']
		end

	end

	class DropboxSyncer

		def initialize(options = {})
			@filepath = options[:filepath]
			@dropbox = options[:dropbox]
			@cleanup_dropbox = options[:cleanup_dropbox]

			@connector = DropboxConnector.new({
				app_mode: AppConfig::APP_MODE,
				app_token: AppConfig::APP_TOKEN,
				app_secret: AppConfig::APP_SECRET,
				token: AppConfig::USER_TOKEN,
				secret: AppConfig::USER_SECRET
			})
		end

		def sync
			root = SyncItem.new({
				client: @connector.client,
				dropbox_root: @dropbox,
				filepath_root: @filepath,
				cleanup_dropbox: @cleanup_dropbox,
				cleanup_local: false,
				path: '',
				root: true
			})
			root.sync
		end

	end

end