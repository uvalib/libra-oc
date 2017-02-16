require 'spec_helper'

describe CurationConcerns::SingleUseLinksViewerController do
  routes { CurationConcerns::Engine.routes }
  let(:file) do
    file = FileSet.create do |lfile|
      lfile.label = 'world.png'
      lfile.apply_depositor_metadata('mjg')
    end
    Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :original_file)
    file
  end

  describe "retrieval links" do
    let :show_link do
      SingleUseLink.create itemId: file.id, path: Rails.application.routes.url_helpers.curation_concerns_file_set_path(id: file)
    end

    let :download_link do
      SingleUseLink.create itemId: file.id, path: Rails.application.routes.url_helpers.download_path(id: file)
    end

    let(:show_link_hash) { show_link.downloadKey }
    let(:download_link_hash) { download_link.downloadKey }

    describe "GET 'download'" do
      let(:expected_content) { ActiveFedora::Base.find(file.id).original_file.content }

      it "downloads the file and deletes the link from the database" do
        expect(controller).to receive(:send_file_headers!).with(filename: 'world.png', disposition: 'attachment', type: 'image/png')
        get :download, params: { id: download_link_hash }
        expect(response.body).to eq expected_content
        expect(response).to be_success
        expect { SingleUseLink.find_by_downloadKey!(download_link_hash) }.to raise_error ActiveRecord::RecordNotFound
      end

      context "when the key is not found" do
        before { SingleUseLink.find_by_downloadKey!(download_link_hash).destroy }

        it "returns 404" do
          get :download, params: { id: download_link_hash }
          expect(response).to render_template("curation_concerns/single_use_links_viewer/single_use_error", "layouts/error")
        end
      end
    end

    describe "GET 'show'" do
      it "renders the file set's show page and deletes the link from the database" do
        get 'show', params: { id: show_link_hash }
        expect(response).to be_success
        expect(assigns[:presenter].id).to eq file.id
        expect { SingleUseLink.find_by_downloadKey!(show_link_hash) }.to raise_error ActiveRecord::RecordNotFound
      end

      context "when the key is not found" do
        before { SingleUseLink.find_by_downloadKey!(show_link_hash).destroy }
        it "returns 404" do
          get :show, params: { id: show_link_hash }
          expect(response).to render_template("curation_concerns/single_use_links_viewer/single_use_error", "layouts/error")
        end
      end

      it "returns 404 on attempt to get show path with download hash" do
        get :show, params: { id: download_link_hash }
        expect(response).to render_template("curation_concerns/single_use_links_viewer/single_use_error", "layouts/error")
      end
    end
  end
end
