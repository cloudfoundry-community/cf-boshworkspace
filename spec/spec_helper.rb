module SpiffHelper
  require 'tempfile'
  require "common/exec"
  require "yaml"
  require 'rspec/its'

  def spiff_merge(template, stub_string)
    begin
      stub = Tempfile.new(['stub', '.yml'])
      stub.write(stub_string)
      stub.close
      out = sh("spiff merge #{template} #{stub.path} 2>&1")
      SpiffResult.new(out.output)
    ensure
      stub.close
      stub.unlink
    end
  end

  def sh(args, options={})
    begin
      Bosh::Exec.sh args, options
    rescue Bosh::Exec::Error => e
      raise [e.message, e.output].join(":\n")
    end
  end

  def template_path(file)
    templates_dir = File.expand_path("../../templates", __FILE__)
    File.join(templates_dir, file)
  end

  class SpiffResult
    def initialize(raw_yaml)
      @raw = YAML.load(raw_yaml)
    end

    def [](*keys)
      result = @raw
      keys.each do |key|
        case result
        when Hash
          result = result[key.to_s]
        when Array
          result = result.find { |h| h["name"] == key.to_s }
        end
      end
      result
    end
  end
end

class String
  def strip_heredoc
    gsub(/^#{scan(/^\s*/).min_by{ |l|l.length }}/, "")
  end
end

RSpec.configure do |config|
  config.include SpiffHelper
end
