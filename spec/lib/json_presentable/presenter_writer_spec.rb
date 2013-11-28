require 'spec_helper'

describe JSONPresentable::PresenterWriter do
  describe '#print' do
    context 'when errors option is false' do
      subject { JSONPresentable::PresenterWriter.new('page', method_name: '_some_map', errors: false, &block).print }

      describe '#attributes' do
        context 'when called with arguments' do
          let(:block) { proc { attributes :id, :username } }

          it 'presents the attributes that are given' do
            should eq "def _some_map\n  (page.as_json(only: [:id, :username]))\nend\n"
          end
        end

        context 'when called WITHOUT arguments' do
          let(:block) { proc { attributes } }

          it 'presents all attributes of the root item' do
            should eq "def _some_map\n  (page.as_json)\nend\n"
          end
        end
      end

      describe '#not_attributes' do
        context 'when called with arguments' do
          let(:block) { proc { not_attributes :id, :username } }

          it 'presents all but the attributes that are given' do
            should eq "def _some_map\n  (page.as_json(except: [:id, :username]))\nend\n"
          end
        end

        context 'when called WITHOUT arguments' do
          let(:block) { proc { not_attributes } }
          subject { -> { JSONPresentable::PresenterWriter.new('page', method_name: '_some_map', &block).print } }

          it { should raise_error(ArgumentError, "'not_attributes' called with no arguments") }
        end
      end

      describe '#errors' do
        context 'when called without options' do
          let(:block) { proc { errors } }

          it 'presents errors' do
            should eq "def _some_map\n  ({errors: page.errors.as_json(full_messages: false)})\nend\n"
          end
        end

        context 'when called with (full_messages: true)' do
          let(:block) { proc { errors full_messages: true } }

          it 'presents errors with full_messages' do
            should eq "def _some_map\n  ({errors: page.errors.as_json(full_messages: true)})\nend\n"
          end
        end

        context 'when called with :root option' do
          let(:block) { proc { errors root: :shit_ton_of_errors } }

          it 'presents errors with given root' do
            should eq "def _some_map\n  ({shit_ton_of_errors: page.errors.as_json(full_messages: false)})\nend\n"
          end
        end

        context 'when called with :only option (even if the :except option is set)' do
          let(:block) { proc { errors only: [:title, :content], except: [:nonsense] } }

          it 'presents only errors on fields given' do
            should eq "def _some_map\n  ({errors: page.errors.as_json(full_messages: false).select {|k,v| [:title, :content].include?(k.to_sym)}})\nend\n"
          end
        end

        context 'when called with :except option' do
          let(:block) { proc { errors except: :title } }

          it 'presents errors except on fields given' do
            should eq "def _some_map\n  ({errors: page.errors.as_json(full_messages: false).reject {|k,v| [:title].include?(k.to_sym)}})\nend\n"
          end
        end

        context 'when called with :method option' do
          let(:block) { proc { errors method: 'some_error_method(fun: true)' } }

          it 'presents errors using the method call specified' do
            should eq "def _some_map\n  ({errors: page.some_error_method(fun: true).as_json(full_messages: false)})\nend\n"
          end
        end
      end

      describe '#url_for' do
        context 'when called without options' do
          let(:block) { proc { url_for } }

          it 'presents url' do
            should eq "def _some_map\n  ({url: controller.page_url(page)})\nend\n"
          end
        end

        context 'when called with (only_path: true) option' do
          let(:block) { proc { url_for only_path: true } }

          it 'presents path' do
            should eq "def _some_map\n  ({path: controller.page_path(page)})\nend\n"
          end
        end

        context 'when called with :root option' do
          let(:block) { proc { url_for root: :location } }

          it 'presents url with :root option as root' do
            should eq "def _some_map\n  ({location: controller.page_url(page)})\nend\n"
          end
        end

        context 'when called with :namespace option' do
          let(:block) { proc { url_for namespace: :admin } }

          it 'presents namespaced url' do
            should eq "def _some_map\n  ({url: controller.admin_page_url(page)})\nend\n"
          end
        end

        context 'when nested in a call to #association' do
          let(:block) do
            proc do
              association :user, errors: false do
                url_for
              end
            end
          end

          it 'presents the correct path' do
            should eq "def _some_map\n  ({user: ({url: controller.user_url(page.user)})})\nend\n"
          end
        end

        context 'when called with any other options' do
          let(:block) do
            proc do
              url_for controller: 'admin/monkeys', action: 'show', id: -> { page }, namespace: :thing
            end
          end

          it 'presents the path by calling the url_for helper with the options, ignoring the :namespace option if present' do
            meat = '({url: controller.url_for(:controller=>"admin/monkeys", :action=>"show", :id=>page, :only_path=>false)})'
            should eq "def _some_map\n  #{meat}\nend\n"
          end
        end
      end

      describe '#property' do
        context 'when called with a symbol argument' do
          let(:block) { proc { property :permalink } }

          it 'presents that attribute of the root item' do
            should eq "def _some_map\n  ({permalink: page.permalink})\nend\n"
          end
        end

        context 'when called with a single-key hash argument' do
          let(:block) { proc { property permalink: 'humanize(permalink)' } }

          it 'presents that attribute of the root item, getting the value by calling the method given in the hash' do
            should eq "def _some_map\n  ({permalink: page.humanize(permalink)})\nend\n"
          end
        end

        context 'when called with a multiple-key hash argument (nonsense to API)' do
          let(:block) { proc { property permalink: :something, user_id: :something } }
          subject { -> { JSONPresentable::PresenterWriter.new('page', method_name: '_some_map', &block).print } }
          it { should raise_error(ArgumentError, "'attribute' called with bad argument") }
        end
      end

      describe '#association' do
        context 'when called WITHOUT a block' do
          let(:block) { proc { association :thing } }

          it 'presents all attributes of the associated item using association name as the root' do
            should eq "def _some_map\n  ({thing: page.thing.as_json})\nend\n"
          end
        end

        context 'when called with a block' do
          let(:block) do
            proc do
              association :thing, errors: false do
                attributes :id, :weight
              end
            end
          end

          it 'does NOT present all attributes but instead does as instructed in the block using association name as the root' do
            should eq "def _some_map\n  ({thing: (page.thing.as_json(only: [:id, :weight]))})\nend\n"
          end
        end
      end

      describe 'more than one call in a block' do
        let(:block) do
          proc do
            attributes :id, :title
            association :thing, errors: false do
              attributes :id, :height
              property permalink: 'humanize(permalink)'
            end
          end
        end

        it 'merges all the right things together' do
          meat = "(page.as_json(only: [:id, :title])).merge({thing: (page.thing.as_json(only: [:id, :height])).merge({permalink: page.thing.humanize(permalink)})})"
          should eq "def _some_map\n  #{meat}\nend\n"
        end
      end
    end

    context 'when :include_maps option is set' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterWriter.new('page', method_name: '_some_map', include_maps: included_maps, errors: false, &block).print }

      context 'with a single argument' do
        let(:included_maps) { '_blah_map' }

        it 'merges its code into the map given' do
          should eq "def _some_map\n  (_blah_map).merge(page.as_json(only: [:title]))\nend\n"
        end
      end

      context 'with an array of arguments' do
        let(:included_maps) { ['__map', '_blah_map'] }

        it 'merges its code into the map given' do
          should eq "def _some_map\n  (__map).merge(_blah_map).merge(page.as_json(only: [:title]))\nend\n"
        end
      end
    end

    context 'when :errors option is true' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterWriter.new('page', method_name: '_some_map', errors: true, &block).print }

      it 'writes errors into method' do
        should eq "def _some_map\n  (page.as_json(only: [:title])).merge({errors: page.errors.as_json})\nend\n"
      end
    end

    context 'when errors option is not set at all' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterWriter.new('page', method_name: '_some_map', &block).print }

      it 'writes a respond_to? check and errors into method' do
        should eq "def _some_map\n  (page.as_json(only: [:title])).merge(page.respond_to?(:errors) ? {errors: page.errors.as_json} : {})\nend\n"
      end
    end

    context 'when errors option is set to a string or symbol' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterWriter.new('page', method_name: '_some_map', errors: 'issues(14)', &block).print }

      it 'writes errors key into method output by calling method as specified in string or symbol' do
        should eq "def _some_map\n  (page.as_json(only: [:title])).merge({errors: page.issues(14).as_json})\nend\n"
      end
    end
  end
end