require 'spec_helper'

describe JSONPresentable::PresenterMethodMaker do
  describe '#print' do
    context 'when errors option is false' do
      subject { JSONPresentable::PresenterMethodMaker.new('page', :default, errors: false, &block).print }

      describe '#attributes' do
        context 'when called with arguments' do
          let(:block) { proc { attributes :id, :username } }

          it 'presents the attributes that are given' do
            should eq "def json_presentable_default\n  (page.as_json(only: [:id, :username]))\nend\n"
          end
        end

        context 'when called WITHOUT arguments' do
          let(:block) { proc { attributes } }

          it 'presents all attributes of the root item' do
            should eq "def json_presentable_default\n  (page.as_json)\nend\n"
          end
        end
      end

      describe '#url_for' do
        context 'when called without options' do
          let(:block) { proc { url_for } }

          it 'presents url' do
            should eq "def json_presentable_default\n  ({url: controller.page_url(page)})\nend\n"
          end
        end

        context 'when called with (path_only: true) option' do
          let(:block) { proc { url_for path_only: true } }

          it 'presents path' do
            should eq "def json_presentable_default\n  ({path: controller.page_path(page)})\nend\n"
          end
        end

        context 'when called with :root option' do
          let(:block) { proc { url_for root: :location } }

          it 'presents url with :root option as root' do
            should eq "def json_presentable_default\n  ({location: controller.page_url(page)})\nend\n"
          end
        end

        context 'when called with :namespace option' do
          let(:block) { proc { url_for namespace: :admin } }

          it 'presents namespaced url' do
            should eq "def json_presentable_default\n  ({url: controller.admin_page_url(page)})\nend\n"
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
            should eq "def json_presentable_default\n  ({user: ({url: controller.user_url(page.user)})})\nend\n"
          end
        end
      end

      describe '#property' do
        context 'when called with a symbol argument' do
          let(:block) { proc { property :permalink } }

          it 'presents that attribute of the root item' do
            should eq "def json_presentable_default\n  ({permalink: page.permalink})\nend\n"
          end
        end

        context 'when called with a single-key hash argument' do
          let(:block) { proc { property permalink: 'humanize(permalink)' } }

          it 'presents that attribute of the root item, getting the value by calling the method given in the hash' do
            should eq "def json_presentable_default\n  ({permalink: page.humanize(permalink)})\nend\n"
          end
        end

        context 'when called with a multiple-key hash argument (nonsense to API)' do
          let(:block) { proc { property permalink: :something, user_id: :something } }
          subject { -> { JSONPresentable::PresenterMethodMaker.new('page', :default, &block).print } }
          it { should raise_error(ArgumentError, "'attribute' called with bad argument") }
        end
      end

      describe '#association' do
        context 'when called WITHOUT a block' do
          let(:block) { proc { association :thing } }

          it 'presents all attributes of the associated item using association name as the root' do
            should eq "def json_presentable_default\n  ({thing: page.thing.as_json})\nend\n"
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
            should eq "def json_presentable_default\n  ({thing: (page.thing.as_json(only: [:id, :weight]))})\nend\n"
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
          should eq "def json_presentable_default\n  #{meat}\nend\n"
        end
      end
    end

    context 'when :url option is set to true' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterMethodMaker.new('page', :default, errors: false, url: true, &block).print }

      it 'includes url of item as controller.url_for(page)' do
        should eq "def json_presentable_default\n  (page.as_json(only: [:title])).merge({url: controller.url_for(page)})\nend\n"
      end
    end

    context 'when :url option is set to a string' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterMethodMaker.new('page', :default, errors: false, url: :something_path, &block).print }

      it 'includes url of item as controller.<string>(page)' do
        should eq "def json_presentable_default\n  (page.as_json(only: [:title])).merge({url: controller.something_path(page)})\nend\n"
      end
    end

    context 'when :url option is set for an association without block' do
      let(:block) do
        proc do
          association :user, url: true
        end
      end

      subject { JSONPresentable::PresenterMethodMaker.new('page', :default, errors: false, &block).print }

      it 'includes url of item as controller.<string>(page)' do
        should eq "def json_presentable_default\n  ({user: page.user.as_json}).merge({url: controller.url_for(page.user)})\nend\n"
      end
    end

    context 'when :url option is set for an association WITH block' do
      let(:block) do
        proc do
          association :user, url: true, errors: false do
            attributes :id
          end
        end
      end

      subject { JSONPresentable::PresenterMethodMaker.new('page', :default, errors: false, &block).print }

      it 'includes url of item as controller.<string>(page)' do
        should eq "def json_presentable_default\n  ({user: (page.user.as_json(only: [:id])).merge({url: controller.url_for(page.user)})})\nend\n"
      end
    end

    context 'when :errors option is true' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterMethodMaker.new('page', :default, errors: true, &block).print }

      it 'writes errors into method' do
        should eq "def json_presentable_default\n  (page.as_json(only: [:title])).merge({errors: page.errors.as_json})\nend\n"
      end
    end

    context 'when errors option is not set at all' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterMethodMaker.new('page', :default, &block).print }

      it 'writes a respond_to? check and errors into method' do
        should eq "def json_presentable_default\n  (page.as_json(only: [:title])).merge(page.respond_to?(:errors) ? {errors: page.errors.as_json} : {})\nend\n"
      end
    end

    context 'when errors option is set to a string or symbol' do
      let(:block) { proc { attributes :title } }
      subject { JSONPresentable::PresenterMethodMaker.new('page', :default, errors: 'issues(14)', &block).print }

      it 'writes errors key into method output by calling method as specified in string or symbol' do
        should eq "def json_presentable_default\n  (page.as_json(only: [:title])).merge({errors: page.issues(14).as_json})\nend\n"
      end
    end
  end
end