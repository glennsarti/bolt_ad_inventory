#!/usr/bin/env ruby
# frozen_string_literal: true

[
  # Assumes the ruby_task_helper modules is installed in same directory as this module
  File.join('..', '..', 'ruby_task_helper', 'files', 'task_helper.rb'),
  # During development the ruby_task_helper module will be in the test module fixtures
  File.join(__dir__, '..', 'spec', 'fixtures', 'modules', 'ruby_task_helper', 'files', 'task_helper.rb')
].each do |helper_path|
  if File.exist?(helper_path)
    require_relative helper_path
    break
  end
end
require 'net-ldap'

class ActiveDirectoryInventory < TaskHelper
  def resolve_reference(opts)

    ad_domain = opts[:ad_domain]
    raise TaskHelper::Error.new('The Active Directory Inventory Plugin requires the ad_domain', 'bolt.plugin/validation-error') if ad_domain.nil? || ad_domain.empty?
    domain_controller = opts[:domain_controller] || opts[:ad_domain]

    # A little basic, but it works
    x509_domain = 'dc=' + ad_domain.split('.').join(',dc=')

    ldap_properties = {
      host: domain_controller
    }
    if opts[:username] && opts[:password]
      ldap_properties[:auth] = { method: :simple, username: opts[:username], password: opts[:password] }
    end

    ldap = Net::LDAP.new(ldap_properties)
    # Add authentication if specified

    # Bind to the domain controller
    if ldap.bind
      ldap.search(
        base:         x509_domain,
        filter:       Net::LDAP::Filter.eq( 'objectCategory', 'computer' ),
        attributes:   %w[ dn dNSHostName ],
        return_result:true
      ).map do |entry|
        next unless entry.attribute_names.include?(:dnshostname)
        next if entry.dnshostname.nil? || entry.dnshostname.empty?
        {
          'name' => entry.dn,
          'uri' => entry.dnshostname[0]
        }
      end.compact
    end
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
#  ActiveDirectoryInventory.run
  puts ActiveDirectoryInventory.new.task({
    :ad_domain => 'bolt.local',
    :domain_controller => '192.168.200.200',
    :username => 'BOLT\\Administrator',
    :password => 'Password1'
  })
end
