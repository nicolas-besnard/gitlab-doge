require "spec_helper"

describe DeactivationsController, "#create" do
  context "when deactivation succeeds" do
    it "returns successful response" do
      token = "sometoken"
      membership = create(:membership)
      repo = membership.repo
      activator = double(:repo_activator, deactivate: true)
      allow(RepoActivator).to receive(:new).and_return(activator)
      stub_sign_in(membership.user, token)

      post :create, repo_id: repo.id, format: :json

      expect(response.code).to eq "201"
      expect(response.body).to eq RepoSerializer.new(repo).to_json
      expect(activator).to have_received(:deactivate)
      expect(RepoActivator).to have_received(:new).
        with(repo: repo, github_token: token)
    end
  end

  context "when deactivation fails" do
    it "returns error response" do
      token = "sometoken"
      membership = create(:membership)
      repo = membership.repo
      activator = double(:repo_activator, deactivate: false)
      allow(RepoActivator).to receive(:new).and_return(activator)
      stub_sign_in(membership.user, token)

      post :create, repo_id: repo.id, format: :json

      expect(response.code).to eq "502"
      expect(activator).to have_received(:deactivate)
      expect(RepoActivator).to have_received(:new).
        with(repo: repo, github_token: token)
    end

    it "notifies Sentry" do
      membership = create(:membership)
      repo = membership.repo
      activator = double(:repo_activator, deactivate: false)
      allow(RepoActivator).to receive(:new).and_return(activator)
      allow(Raven).to receive(:capture_exception)
      stub_sign_in(membership.user)

      post :create, repo_id: repo.id, format: :json

      expect(Raven).to have_received(:capture_exception).with(
        DeactivationsController::FailedToActivate.new(
          "Failed to deactivate repo"
        ),
        extra: { user_id: membership.user.id, repo_id: repo.id.to_s }
      )
    end
  end
end
