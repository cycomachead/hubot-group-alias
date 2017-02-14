# Description:
#   Define user aliases to @mention groups of people at once.
#
# Dependencies:
#   hubot-auth - for dynamically configured grouos
#
# Configuration:
#   HUBOT_GROUP_ALIAS: DYNAMIC (or) group1=user1,user2;group2=user1,user2 [...]
#   HUBOT_GROUP_ALIAS_NAME_PROP: A property on the user object for @metions
#
# Commands:
#   hubot list group aliases - give the names of the alias groups.
#
# Notes:
#   Use @group_name in your message and your robot will pass it along to
#      each user in the group
#
# Author:
#   Michael Ball @cycomachead

_ = require('lodash')

config = process.env.HUBOT_GROUP_ALIAS
user_prop = process.env.HUBOT_GROUP_ALIAS_NAME_PROP || ''
useDynamicGroups = config == 'DYNAMIC'
groupCache = {}

buildGroupObject = ->
  if !_.isEqual(groupCache, {})
    return groupCache
  # Create a 1D list of group assignments
  staticGroups = _.without(config.split(';'), '')
  # Create 2D list of [alias, users]
  staticGroups = _.map(staticGroups, (val, item, array) -> val.split('='))
  # expand "user1,user2" to "@user1 @user2"
  staticGroups = _.map(staticGroups, (val, item, array) -> [val[0],
    '@' + val[1].replace(/,/g, ' @')])
  # Convert 2D list to native object
  groupCache = _.object(staticGroups)
  return groupCache

# Return Groups Mentioned in a message if there is a dynamic group.
getGroups = (robot, text) ->
  if useDynamicGroups
    groupMap = {}
    regex = /[:(]+(\w+)[:)]+|@(\w+)/gi
    matches = regex.exec(text)
    while matches != null
      # If matched, 1 group will always be `undefined`
      group = matches[1] || matches[2]
      users = robot.auth.usersWithRole(group)
      if !_.isEqual(users, [])
        groupMap[group] = users
      matches = regex.exec(text)
    for own group, members of groupMap
      list = _.map(members, userFromName(robot))
      list = _.map(list, mentionName)
      groupMap[group] = listToMentions(list)
    return groupMap
  else
    return buildGroupObject()

getGroupsList = (robot) ->
  if useDynamicGroups
    groups = []
    users = robot.brain.data.users
    for own id, user of users
      roles = robot.auth.userRoles(user)
      groups = groups.concat(roles)
    return _.uniq(groups)
  else
    return Object.keys(buildGroupObject())

# Returns a function that lets this be used inside _.map
# TODO: This closure isn't totally necessary... bleh.
userFromName = (robot) ->
  return (name) ->
    allUsers = robot.brain.data.users
    for own id, user of allUsers
      if user.name == name
        return user
    return {}

mentionName = (user) ->
  # mention_name is for Hipchat
  return user[user_prop] || user.mention_name || user.name

listToMentions = (list) ->
  return '@' + list.join(' @')

# Replace aliases with @mentions in the message
expand = (message, groups, user) ->
  filterName = mentionName(user)
  for own alias, members of groups
    # Filter inviduals from their own messages.
    if filterName
      members = members.replace('@' + filterName, '').replace(/\s+/g, ' ')
    reg = new RegExp('[:(]+' + alias + '[:)]+|@' + alias, 'i')
    message = message.replace(reg, members)
  return message

# Note this matches (alias) :alias: and @alias
buildRegExp = ->
  if useDynamicGroups
    aliases = '\\w+'
  else # match only defined aliases
    aliases = _.keys(buildGroupObject()).join('|')
  # The last group is a set of stop conditions (word boundaries or end of line)
  atRE = '(?:@(' + aliases + ')(?:\\b[^.]|$))'
  emojiRE = '(?:[(:])(' + aliases + ')(?:[:)])'
  return new RegExp(atRE + '|' + emojiRE, 'i')

module.exports = (robot) ->
  if !config
    robot.logger.warning "Configuration HUBOT_GROUP_ALIAS is not defined."
    return

  if useDynamicGroups && !robot.auth
    robot.logger.warning "Using dynamic groups requires hubot-auth to be loaded"
    return

  robot.respond /list groups?( alias(es)?)?/i, (resp) ->
    groups = listToMentions(getGroupsList(robot))
    resp.send "The currently setup groups are: #{groups}"

  regex = buildRegExp()
  robot.hear regex, (resp) ->
    groups = getGroups(robot, resp.message.text)
    if !_.isEqual(groups, {}) # don't send message if no groups found.
      resp.send expand(resp.message.text, groups, resp.message.user)
