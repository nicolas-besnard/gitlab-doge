require 'spec_helper'
require 'app/jobs/repo_synchronization_job'

describe RepoSynchronizationJob do
  before :each do
    allow(GitlabToken).to receive(:token_by_dn).and_return('gitlabdogetoken')
  end
  describe '.perform' do
    it 'syncs repos and sets refreshing_repos to false' do
      user = create(:user, refreshing_repos: true)
      gitlab_token = 'token'
      synchronization = double(:repo_synchronization, start: nil)
      allow(RepoSynchronization).to receive(:new).and_return(synchronization)

      RepoSynchronizationJob.new.perform(user.id, gitlab_token)

      expect(RepoSynchronization).to have_received(:new).with(
        user,
        gitlab_token
      )
      expect(synchronization).to have_received(:start)
      expect(user.reload).not_to be_refreshing_repos
    end
  end
end
