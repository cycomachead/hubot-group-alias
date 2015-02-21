# Description:
#   Define user aliases to @ mention groups of people at once.
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

  config = process.env.HUBOT_GROUP_ALIAS

  if !config
    robot.logger.warning "Configuration HUBOT_GROUP_ALIAS is not defined."
    return

  groups = config.split(';')

  # Create 2D list of [alias, users]
  groups = _.map(groups, (val, item, array) -> val.split('='))
  # expand "user1,user2" to "@user1 @user2"
  groups = _.map(groups, (val, item, array) -> [val[0],
    '@' + val[1].split(',').join(' @')])

  # Convert 2D list to native object
  groups = _.object(groups)

  # Replace aliases with @mentions in the message
  expand = (message) ->
    for own k, v of groups
      reg = new RegExp('[:(]' + k + '[:)]|@' + k, 'i')
      message = message.replace(reg, v)
    return message

  # Compile RegEx to match only the aliases
  # Note this matches (alias) :alias: and @alias
  aliases = _.keys(groups).join('|')
  regex = new RegExp('((?:\\(|\\:|@)(' + aliases + ')(?:\\|\\:)*)', 'i')
  robot.hear regex, (msg) ->
    msg.send expand(msg.message.text)