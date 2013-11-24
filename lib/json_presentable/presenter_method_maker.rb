module JSONPresentable
  class PresenterMethodMaker
    def initialize(root_name, method_suffix = nil, errors: nil, url: false, &block)
      @root_name = root_name
      @method_suffix = method_suffix
      @block = block
      @errors = errors
      @url = url
    end

    def print(strip_enclosure: false)
      instance_eval &@block
      strip_enclosure ? code : enclose_code(code)
    end

    private

    def enclose_code(code)
      <<-EOS
def json_presentable_#{@method_suffix}
  #{code}
end
      EOS
    end

    def code
      @code ||= (code_snippets + [url_code_snippet, errors_code_snippet].compact).join('.merge')
    end

    def code_snippets
      @code_snippets ||= []
    end

    def errors_code_snippet
      if @errors.nil?
        "(#{@root_name}.respond_to?(:errors) ? {errors: #{@root_name}.errors.as_json} : {})"
      elsif @errors.is_a?(String) || @errors.is_a?(Symbol)
        "({errors: page.#{@errors}.as_json})"
      elsif @errors
        "({errors: #{@root_name}.errors.as_json})"
      end
    end

    def url_code_snippet
      if @url.is_a?(String)|| @url.is_a?(Symbol)
        "({url: controller.#{@url}(page)})"
      elsif @url
        "({url: controller.url_for(#{@root_name})})"
      end
    end

    def property(arg)
      if arg.is_a?(Hash) && arg.size == 1
        code_snippets << "({#{arg.keys.first}: #{@root_name}.#{arg.values.first}})"
      elsif arg.is_a?(String) || arg.is_a?(Symbol)
        code_snippets << "({#{arg}: #{@root_name}.#{arg}})"
      else
        raise ArgumentError, "'attribute' called with bad argument"
      end
    end

    def attributes(*args)
      code_snippets << "(#{@root_name}.as_json#{options_for_only(args)})"
    end

    def association(assoc_root_name, errors: nil, url: false, &block)
      deep_root_name = "#{@root_name}.#{assoc_root_name}"
      if block_given?
        code_snippets << "({#{assoc_root_name}: #{PresenterMethodMaker.new(deep_root_name, errors: errors, url: url, &block).print(strip_enclosure: true)}})"
      else
        code_snippets << "({#{assoc_root_name}: #{@root_name}.#{assoc_root_name}.as_json})" + (url ? ".merge({url: controller.url_for(#{@root_name}.#{assoc_root_name})})" : '')
      end
    end

    def options_for_only(args)
      return if args.empty?
      "(only: #{args.to_s})"
    end
  end
end