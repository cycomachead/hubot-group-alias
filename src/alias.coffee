# Description:
#   Define user groups to @ mention groups of people at once.
#
# Dependencies:
#   underscorejs
#
# Configuration:
#   HUBOT_GROUP_ALIAS: group1=user1,user2;group2=user1,user2,user3 [...]
#
# Commands:
#   None, use @mention a defined group
#
# Author:
#   Michael Ball @cycomachead
_ = require 'underscore'

module.exports = (robot) ->
  # TODO: guard better against empty configs
  config = process.env.HUBOT_GROUP_ALIAS || ''

  groups = config.split(';')

  groups = _.map(groups, (value, item, array) -> value.split('='))

  groups = _.reduce(groups, (obj, val, index) ->
    obj[val[0]] = val[1]
    obj
  , {})

  all_aliases = []
  for own k, v of groups
      all_aliases.push(k)


  expand = (alias, message) ->
    users = groups[alias]
    users = "@" + users.replace(/,/g, ' @')
    users += " #{message}"
    users

  robot.hear /@(\w+) (.*)$/i, (msg) ->
    alias = msg.match[1]
    if alias in all_aliases
      msg.send expand(alias, msg.match[2])

