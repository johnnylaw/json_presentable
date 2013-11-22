require 'spec_helper'

describe JSONPresentable::PresenterMethodMaker do
  describe '#print' do
    subject { JSONPresentable::PresenterMethodMaker.new('page', :default, &block).print }

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

    describe '#attribute' do
      context 'when called with a symbol argument' do
        let(:block) { proc { attribute :permalink } }

        it 'presents that attribute of the root item' do
          should eq "def json_presentable_default\n  (page.as_json(only: [:permalink]))\nend\n"
        end
      end

      context 'when called with a single-key hash argument' do
        let(:block) { proc { attribute permalink: 'humanize(permalink)' } }

        it 'presents that attribute of the root item, getting the value by calling the method given in the hash' do
          should eq "def json_presentable_default\n  ({permalink: page.humanize(permalink)})\nend\n"
        end
      end

      context 'when called with a multiple-key hash argument (nonsense to API)' do
        let(:block) { proc { attribute permalink: :something, user_id: :something } }
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
            association :thing do
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
          association :thing do
            attributes :id, :height
            attribute permalink: 'humanize(permalink)'
          end
        end
      end

      it 'merges all the right things together' do
        meat = "(page.as_json(only: [:id, :title])).merge({thing: (page.thing.as_json(only: [:id, :height])).merge({permalink: page.thing.humanize(permalink)})})"
        should eq "def json_presentable_default\n  #{meat}\nend\n"
      end
    end
  end
end