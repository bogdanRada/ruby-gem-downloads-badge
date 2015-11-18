require 'spec_helper'
describe RubygemsApi do
  let(:params) { { gem: 'rails', version: 'stable', tyoe: 'total' } }
  let(:callback) { -> {} }
  let(:subject) { RubygemsApi.new(params, callback) }

  before(:each) do
    allow_any_instance_of(RubygemsApi).to receive(:fetch_downloads_data).and_return('this is the value to return')
  end

  it 'responds to init_record' do
    expect(subject).to respond_to :params
  end

  it 'responds to callback' do
    expect(subject).to respond_to :callback
  end

  describe 'initialize' do
    it 'should initialize the params' do
      expect(subject.params).to eq params.stringify_keys
    end
    it 'should initialize the callback' do
      expect(subject.callback).to eq callback
    end
  end

  describe 'valid' do
    it 'should be valid' do
      expect(subject).to be_valid
    end
  end
end
