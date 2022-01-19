/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS203: Remove `|| {}` from converted for-own loops
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Description:
//   Define user aliases to @mention groups of people at once.
//
// Dependencies:
//   hubot-auth - for dynamically configured grouos
//
// Configuration:
//   HUBOT_GROUP_ALIAS: DYNAMIC (or) group1=user1,user2;group2=user1,user2 [...]
//   HUBOT_GROUP_ALIAS_NAME_PROP: A property on the user object for @metions
//
// Commands:
//   hubot list group aliases - give the names of the alias groups.
//
// Notes:
//   Use @group_name in your message and your robot will pass it along to
//      each user in the group
//
// Author:
//   Michael Ball @cycomachead

const _ = require('lodash');

const config = process.env.HUBOT_GROUP_ALIAS;
const user_prop = process.env.HUBOT_GROUP_ALIAS_NAME_PROP || '';
const useDynamicGroups = config === 'DYNAMIC';
let groupCache = {};

const buildGroupObject = function() {
  if (!_.isEqual(groupCache, {})) {
    return groupCache;
  }
  // Create a 1D list of group assignments
  let staticGroups = _.without(config.split(';'), '');
  // Create 2D list of [alias, users]
  staticGroups = _.map(staticGroups, (val, item, array) => val.split('='));
  // expand "user1,user2" to "@user1 @user2"
  staticGroups = _.map(staticGroups, (val, item, array) => [val[0],
    '@' + val[1].replace(/,/g, ' @')]);
  // Convert 2D list to native object
  groupCache = _.object(staticGroups);
  return groupCache;
};

// Return Groups Mentioned in a message if there is a dynamic group.
const getGroups = function(robot, text) {
  if (useDynamicGroups) {
    let group;
    const groupMap = {};
    const regex = /[:(]+(\w+)[:)]+|@(\w+)/gi;
    let matches = regex.exec(text);
    while (matches !== null) {
      // If matched, 1 group will always be `undefined`
      group = matches[1] || matches[2];
      const users = robot.auth.usersWithRole(group);
      if (!_.isEqual(users, [])) {
        groupMap[group] = users;
      }
      matches = regex.exec(text);
    }
    for (group of Object.keys(groupMap || {})) {
      const members = groupMap[group];
      let list = _.map(members, userFromName(robot));
      list = _.map(list, mentionName);
      groupMap[group] = listToMentions(list);
    }
    return groupMap;
  } else {
    return buildGroupObject();
  }
};

const getGroupsList = function(robot) {
  if (useDynamicGroups) {
    let groups = [];
    const {
      users
    } = robot.brain.data;
    for (let id of Object.keys(users || {})) {
      const user = users[id];
      const roles = robot.auth.userRoles(user);
      groups = groups.concat(roles);
    }
    return _.uniq(groups);
  } else {
    return Object.keys(buildGroupObject());
  }
};

// Returns a function that lets this be used inside _.map
// TODO: This closure isn't totally necessary... bleh.
var userFromName = robot => (function(name) {
  const allUsers = robot.brain.data.users;
  for (let id of Object.keys(allUsers || {})) {
    const user = allUsers[id];
    if (user.name === name) {
      return user;
    }
  }
  return {};
});

var mentionName = user => // mention_name is for Hipchat
user[user_prop] || user.mention_name || user.name;

var listToMentions = list => '@' + list.join(' @');

// Replace aliases with @mentions in the message
const expand = function(message, groups, user) {
  const filterName = mentionName(user);
  for (let alias of Object.keys(groups || {})) {
    // Filter inviduals from their own messages.
    let members = groups[alias];
    if (filterName) {
      members = members.replace('@' + filterName, '').replace(/\s+/g, ' ');
    }
    const reg = new RegExp('[:(]+' + alias + '[:)]+|@' + alias, 'i');
    message = message.replace(reg, members);
  }
  return message;
};

// Note this matches (alias) :alias: and @alias
const buildRegExp = function() {
  let aliases;
  if (useDynamicGroups) {
    aliases = '\\w+';
  } else { // match only defined aliases
    aliases = _.keys(buildGroupObject()).join('|');
  }
  // The last group is a set of stop conditions (word boundaries or end of line)
  const atRE = '(?:@(' + aliases + ')(?:\\b[^.]|$))';
  const emojiRE = '(?:[(:])(' + aliases + ')(?:[:)])';
  return new RegExp(atRE + '|' + emojiRE, 'i');
};

module.exports = function(robot) {
  if (!config) {
    robot.logger.warning("Configuration HUBOT_GROUP_ALIAS is not defined.");
    return;
  }

  if (useDynamicGroups && !robot.auth) {
    robot.logger.warning("Using dynamic groups requires hubot-auth to be loaded");
    return;
  }

  robot.respond(/list groups?( alias(es)?)?/i, function(resp) {
    const groups = listToMentions(getGroupsList(robot));
    return resp.send(`The currently setup groups are: ${groups}`);
  });

  const regex = buildRegExp();
  return robot.hear(regex, function(resp) {
    const groups = getGroups(robot, resp.message.text);
    if (!_.isEqual(groups, {})) { // don't send message if no groups found.
      return resp.send(expand(resp.message.text, groups, resp.message.user));
    }
  });
};
