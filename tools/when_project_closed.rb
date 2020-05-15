#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'octokit'

module WhenProjectClosed
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

  def self.milestone_name_from_event(event)
    abort("incomplete/wrong event payload received, missing 'project.name':\n\n #{event}") unless event.dig('project', 'name')

    event['project']['name'].gsub(/\ARelease /, '')
  end

  def self.get_open_milestone_by_name(repo, milestone_name)
    gh_client.list_milestones(repo, state: 'open').find { |ms| ms[:title] == milestone_name }
  end

  def self.close_milestone!(repo, milestone)
    if debug?
      puts "Would have closed milestone '#{milestone[:title]}' (##{milestone[:id]}) on '#{repo}'"
      return
    end

    gh_client.update_milestone(repo, milestone[:id], { :state => 'closed' })

    if gh_client.last_response.status == 200
      puts "Closed milestone '#{milestone[:title]}' (##{milestone[:id]}) on '#{repo}'"
      return
    end

    error = gh_client.last_response.body
    abort "Failed to close milestone '#{milestone[:name]}' (##{milestone[:id]}) on '#{repo}':\n\n#{error}"
  end
end

abort("GITHUB_TOKEN must be set") unless ENV['GITHUB_TOKEN']
abort("GITHUB_EVENT_PATH must be set") unless ENV['GITHUB_EVENT_PATH']

@event = WhenProjectClosed.event

if @event.dig('project', 'name') !~ /\ARelease /
  puts "Closed project does not match /\\ARelease /, skipping"
  exit(0)
end

@milestone_name = WhenProjectClosed.milestone_name_from_event(@event)

%w[
  puppetlabs/pdk
  puppetlabs/pdk-templates
  puppetlabs/pdk-vanagon
].each do |repo|
  milestone = WhenProjectClosed.get_open_milestone_by_name(repo, @milestone_name)

  if !milestone
    puts "Milestone '#{@milestone_name}' does not exist or is already closed on '#{repo}', skipping"
    next
  end

  WhenProjectClosed.close_milestone!(repo, milestone)
end
