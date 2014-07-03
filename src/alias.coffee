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
#   None
#
# Notes:
#   Use @group_name in your message and your robot will pass it along to
#      each user in the group
#
# Author:
#   Michael Ball @cycomachead

_ = require 'underscore'

module.exports = (robot) ->

  config = process.env.HUBOT_GROUP_ALIAS || ''

  groups = config.split(';')

  # Create 2D list of [alias, users]
  groups = _.map(groups, (value, item, array) -> value.split('='))

  # Convert 2D list to native object
  # expand "user1,user2" to "@user1 @user2"
  groups = _.reduce(groups, (obj, val, index) ->
    sendTo = val[1]
    sendTo = "@" + users.replace(/,/g, ' @')
    obj[val[0].toLowerCase()] = sendTo
    obj
  , {})

  all_aliases = []
  for own k, v of groups
      all_aliases.push(k)

  # Prepend the users @mentions to the message
  expand = (alias, message) ->
    groups[alias] + "\n #{message}"


  # Grabs all messages starting with @
  # TODO: Complie regex?
  # TODO: Handle @ anywhere in message
  robot.hear /@(\w+) (.*)$/i, (msg) ->
    alias = msg.match[1].toLowerCase()
    if alias in all_aliases
      msg.send expand(alias, msg.match[2])

