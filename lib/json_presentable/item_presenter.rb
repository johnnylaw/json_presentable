module JSONPresentable
  class ItemPresenter
    attr_reader :item

    def self.inherited(subclass)
      method_name = presenter_object_name(subclass)
      subclass.class_eval <<-EOS
        def #{method_name}
          @item || @#{method_name}
        end

        private

        def item
          #{method_name}
        end
      EOS
    end

    def self.mapping(*mappings, &block)
      mappings.each do |mapping|
        self.mappings << mapping.to_s
        class_eval <<-EOS
          def mapping_#{mapping}
            #{block.to_source(strip_enclosure: true)}
          end
        EOS
      end
    end

    def self.mappings
      @mappings ||= []
    end

    def initialize(item, mapping: nil, controller: nil)
      @item = item
      with_map(mapping || controller && controller.class.to_s.sub(/Controller$/, '').underscore)
      @controller = controller
    end

    def as_json(options = {})
      return nil if item.nil?
      to_hash.merge(errors: errors).as_json
    end

    def json_root
      item.class.name.underscore
    end

    def with_map(mapping)
      @mapping = mapping.to_s
      self
    end

    def errors
      @errors ||= item.errors.as_json(full_messages: true)
    end

    private

    def to_hash
      self.class.mappings.include?(@mapping) ? send("mapping_#{@mapping}") : item.as_json
    end

    def self.presenter_object_name(subclass)
      subclass.name.sub(/^([A-Z][A-Za-z]*::)*(([A-Z][A-Za-z]*)+)Presenter$/, '\2').underscore
    end
  end
end