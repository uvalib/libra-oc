require 'spec_helper'

describe CurationConcerns::Renderers::LinkedAttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['Bob', 'Jessica']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) {
      "<tr><th>Name</th>\n" \
       "<td><ul class='tabular'>" \
       "<li class=\"attribute name\"><a href=\"/catalog?q=Bob&amp;search_field=name\">Bob</a></li>\n" \
       "<li class=\"attribute name\"><a href=\"/catalog?q=Jessica&amp;search_field=name\">Jessica</a></li>\n" \
       "</ul></td></tr>"
    }
    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
