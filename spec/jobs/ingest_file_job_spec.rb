require 'spec_helper'
require 'rails_helper'

describe IngestFileJob do
  let(:file_set) { FactoryGirl.create(:file_set) }
  #let(:filename) { FactoryGirl.fixture_file_path('/world.png') }
  let(:filename) { Rails.root.join("spec", "fixtures", "world.png").to_s }
  let(:user)     { FactoryGirl.create(:user) }

  context 'when given a relationship' do
    before do
      class FileSetWithExtras < FileSet
        directly_contains_one :remastered, through: :files, type: ::RDF::URI('http://pcdm.org/use#IntermediateFile'), class_name: 'Hydra::PCDM::File'
      end
    end
    let(:file_set) do
      FileSetWithExtras.create!(FactoryGirl.attributes_for(:file_set)) do |file|
        file.apply_depositor_metadata(user.user_key)
      end
    end
    after do
      Object.send(:remove_const, :FileSetWithExtras)
    end
    it 'uses the provided relationship' do
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String)
      described_class.perform_now(file_set, filename, user, mime_type: 'image/png', relation: 'remastered')
      expect(file_set.reload.remastered.mime_type).to eq 'image/png'
    end
  end

  context 'when given a mime_type' do
    it 'uses the provided mime_type' do
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String)
      described_class.perform_now(file_set, filename, user, mime_type: 'image/png')
      expect(file_set.reload.original_file.mime_type).to eq 'image/png'
    end
  end

  context 'when not given a mime_type' do
    before { allow(CurationConcerns::VersioningService).to receive(:create) }
    it 'passes a decorated instance of the file with a nil mime_type' do
      # The parameter versioning: false instructs the machinery in Hydra::Works NOT to do versioning
      # so it can be handled later on.
      expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(
        file_set,
        instance_of(Hydra::Derivatives::IoDecorator),
        :original_file,
        versioning: false
      ).and_call_original
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String)
      described_class.perform_now(file_set, filename, user)
    end
  end

end
