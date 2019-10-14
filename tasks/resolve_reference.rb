#!/usr/bin/env ruby
# frozen_string_literal: true

task_helper = [
  # During a real bolt call, ruby_task_helper modules is installed in same directory as this module
  File.join(__dir__, '..', '..', 'ruby_task_helper', 'files', 'task_helper.rb'),
  # During development the ruby_task_helper module will be in the test module fixtures
  File.join(__dir__, '..', 'spec', 'fixtures', 'modules', 'ruby_task_helper', 'files', 'task_helper.rb')
].find { |helper_path| File.exist?(helper_path) }
raise "Could not find the Bolt ruby_task_helper" if task_helper.nil?
require_relative task_helper

require 'net-ldap'

class ActiveDirectoryInventory < TaskHelper
  DEFAULT_AD_ATTRIBUTES = %w[dn dNSHostName operatingSystem].freeze

  def resolve_reference(opts)
    # Can't search by group, yet!
    raise "Searching by group is currently not implemented" unless opts[:group].nil? || opts[:group].empty?

    ad_domain = opts[:ad_domain]
    raise TaskHelper::Error.new('The Active Directory Inventory Plugin requires the ad_domain', 'bolt.plugin/validation-error') if ad_domain.nil? || ad_domain.empty?
    domain_controller = opts[:domain_controller] || opts[:ad_domain]

    # A little basic, but it works
    x500_domain = 'DC=' + ad_domain.split('.').join(',DC=')

    ldap_properties = {
      host: domain_controller
    }
    # Add authentication if specified
    if opts[:user] && opts[:password]
      ldap_properties[:auth] = { method: :simple, username: opts[:user], password: opts[:password] }
    end
    ldap = Net::LDAP.new(ldap_properties)

    # Bind to the domain controller
    bind_result = ldap.bind
    raise "Error occured binding to the domain controller #{ldap_properties[:host]}: #{ldap.get_operation_result.message} #{ldap.get_operation_result.error_message}" unless ldap.get_operation_result.code.zero?

    # Execute the search
    calc_transport = opts[:calculate_transport] || true
    result = []
    ldap.search(
      base:         x500_domain,
      filter:       Net::LDAP::Filter.eq( 'objectCategory', 'computer' ),
      attributes:   DEFAULT_AD_ATTRIBUTES,
      return_result: false
    ) do |entry|
      obj = ad_entry_to_target_hash(entry, calc_transport)
      result << obj unless obj.nil?
    end
    raise "Error occured querying active directory: #{ldap.get_operation_result.message} #{ldap.get_operation_result.error_message}" unless ldap.get_operation_result.code.zero?
    result
  end

  # private
  def ad_entry_to_target_hash(entry, calculate_transport)
    return unless entry.attribute_names.include?(:dnshostname)
    return if entry.dnshostname.nil? || entry.dnshostname.empty?

    transport = nil
    if calculate_transport
      # If the operatingSystem attribute is missing, don't even try to calculate the
      # transport as we have no idea at all.
      if entry.attribute_names.include?(:operatingsystem) &&
        !entry.operatingsystem.nil?
        # This is fairly naive but effective. A simple regex of 'Does it have the word windows in it'
        # is used to switch between WinRM transport (Windows targets) and SSH transport (everything else)
        transport = entry.operatingsystem.to_s.match(/windows/i) ? 'winrm' : 'ssh'
      end
    end

    {
      'name' => entry.dn,
      'uri' => entry.dnshostname[0],
    }.tap { |i| i['config'] = { 'transport' => transport} unless transport.nil? }
  end

  def task(opts)
    targets = resolve_reference(opts)
    return { value: targets }
  rescue TaskHelper::Error => e
    # ruby_task_helper doesn't print errors under the _error key, so we have to
    # handle that ourselves
    return { _error: e.to_h }
  end
end

if $PROGRAM_NAME == __FILE__
  # TODO: DEBUG
  if (__dir__.start_with?('C:/Source/'))
    puts ActiveDirectoryInventory.new.task({
      :ad_domain => 'bolt.local',
      :domain_controller => '192.168.200.200',
      :user => 'BOLT\\Administrator',
      :password => 'Password1',
    })
    return
  end
  ActiveDirectoryInventory.run
end
