# Description:
#   Define user aliases to @ mention groups of people at once.
#
# Dependencies:
#   underscorejs
#
# Configuration:
#   HUBOT_GROUP_ALIAS: group1=user1,user2;group2=user1,user2,user3 [...]
#   HUBOT_GROUP_ALIAS_NAME_PROP: A property on the user object for @metions
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

  user_prop = process.env.HUBOT_GROUP_ALIAS_NAME_PROP

  # Replace aliases with @mentions in the message
  expand = (message, user) ->
    filterName = user.mention_name || user[user_prop]
    for own alias, members of groups
      # Filter inviduals from their own messages.
      if filterName
        members = members.replace('@' + filterName, '')
      reg = new RegExp('[:(]+' + alias + '[:)]+|@' + alias, 'i')
      message = message.replace(reg, members)
    return message

  # Compile RegEx to match only the aliases
  # Note this matches (alias) :alias: and @alias
  aliases = _.keys(groups).join('|')
  # The last group is a set of stop conditions (word boundaries or end of line)
  atRE = '(?:@(' + aliases + ')(?:\\b[^.]|$))'
  emojiRE = '(?:[(:])(' + aliases + ')(?:[:)])'
  regex = new RegExp(atRE + '|' + emojiRE, 'i')
  robot.hear regex, (msg) ->
    msg.send expand(msg.message.text, msg.message.user)