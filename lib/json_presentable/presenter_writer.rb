module JSONPresentable
  class PresenterWriter
    def initialize(root, errors: nil, &block)
      @root = root
      @block = block
      @errors = errors
    end

    def print
      instance_eval &@block
      (code_snippets + [errors_code_snippet].compact).join('.merge')
    end

    private

    def root_name
      @root.sub /^.*\./, ''
    end

    def code_snippets
      @code_snippets ||= []
    end

    def errors_code_snippet
      if @errors.nil?
        "(#{@root}.respond_to?(:errors) ? {errors: #{@root}.errors.as_json} : {})"
      elsif @errors.is_a?(String) || @errors.is_a?(Symbol)
        "({errors: page.#{@errors}.as_json})"
      elsif @errors
        "({errors: #{@root}.errors.as_json})"
      end
    end

    def property(arg)
      if arg.is_a?(Hash) && arg.size == 1
        code_snippets << "({#{arg.keys.first}: #{@root}.#{arg.values.first}})"
      elsif arg.is_a?(String) || arg.is_a?(Symbol)
        code_snippets << "({#{arg}: #{@root}.#{arg}})"
      else
        raise ArgumentError, "'attribute' called with bad argument"
      end
    end

    def attributes(*args)
      code_snippets << "(#{@root}.as_json#{options_for_only(args)})"
    end

    def not_attributes(*args)
      code_snippets << "(#{@root}.as_json#{options_for_except(args)})"
    end

    def errors(full_messages: false, only: false, except: false, method: :errors, root: :errors)
      method_call = "#{method}.as_json(full_messages: #{full_messages})"
      if only
        method_call += ".select {|k,v| #{[only].flatten.inspect}.include?(k.to_sym)}"
      elsif except
        method_call += ".reject {|k,v| #{[except].flatten.inspect}.include?(k.to_sym)}"
      end
      code_snippets << "({#{root}: #{@root}.#{method_call}})"
    end

    def url_for(only_path: false, root: false, namespace: false, **opts)
      path_or_url = only_path ? 'path' : 'url'
      root ||= path_or_url
      prefix = namespace ? "#{namespace}_" : ''
      if opts.present?
        method_call = "url_for(#{url_for_opts_string(opts.merge(only_path: only_path))})"
      else
        method_call = "#{prefix}#{root_name}_#{path_or_url}(#{@root})"
      end
      code_snippets << "({#{root}: controller.#{method_call}})"
    end

    def url_for_opts_string(opts)
      result = []
      opts.each do |k, v|
        value = v.is_a?(Proc) ? v.to_source(strip_enclosure: true) : v.inspect
        (result ||= []) << "#{k.inspect}=>#{value}"
      end
      result.join(', ')
    end

    def association(assoc_root_name, errors: nil, url: false, &block)
      deep_root_name = "#{@root}.#{assoc_root_name}"
      if block_given?
        code_snippets << "({#{assoc_root_name}: #{PresenterWriter.new(deep_root_name, errors: errors, &block).print}})"
      else
        code_snippets << "({#{assoc_root_name}: #{@root}.#{assoc_root_name}.as_json})" + (url ? ".merge({url: controller.url_for(#{@root}.#{assoc_root_name})})" : '')
      end
    end

    def options_for_except(args)
      raise ArgumentError, "'not_attributes' called with no arguments" if args.empty?
      "(except: #{args.to_s})"
    end

    def options_for_only(args)
      return if args.empty?
      "(only: #{args.to_s})"
    end
  end
end