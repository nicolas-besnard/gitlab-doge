class Repo < ActiveRecord::Base
  has_many :memberships
  has_many :users, through: :memberships
  has_many :builds

  alias_attribute :name, :full_github_name

  validates :full_github_name, presence: true
  validates :github_id, uniqueness: true, presence: true

  def self.active
    where(active: true)
  end

  def self.find_or_create_with(attributes)
    repo = where(github_id: attributes[:github_id]).first_or_initialize
    repo.update_attributes(attributes)
    repo
  end

  def self.find_and_update(github_id, repo_name)
    repo = find_by(github_id: github_id)

    if repo && repo.full_github_name != repo_name
      repo.update(full_github_name: repo_name)
    end

    repo
  end

  def activate
    update(active: true)
  end

  def deactivate
    update(active: false)
  end

  def exempt?
    ENV["EXEMPT_ORGS"] && ENV["EXEMPT_ORGS"].split(",").include?(organization)
  end

  private

  def organization
    if full_github_name
      full_github_name.split("/").first
    end
  end
end
