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

config = process.env.HUBOT_GROUP_ALIAS
user_prop = process.env.HUBOT_GROUP_ALIAS_NAME_PROP || ''
useDynamicGroups = config == 'DYNAMIC'
groupCache = {}

buildGroupObject = () ->
  if !_.isEqual(groupCache, {})
    return groupCache
  staticGroups = config.split(';')
  # Create 2D list of [alias, users]
  staticGroups = _.map(staticGroups, (val, item, array) -> val.split('='))
  # expand "user1,user2" to "@user1 @user2"
  staticGroups = _.map(staticGroups, (val, item, array) -> [val[0],
    '@' + val[1].split(',').join(' @')])
  # Convert 2D list to native object
  groupCache = _.object(staticGroups)
  return groupCache

getGroups = (match) ->
  if useDynamicGroups
    return ''
  else
    return buildGroupObject()


# Replace aliases with @mentions in the message
expand = (message, user) ->
  # mention_name is for Hipchat
  filterName = user[user_prop] || user.mention_name || user.name
  groups = getGroups(message.match)
  for own alias, members of groups
    # Filter inviduals from their own messages.
    if filterName
      members = members.replace('@' + filterName, '')
    reg = new RegExp('[:(]+' + alias + '[:)]+|@' + alias, 'i')
    message = message.replace(reg, members)
  return message

buildRegExp = () ->
  if useDynamicGroups
    aliases = '\\w+'
  else
    # Compile RegEx to match only the aliases
    # Note this matches (alias) :alias: and @alias
    aliases = _.keys(buildGroupObject()).join('|')
  # The last group is a set of stop conditions (word boundaries or end of line)
  atRE = '(?:@(' + aliases + ')(?:\\b[^.]|$))'
  emojiRE = '(?:[(:])(' + aliases + ')(?:[:)])'

  return new RegExp(atRE + '|' + emojiRE, 'i')

module.exports = (robot) ->
  if !config
    robot.logger.warning "Configuration HUBOT_GROUP_ALIAS is not defined."
    return

  regex = buildRegExp()
  robot.hear regex, (msg) ->
    msg.send expand(msg.message.text, msg.message.user)