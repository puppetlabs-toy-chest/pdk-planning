#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'octokit'

module WhenProjectCreated
  def self.debug?
    # TODO: it would be nice to have a better way to check this...
    ENV['GITHUB_ACTIONS'].nil? || ENV['GITHUB_ACTOR'] == 'nektos/act'
  end

  def self.gh_client
    @gh_client ||= Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'])
  end

  def self.event
    @event ||= JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
  end

  def self.milestone_from_event(event)
    abort("incomplete/wrong event payload received, missing 'project.name':\n\n #{event}") unless event.dig('project', 'name')
    abort("incomplete/wrong event payload received, missing 'project.html_url':\n\n #{event}") unless event.dig('project', 'html_url')

    {
      name: event['project']['name'].gsub(/\ARelease /, ''),
      link: event['project']['html_url'],
    }
  end

  def self.repo_has_milestone?(repo, milestone)
    gh_client.list_milestones(repo, state: 'all').any? { |ms| ms[:title] == milestone[:name] }
  end

  def self.create_milestone!(repo, milestone)
    if repo_has_milestone?(repo, milestone)
      puts "Milestone '#{milestone[:name]}' already exists on #{repo}, skipping"
      return
    end

    if debug?
      puts "Would have created milestone '#{milestone[:name]}' on #{repo}"
      return
    end

    gh_client.create_milestone(repo, milestone[:name], {
      description: "See #{milestone[:link]} for complete release planning",
    })

    if gh_client.last_response.status == 201
      puts "Created milestone '#{milestone[:name]}' on #{repo}"
      return
    end

    error = gh_client.last_response.body
    abort "Failed to create milestone '#{milestone[:name]}' on #{repo}:\n\n#{error}"
  end
end

abort("GITHUB_TOKEN must be set") unless ENV['GITHUB_TOKEN']
abort("GITHUB_EVENT_PATH must be set") unless ENV['GITHUB_EVENT_PATH']

@event = WhenProjectCreated.event

if @event.dig('project', 'name') !~ /\ARelease /
  puts "New project does not match /\\ARelease /, skipping"
  exit(0)
end

@milestone = WhenProjectCreated.milestone_from_event(@event)

%w[
  puppetlabs/pdk
  puppetlabs/pdk-templates
  puppetlabs/pdk-vanagon
].each do |repo|
  WhenProjectCreated.create_milestone!(repo, @milestone)
end
