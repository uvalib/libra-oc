require 'spec_helper'

describe CurationConcerns::PersistDerivatives do
  before do
    allow(CurationConcerns.config).to receive(:derivatives_path).and_return('tmp')
  end

  describe '.output_file' do
    subject { described_class.output_file(directives, &block) }

    let(:directives) { { url: "file:/tmp/12/34/56/7-thumbnail.jpeg" } }
    let(:destination_name) { 'thumbnail' }

    let(:block) { lambda { true } }

    it 'yields to the file' do
      expect(FileUtils).to receive(:mkdir_p).with('/tmp/12/34/56')
      expect(File).to receive(:open).with('/tmp/12/34/56/7-thumbnail.jpeg', 'wb') do |*_, &blk|
        expect(blk).to be(block)
      end
      subject
    end
  end
end
