module ActionView
  module Helpers
    module AssetTagHelper
      class CouldNotOpenRemoteFileException < Exception; end

      def stylesheet_link_tag(*sources)
        options = sources.extract_options!.stringify_keys
        cache   = options.delete("cache")
        lifetime = options.delete("lifetime")
        recursive = options.delete("recursive")

        if ActionController::Base.perform_caching && cache
          joined_stylesheet_name = (cache == true ? "all" : cache) + ".css"
          joined_stylesheet_path = File.join(STYLESHEETS_DIR, joined_stylesheet_name)
          exists = File.exists?(joined_stylesheet_path)
          expired = lifetime && exists && File.mtime(joined_stylesheet_path) + lifetime < Time.now
          
          write_asset_file_contents(joined_stylesheet_path, compute_stylesheet_paths(sources, recursive)) if !exists or expired
          stylesheet_tag(joined_stylesheet_name, options)
        else
          expand_stylesheet_sources(sources, recursive).collect { |source| stylesheet_tag(source, options) }.join("\n")
        end
      end
      
      def javascript_include_tag(*sources, &block)
        options = sources.extract_options!.stringify_keys
        concat  = options.delete("concat")
        cache   = concat || options.delete("cache")
        lifetime = options.delete("lifetime")
        recursive = options.delete("recursive")

        if concat || (ActionController::Base.perform_caching && cache)
          joined_javascript_name = (cache == true ? "all" : cache) + ".js"
          joined_javascript_path = File.join(joined_javascript_name[/^#{File::SEPARATOR}/] ? ASSETS_DIR : JAVASCRIPTS_DIR, joined_javascript_name)

          if ActionController::Base.perform_caching then
            exists = File.exists?(joined_javascript_path)
            expired = lifetime && exists && File.mtime(joined_javascript_path) + lifetime < Time.now
            write_asset_file_contents(joined_javascript_path, compute_javascript_paths(sources, recursive), &block) if !exists or expired
          end
          javascript_src_tag(joined_javascript_name, options)
        else
          expand_javascript_sources(sources, recursive).collect { |source| javascript_src_tag(source, options) }.join("\n")
        end
      end
        
      private
        
        def write_asset_file_contents(joined_asset_path, asset_paths)
          FileUtils.mkdir_p(File.dirname(joined_asset_path))
          begin
            buffer = join_asset_file_contents(asset_paths)
            buffer = yield(buffer) if block_given?
            File.open(joined_asset_path, "w+") do |cache|
              cache.write(buffer)
            end
            # Set mtime to the latest of the combined files to allow for
            # consistent ETag without a shared filesystem.
            mt = asset_paths.reject {|p| p =~ %r{^[-a-z]+://} }.map { |p| File.mtime(asset_file_path(p)) }.max
            File.utime(mt, mt, joined_asset_path)            
          rescue CouldNotOpenRemoteFileException    # If one or more of the remotes failed to build, don't overwrite
          end
        end
        
        def asset_file_path(path)
          return path if path =~ %r{^[-a-z]+://}
          File.join(ASSETS_DIR, path.split('?').first)
        end
        
        def join_asset_file_contents(paths)
          paths.collect do |path|
            begin
              open(asset_file_path(path)).read
            rescue
              RAILS_DEFAULT_LOGGER.warn "Couldn't open path: #{path}: #{$!.inspect}"
              raise CouldNotOpenRemoteFileException
            end
          end.join("\n\n")
        end
        
        def compute_public_path(source, dir, ext = nil, include_host = true)
          has_request = @controller.respond_to?(:request)

          unless source =~ %r{^[-a-z]+://}
            source_ext = File.extname(source)[1..-1]
            if ext && (source_ext.blank? || (ext != source_ext && File.exist?(File.join(ASSETS_DIR, dir, "#{source}.#{ext}"))))
              source += ".#{ext}"
            end

            source = "/#{dir}/#{source}" unless source[0] == ?/

            source = rewrite_asset_path(source)

            if has_request && include_host
              unless source =~ %r{^#{ActionController::Base.relative_url_root}/}
                source = "#{ActionController::Base.relative_url_root}#{source}"
              end
            end
          end

          if include_host && source !~ %r{^[-a-z]+://}
            host = compute_asset_host(source)

            if has_request && !host.blank? && host !~ %r{^[-a-z]+://}
              host = "#{@controller.request.protocol}#{host}"
            end

            "#{host}#{source}"
          else
            source
          end
        end
    end
  end
end