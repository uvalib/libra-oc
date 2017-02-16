require 'spec_helper'

module Sipity
  RSpec.describe Entity, type: :model do
    describe 'database configuration', no_clean: true do
      subject { described_class }
      its(:column_names) { is_expected.to include("proxy_for_global_id") }
      its(:column_names) { is_expected.to include("workflow_id") }
      its(:column_names) { is_expected.to include("workflow_state_id") }
    end

    subject { described_class.new }

    describe 'delegations', no_clean: true do
      it { is_expected.to delegate_method(:workflow_state_name).to(:workflow_state).as(:name) }
      it { is_expected.to delegate_method(:workflow_name).to(:workflow).as(:name) }
    end

    describe '#proxy_for' do
      let(:work) { FactoryGirl.create(:generic_work) }
      it 'will retrieve based on a GlobalID of the object' do
        entity = Sipity::Entity.create!(proxy_for_global_id: work.to_global_id, workflow_state_id: 1, workflow_id: 2)
        expect(entity.proxy_for).to eq(work)
      end
    end
  end
end
