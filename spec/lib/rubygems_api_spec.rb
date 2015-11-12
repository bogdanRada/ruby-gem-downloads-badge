require 'spec_helper'
describe RubygemsApi do
  let(:out) { StringIO.new }
  let(:downloads) { '1234' }
  let(:params) do
    {
      gem: 'rails',
      version: 'stable',
      type: 'total'
    }
  end
  let(:badge_downloader) { BadgeDownloader.new(params, out, downloads) }
  let(:callback) { ->(_downloads) { badge_downloader } }
  let(:subject) { RubygemsApi.new(params, callback) }

  before(:each) do
    
  end

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
