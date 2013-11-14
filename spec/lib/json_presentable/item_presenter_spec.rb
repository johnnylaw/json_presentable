require 'spec_helper'

describe JSONPresentable::ItemPresenter do
  let(:error_messages) { [] }
  let(:errors) do
    errs = double 'Errors'
    errs.stub(:as_json).with(full_messages: true).and_return(error_messages)
    errs
  end

  let(:item) do
    item = double 'Item', as_json: { id: 234, name: 'Bubba' }, errors: errors
    item.stub(:class).and_return(Array)
    item
  end

  describe '#as_json' do
    context 'when called with options' do
      subject { JSONPresentable::ItemPresenter.new(item).as_json }
      it { should eq('id' => 234, 'name' => 'Bubba', 'errors' => []) }
    end

    context 'when called without options' do
      subject { JSONPresentable::ItemPresenter.new(item).as_json(something: true) }
      it { should eq('id' => 234, 'name' => 'Bubba', 'errors' => []) }
    end
  end

  describe '#item' do
    subject { JSONPresentable::ItemPresenter.new(item).item }
    it { should eq item }
  end

  describe '#errors' do
    let(:error_messages) do
      { name: 'Name cannot be Bubba' }
    end
    subject { JSONPresentable::ItemPresenter.new(item).errors }

    it { should eq(name: 'Name cannot be Bubba') }
  end

  describe '#json_root' do
    subject { JSONPresentable::ItemPresenter.new(item).json_root }

    it { should eq 'array' }
  end

  describe 'subclasses' do
    subject { Silly::ThingyMaBobPresenter.new(item) }

    before :all do
      module Silly
        class ThingyMaBobPresenter < JSONPresentable::ItemPresenter
        end
      end
    end

    describe 'other item retrieval method (in this case #thingy_ma_bob)' do
      its(:thingy_ma_bob) { should eq item }
    end

    describe '#as_json' do
      its(:as_json) { should eq('id' => 234, 'name' => 'Bubba', 'errors' => []) }
    end

    context 'when the initializer creates an instance variable named after the root object' do
      subject { Silly::SomethingPresenter.new item }

      before :all do
        module Silly
          class SomethingPresenter < JSONPresentable::ItemPresenter
            def initialize(something)
              @something = something
            end
          end
        end
      end

      its(:something) { should eq item }
      its(:as_json) { should eq('id' => 234, 'name' => 'Bubba', 'errors' => []) }
    end

    describe '.mapping' do
      subject { PagePresenter.new(page, mapping: mapping).as_json }
      let(:page) do
        page = double 'Page', errors: errors
        page.stub(:as_json).and_return(id: 234, title: 'My Title', content: 'lorem ipsum etc')
        page
      end

      before :all do
        class PagePresenter < JSONPresentable::ItemPresenter
          mapping :display_only do
            page.as_json.slice :title, :content
          end

          mapping :pages, :admin do
            page.as_json.merge(user: {
              username: 'johnnylaw',
              profile_image: 'http://cloudfront.com/path/to/image.png'
            })
          end
        end
      end

      context 'when mapping is present in class' do
        context 'when one mapping was defined in one statement' do
          let(:mapping) { :display_only }
          it { should eq("title"=>"My Title", "content"=>"lorem ipsum etc", "errors"=>[]) }
        end

        context 'when more than one mapping was defined in a statement' do
          let(:expected_result) do
            {
              "id" => 234, "title" => "My Title", "content" => "lorem ipsum etc",
              "errors" => [], "user" => {
                "username" => "johnnylaw", "profile_image" => "http://cloudfront.com/path/to/image.png"
              }
            }
          end

          context 'when it is one of the defined mappings' do
            let(:mapping) { :pages }
            it { should eq expected_result }
          end

          context 'when it is the other' do
            let(:mapping) { :admin }
            it { should eq expected_result }
          end
        end
      end

      context 'when mapping is present in class' do
        let(:mapping) { 'some_non-existent mapping' }
        it { should eq("id"=>234, "title"=>"My Title", "content"=>"lorem ipsum etc", "errors"=>[]) }
      end
    end
  end
end