require 'spec_helper'

describe CurationConcerns::AbilityHelper do
  describe "#visibility_badge" do
    subject { helper.visibility_badge visibility }
    {
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC =>
        "<span class=\"label label-success\">Open Access</span>",
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED =>
        "<span class=\"label label-info\">%s</span>",
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE =>
        "<span class=\"label label-danger\">Private</span>",
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO =>
        "<span class=\"label label-warning\">Embargo</span>",
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE =>
        "<span class=\"label label-warning\">Lease</span>"
    }.each do |value, output|
      context value do
        let(:visibility) { value }
        it { expect(subject).to eql(output % t('curation_concerns.institution_name')) }
      end
    end
  end
  describe "#visibility_options" do
    let(:public_opt) { ['Open Access', Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC] }
    let(:authenticated_opt) { [t('curation_concerns.institution_name'), Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED] }
    let(:private_opt) { ['Private', Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE] }
    subject { helper.visibility_options(option) }
    context 'all options' do
      let(:options) { [public_opt, authenticated_opt, private_opt] }
      let(:option) { nil }
      it { is_expected.to eql(options) }
    end
    context 'restricting options' do
      let(:options) { [private_opt, authenticated_opt] }
      let(:option) { :restrict }
      it { is_expected.to eql(options) }
    end
    context 'loosening options' do
      let(:options) { [public_opt, authenticated_opt] }
      let(:option) { :loosen }
      it { is_expected.to eql(options) }
    end
  end
end
