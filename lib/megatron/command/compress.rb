module Megatron
  module GZIP
    ZIP_TYPES = /\.(?:css|html|js|otf|svg|txt|xml)$/

    def compress(glob)
      Dir["#{Dir.pwd}/#{glob}"].each do |f|
        next unless f =~ ZIP_TYPES

        mtime = File.mtime(f)
        gz_file = "#{f}.gz"
        next if File.exist?(gz_file) && File.mtime(gz_file) >= mtime

        File.open(gz_file, "wb") do |dest|
          gz = Zlib::GzipWriter.new(dest, Zlib::BEST_COMPRESSION)
          gz.mtime = mtime.to_i
          IO.copy_stream(open(f), gz)
          gz.close
        end

        File.utime(mtime, mtime, gz_file)
      end
    end
  end
end
