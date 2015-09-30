require 'spec_helper'
describe RubygemsApi do
  let(:params) { { gem: 'rails', version: 'stable', tyoe: 'total' } }
  let(:subject) { RubygemsApi.new(params) }

  it 'responds to init_record' do
    expect(subject).to respond_to :params
  end

  describe 'initialize' do
    it 'should initialize the params' do
      expect(subject.params).to eq params.stringify_keys
    end

    it 'sets the downloads to nil' do
      expect(subject.downloads).to eq nil
    end
  end

  describe 'valid' do
    it 'should be valid' do
      expect(subject).to be_valid
    end
  end
end
