# ad_inventory

The ad_inventory Puppet Module is an [Inventory Plugin](https://puppet.com/docs/bolt/latest/using_plugins.html#ariaid-title2) for Bolt which can dynamically query Active Directory for target information.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with ad_inventory](#setup)
    * [What ad_inventory affects](#what-ad_inventory-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with ad_inventory](#beginning-with-ad_inventory)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

Briefly tell users why they might want to use your module. Explain what your module does and what kind of problems users can solve with it.

This should be a fairly short description helps the user decide if your module is what they want.

## Setup

Install net-ldap gem into Bolt

On Windows

``` text
> "C:/Program Files/Puppet Labs/Bolt/bin/gem.bat" install --user-install net-ldap
```

On other platforms

``` text
> /opt/puppetlabs/bolt/bin/gem install --user-install net-ldap
```

Reference - [Bolt Documentation](https://puppet.com/docs/bolt/latest/bolt_installing.html#ariaid-title13)

### Development

``` text
> bundle exec rake spec_prep

...

> bundle exec bolt command run "Write-Host 'Hello'" --modulepath spec/fixtures/modules --inventoryfile example_inventory.yaml
```

Example Inventory

``` yaml
# inventory.yaml
version: 2
groups:
  - name: all_bolt_domain
    targets:
      - _plugin: ad_inventory
        ad_domain: 'bolt.local'
        domain_controller: '192.168.200.200'
        user: 'BOLT\\Administrator'
        password: 'Password1'
```

### Example: Ignore computers older than given number of days

Sometimes computers are rebuilt, but not deleted from Active Directory.
This can cause stale objects within AD.
This bolt plugin can ignore objects older than a given number of days.

To do this there are two options available on the plugin:

* `ignore_older_than_attribute` : This is the name of the LDAP attribute that contains a LDAP timestamp value that we'll use for ignoring. Common attributes used are `pwdLastSet` or `lastLogonTimestamp`.

* `ignore_older_than_days` : Number of days (integer) that will be used as the cut-off point. If an object is older than this many days it will not be part of the inventory.

``` yaml
# inventory.yaml
version: 2
groups:
  - name: all_bolt_domain
    targets:
      - _plugin: ad_inventory
        ad_domain: 'bolt.local'
        domain_controller: '192.168.200.200'
        user: 'BOLT\\Administrator'
        password: 'Password1'
        ignore_older_than_attribute: 'pwdLastSet'
        ignore_older_than_days: 30
```

### Example: Ignore computers by DNS hostname

It's common that a computer may be returned from AD, but you have may not be able to connect to it: For example, it's behind a firewall or requires a bastion host.
The `ignore_dns_hostnames` attribute is used to ignore specific computers which match their DNS hostname in AD. Pass in an array of hostnames into this option, and any host matching that name will be excluded.

Note that this must be an exact name match and is case-sensitive

``` yaml
# inventory.yaml
version: 2
groups:
  - name: all_bolt_domain
    targets:
      - _plugin: ad_inventory
        ad_domain: 'bolt.local'
        domain_controller: '192.168.200.200'
        user: 'BOLT\\Administrator'
        password: 'Password1'
        ignore_dns_hostnames:
          - mybadwinrm.bolt.local
          - mybaddc01.bolt.local
          - sccm03.bolt.local
```

### Example: Only return members of a given group

It is common for AD administrators to use groups to categorize Computers to ease administrative burden.
For example, applying Group Policies or restricting authentication.
You can use the `member_of_group_dn` attribute to return the Computer objects for a particular group.
This enables you to use your existing administrative groups with Bolt.

Note - The `member_of_group_dn` is the full Distinguished Name (`dn`) of the group.
For example: `CN=WSUS Servers,OU=GPO Groups,OU=Groups,DC=domain,DC=tld,DC=tech`.

Note - This does not match nested groups; only immediate group membership.
For example, if `Computer1` is a member of `WSUS Servers`, and `WSUS Servers` is a member of `All Servers`

``` text
  Computer Object: Computer1`
    |
    +---- Member of Group: WSUS Servers
            |
            +---- Member of Group: All Servers
```

The plugin will find `Computer1` if the `member_of_group_dn` is set to WSUS Servers, but not All Servers.

Note - The plugin binds using `ldap://`, not via [Global Catalog](https://docs.microsoft.com/en-us/windows/win32/ad/global-catalog) (`gc://`) therefore [Universal Groups](https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/active-directory-security-groups) may not be available (The Domain Controller must also host a Global Catalog). Domain Local and Global Groups can be used.

``` yaml
# inventory.yaml
version: 2
groups:
  - name: patching_group_bolt_domain
    targets:
      - _plugin: ad_inventory
        ad_domain: 'bolt.local'
        domain_controller: '192.168.200.200'
        user: 'BOLT\\Administrator'
        password: 'Password1'
        member_of_group_dn: 'CN=Patching Group 1,OU=GPO Groups,OU=Groups,DC=bolt,DC=local'
```
