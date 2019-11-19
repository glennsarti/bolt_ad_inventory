# Changelog

All notable changes to this project will be documented in this file.

## Development

* Added the ability to filter out computers with properties older than a given number of days
  New parameters `filter_older_than_days` and `filter_older_attribute`.
  
  Contributed by Nick Maludy (@nmaludy Encore Technologies)
  
* Added the ability to ignore a set of hosts by their DNS hostname using the new parameter
  `ignore_dns_hostnames`.
  
  Contributed by Nick Maludy (@nmaludy Encore Technologies)
  
* Added the ability to only return computers/hosts if they are a member of a given
  AD group (by specifying the group's full `dn`) using the new property `member_of_group_dn`.
  
  Contributed by Nick Maludy (@nmaludy Encore Technologies)
  
## Release 0.1.0

**Features**

**Bugfixes**

**Known Issues**
