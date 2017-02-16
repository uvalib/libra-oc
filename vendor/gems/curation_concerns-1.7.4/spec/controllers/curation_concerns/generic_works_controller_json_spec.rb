require 'spec_helper'

# This tests the CurationConcerns::CurationConcernController module
# which is included into .internal_test_app/app/controllers/generic_works_controller.rb
describe CurationConcerns::GenericWorksController do
  let(:user) { create(:user) }
  before { sign_in user }

  context "JSON" do
    let(:resource) { create(:private_generic_work, user: user) }
    let(:resource_request) { get :show, params: { id: resource, format: :json } }
    subject { response }

    describe "unauthorized" do
      before do
        sign_out user
        resource_request
      end
      it { is_expected.to respond_unauthorized }
    end

    describe "forbidden" do
      before do
        sign_in create(:user)
        resource_request
      end
      it { is_expected.to respond_forbidden }
    end

    describe 'not found' do
      before { get :show, params: { id: "non-existent-pid", format: :json } }
      it { is_expected.to respond_not_found }
    end

    describe 'created' do
      let(:actor) { double(create: create_status) }
      let(:create_status) { true }
      let(:model) { stub_model(GenericWork) }

      before do
        allow(CurationConcerns::CurationConcern).to receive(:actor).and_return(actor)
        allow(controller).to receive(:curation_concern).and_return(model)
        post :create, params: { generic_work: { title: ['a title'] }, format: :json }
      end

      it "returns 201, renders show template sets location header" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(assigns[:curation_concern]).to be_instance_of GenericWork
        expect(controller).to render_template('curation_concerns/base/show')
        expect(response.code).to eq "201"
        expect(response.location).to eq main_app.curation_concerns_generic_work_path(model)
      end
    end

    describe 'failed create' do
      before { post :create, params: { generic_work: {}, format: :json } }
      it "returns 422 and the errors" do
        created_resource = assigns[:curation_concern]
        expect(response).to respond_unprocessable_entity(errors: created_resource.errors.messages.as_json)
      end
    end

    describe 'found' do
      before { resource_request }
      it "returns json of the work" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(assigns[:curation_concern]).to be_instance_of GenericWork
        expect(controller).to render_template('curation_concerns/base/show')
        expect(response.code).to eq "200"
      end
    end

    describe 'updated' do
      before { put :update, params: { id: resource, generic_work: { title: ['updated title'] }, format: :json } }
      it "returns 200, renders show template sets location header" do
        # Ensure that @curation_concern is set for jbuilder template to use
        expect(assigns[:curation_concern]).to be_instance_of GenericWork
        expect(controller).to render_template('curation_concerns/base/show')
        expect(response.code).to eq "200"
        created_resource = assigns[:curation_concern]
        expect(response.location).to eq main_app.curation_concerns_generic_work_path(created_resource)
      end
    end

    describe 'failed update' do
      before do
        post :update, params: { id: resource, generic_work: { title: [''] }, format: :json }
      end
      it "returns 422 and the errors" do
        expect(response).to respond_unprocessable_entity(errors: { title: ["Your work must have a title."] })
      end
    end
  end
end
