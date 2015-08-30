require_relative '../rails_helper'
require 'stringio'

describe Import do
  describe 'validations' do
    it { should validate_presence_of(:person) }
    it { should validate_presence_of(:filename) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:importable_type).in_array(['Person']) }
  end

  describe '#status_at_least?' do
    context 'given argument is parsed' do
      context 'given status is pending' do
        before { subject.status = :pending }

        it 'returns false' do
          expect(subject.status_at_least?('parsed')).to eq(false)
        end
      end

      context 'given status is parsed' do
        before { subject.status = :parsed }

        it 'returns true' do
          expect(subject.status_at_least?('parsed')).to eq(true)
        end
      end

      context 'given status is complete' do
        before { subject.status = :complete }

        it 'returns true' do
          expect(subject.status_at_least?('parsed')).to eq(true)
        end
      end
    end
  end

  describe '#mappable_attributes' do
    subject { FactoryGirl.create(:import) }

    it 'returns array of attribute names' do
      expect(subject.mappable_attributes).to be_an(Array)
      expect(subject.mappable_attributes).to include(
        'first_name',
        'family_name'
      )
    end
  end

  describe '#parse_async' do
    subject { FactoryGirl.create(:import) }

    let(:file) { StringIO.new("first,last\nTim,Morgan\nJen,Morgan") }

    before do
      allow(ImportParserJob).to receive(:perform_later)
    end

    it 'updates the row count' do
      subject.parse_async(file: file, strategy_name: 'csv')
      expect(subject.reload.row_count).to eq(2)
    end
  end

  describe '#progress' do
    context 'given the status is parsed' do
      subject { FactoryGirl.create(:import, status: :parsed) }

      it 'returns 30' do
        expect(subject.progress).to eq(30)
      end
    end

    context 'given the status is parsing' do
      subject { FactoryGirl.create(:import, status: :parsing) }

      context 'given there are 0 rows parsed' do
        it 'returns 1' do
          expect(subject.progress).to eq(1)
        end
      end

      context 'given there are 1 of 5 rows parsed' do
        before do
          subject.row_count = 5
          FactoryGirl.create(:import_row, status: :parsed, import: subject)
        end

        it 'returns 7' do
          expect(subject.progress).to eq(7)
        end
      end

      context 'given there are 3 of 5 rows parsed' do
        before do
          subject.row_count = 5
          FactoryGirl.create_list(:import_row, 3, status: :parsed, import: subject)
        end

        it 'returns 18' do
          expect(subject.progress).to eq(18)
        end
      end

      context 'given there are 5 of 5 rows parsed' do
        before do
          subject.row_count = 5
          FactoryGirl.create_list(:import_row, 5, status: :parsed, import: subject)
        end

        it 'returns 29' do
          expect(subject.progress).to eq(29)
        end
      end
    end

    context 'given the status is active' do
      subject { FactoryGirl.create(:import, status: :active) }

      context 'given there are 3 of 5 rows imported' do
        before do
          subject.row_count = 5
          FactoryGirl.create_list(:import_row, 3, status: :imported, import: subject)
          FactoryGirl.create_list(:import_row, 2, status: :parsed, import: subject)
        end

        it 'returns 84' do
          expect(subject.progress).to eq(84)
        end
      end

      context 'given there are 5 of 5 rows imported' do
        before do
          subject.row_count = 5
          FactoryGirl.create_list(:import_row, 5, status: :imported, import: subject)
        end

        it 'returns 99' do
          expect(subject.progress).to eq(99)
        end
      end
    end
  end
end