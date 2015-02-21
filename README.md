# Hubot Group Alias

Group Alias is a simple script which allows you to define new `@mentions` which are expanded. For example, you could define `@dev`, `@design` to send to all members of your teams.

## Configuration
1. All this package to your `package.json`. Do this by placing
```
"hubot-group-alias": "hubot-scripts/hubot-group-alias"
```
in your dependencies section.
or run:
```
npm i --save hubot-group-alias
```

2. Add "hubot-group-alias" to `external-scripts.json`
3. Set the `HUBOT_GROUP_ALIAS` variable.

        heroku config:add HUBOT_GROUP_ALIAS`=...

####   `HUBOUT_GROUP_ALIAS`
The format for configuration is easy:

    alias1=user1,user2;alias2=user1

That is:

* Separate different aliases by `;`.
* Define an alias with `=`.
* Separate users by `,`.
* Users (and aliases) should __not__ have `@`.
* Aliases are case insensitive.
