require 'spec_helper'

describe 'layouts/error.html.erb' do
  it 'renders without errors' do
    render
    expect(rendered).to have_css("footer")
  end
end
