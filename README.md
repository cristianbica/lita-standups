# lita-standups

[![Build Status](https://travis-ci.org/cristianbica/lita-standups.png?branch=master)](https://travis-ci.org/cristianbica/lita-standups)
[![Coverage Status](https://coveralls.io/repos/github/cristianbica/lita-standups/badge.svg?branch=master)](https://coveralls.io/github/cristianbica/lita-standups?branch=master)


lita-standups is a [Lita](http://lita.io) plugin which allows you to run standups with your team.

## Installation

Add lita-standups to your Lita instance's Gemfile:

``` ruby
gem "lita-standups"
```

## Usage

```
list standups - list configured standups
create standup - create a standup
show standup STANDUP_ID - shows details of a standup
delete standup STANDUP_ID - deletes a standup
schedule standup STANDUP_ID - schedule a standup
unschedule standup SCHEDULE_ID - unschedule a standup
list standups schedules - shows scheduled standups
show standup schedule SCHEDULE_ID - shows a scheduled standup
run standup STANDUP_ID with USERS - runs a standup now (users space/eparated)
list standup sessions - list all standups sessions
show standup session SESSION_ID - show a standups session details
```

## Contributing

1. Fork it ( https://github.com/cristianbica/lita-standups/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


