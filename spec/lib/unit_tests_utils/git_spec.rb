require 'spec_helper'
require_relative '../../../lib/unit_tests_utils'

describe UnitTestsUtils::Git do
  let(:shortened_hash) { '01092b4' }
  let(:long_hash) { '01092b48eb7a0809bb6d5a2dcac6efb662ec21a0' }

  before(:example) do
    allow(UnitTestsUtils::Git).
      to receive(:`).
      with('git log -1 --format="%h"').
      and_return("#{shortened_hash}\n")
    allow(UnitTestsUtils::Git).
      to receive(:`).
      with('git log -1 --format="%H"').
      and_return("#{long_hash}\n")
  end

  describe '.last_commit_hash' do
    context 'when the shortened commit hash is requested' do
      it 'returns the shortened commit hash' do
        expect(UnitTestsUtils::Git.last_commit_hash).to eq shortened_hash
        expect(UnitTestsUtils::Git.last_commit_hash(shortened_hash: true)).to eq shortened_hash
      end
    end

    context 'when the long commit hash is requested' do
      it 'returns the long commit hash' do
        expect(UnitTestsUtils::Git.last_commit_hash(shortened_hash: false)).to eq long_hash
      end
    end
  end
end
