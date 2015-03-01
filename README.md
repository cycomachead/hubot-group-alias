# Hubot Group Alias

Group Alias is a simple script which allows you to define new `@mentions` which are expanded. For example, you could define `@dev`, `@design` to send to all members of your teams.

## Configuration
1. All this package to your `package.json`. Do this by running this command:
```sh
npm i --save hubot-group-alias
```

2. Add "hubot-group-alias" to `external-scripts.json`:
```json
[
...
"hubot-group-alias",
...
]
```
3. Set the `HUBOT_GROUP_ALIAS` variable.

        heroku config:add HUBOT_GROUP_ALIAS=...

###   `HUBOUT_GROUP_ALIAS` Format
The format for configuration is easy:

    alias1=user1,user2;alias2=user1

That is:

* Separate different aliases by `;`.
* Define an alias with `=`.
* Separate users by `,`.
* Users (and aliases) should __not__ have `@`.
* Aliases are case *insensitive*.

*Note that when set in a shell environment, you may want to put `''` around your alias definition so that any `;` don't try to break the command.*

## Autocomplete Abilities
By default, most chat apps don't support autocomplete for bots. :(
However, Hubot Group Alias includes the ability to use custom emoji in order to allow apps autocomplete. This should work with most chat clients, though please file an issue if there is a different emoji syntax I've missed. To use this feature, all you need to do is add the emoji to your particular chatroom, with the same name as the alias. 
The script matches the following forms of the alias `dev`:

* @dev
* (dev)
* :dev:
* ::dev:: is coming soon!

