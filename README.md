# Hubot Group Alias

Group Alias is a simple [Hubot][hubot] package which allows you to define new **"@mentions"** which are automatically expanded. For example, you could define `@dev`, `@design` to send a message to all members of your teams. Using `hubot-auth`, you can also dynamically define groups!

## Setup
1. All this package to your `package.json`. Do this by running this command:

	```sh
	npm install --save hubot-group-alias
	```
2. Add "hubot-group-alias" to `external-scripts.json`:

	```json
	[
	"...",
	"hubot-group-alias",
	"..."
	]
	```
3. Set the `HUBOT_GROUP_ALIAS` variable.

		heroku config:add HUBOT_GROUP_ALIAS=...
	
	* (Read below for configuration instructions.)
4. _Optional_: set `HUBOT_GROUP_ALIAS_NAME_PROP`
	* This is the property of the `User` object that contains the short or @ name for each user. The problem is this field is non-standard and defined by each user.
	* This field is likely __required__ if you want sender's usernames to be filtered from the messages sent, or you're using `hubot-auth`. This is because both those features rely on matching this property for expanding the message.
	* This property first checks `User.mention_name` then `User.name`
	* Here are some examples:
		* HipChat: `HUBOT_GROUP_ALIAS_NAME_PROP="mention_name"`
			* See the [HipChat adapter source][hc-source] to find `mention_name`
		* Slack: I [_think_][slack-source] this should be just `User.name`, but I'm not sure, because I don't use Slack.

[hc-source]: https://github.com/hipchat/hubot-hipchat/blob/c2846981dd533860352187c7369e4feb792a9062/src/connector.coffee#L411
[slack-source]: https://github.com/slackhq/hubot-slack/blob/master/src/slack.coffee#L180

###   `HUBOT_GROUP_ALIAS` Format
The format for configuration is easy:

    alias1=user1,user2;alias2=user1

That is:

* Separate different aliases by `;`.
* Define an alias with `=`.
* Separate users by `,`.
* Users (and aliases) should __not__ have `@`.
* Aliases are case *insensitive*.

**Note**: *When set in a shell environment, you may want to put `''` around your alias definition so that any `;` don't try to break the command.*

### Dynamic Configuration
Group Alias supports dynamically defining groups using the [hubot-auth][auth] package. All "roles" that are created by `hubot-auth` will be treated able to be expanded into @mention messages. To do this, simple set:

	HUBOT_GROUP_ALIAS='DYNAMIC'

and make sure `hubot-auth` is installed.

##### Notes
* The only supported modes are dynamic or pre-defined. There is currently no "hybrid" mode. (I would welcome a PR if anyone wants this!)
* Currently dynamic mode is _not_ case sensitive because `hubot-auth` roles act the same way.
* You should probably set `HUBOT_GROUP_ALIAS_NAME_PROP` because otherwise, `hubot-auth` may use a different User name from the @ name. (Please see the section above for more details)

[auth]: https://github.com/hubot-scripts/hubot-auth

## Autocomplete Abilities
By default, most chat apps don't support autocomplete for bots. :(

However, Group Alias includes the ability to use custom emoji in order to allow apps autocomplete. This should work with most chat clients, though please file an issue if there is a different emoji syntax I've missed. To use this feature, all you need to do is add the emoji to your particular chatroom, with the same name as the alias.

The script matches the following forms of the alias `dev`:

* @dev
* (dev)
* :dev:
* ::dev::

## Usage
For example:

If you set the configuration as:  `dev=Alice,Bob,Eve`

And the message sent is:

`PO> Hey @dev, there's a standup in 5 min.`

Then this message will be sent by Hubot:

`Hubot> Hey @Alice @Bob @Eve, there's a standup in 5 min.`

**Note** that as of version _1.6.0_ users' names are filtered from the messages they send.

In the above example, the following would happen if @Alice sent a message:
```
Alice> Hey @dev, there's a standup in 5 min.`
Hubot> Hey @Bob @Eve, there's a standup in 5 min.`
```

[hubot]: https://github.com/github/hubot/
