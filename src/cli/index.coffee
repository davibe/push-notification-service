yargs = require 'yargs'

if not module.parent
  argv = yargs
    .usage("Usage: $0 <command> [options]")

    .command(require('./cmds/add'))
    .command(require('./cmds/list'))
    .command(require('./cmds/del'))
    .command(require('./cmds/send'))
    .command(require('./cmds/list-with-username'))
    .command(require('./cmds/send-with-username'))

    .demand(1)
    .help()
    .wrap(null)
    .argv
