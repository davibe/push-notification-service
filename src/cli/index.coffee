amqp = require 'amqp-as-promised'
genrun = require 'q-genrun'
yargs = require 'yargs'

conf =
  connection:
    url: process.env.RABBITMQ_URL or "amqp://localhost:5672//?heartbeat=10"
  logLevel: 'warn'

amqpc = amqp(conf)


pushService = (method, args...) -> genrun ->
  yield amqpc.rpc('myexchange', "push-notification-service.#{method}", args)


add = ({username, userid, type, token}) -> genrun ->
  body =
    token:
      type: type
      value: token
    user:
      id: userid
      username: username
  console.log yield pushService('createOrUpdate', body, false)


del = ({token}) -> genrun ->
  console.log yield pushService('deleteById', token, null)


list = ({userId}) -> genrun ->
  res = yield pushService('findByUserId', userId)
  console.log JSON.stringify(res, null, 2)
  res


send = ({type, token, badge, message}) -> genrun ->
  note =
    tokens: if token then [token] else []
    type: type
    notification:
      badge: badge
      alert: message
  console.log 'Sending notification', note
  response = yield pushService('send', note)
  console.log response
  response


sendWithUsername = ({username, badge, message}) -> genrun ->
  tokens = yield pushService('findByUsername', username)
  for item in tokens
    token = item.token.value
    type = item.token.type
    yield send({token, type, badge, message})


listWithUsername = ({username}) -> genrun ->
  res = yield pushService('findByUsername', username)
  console.log JSON.stringify(res, null, 2)
  res


if not module.parent then genrun ->

  try
    argv = yargs
      .usage("Usage: $0 <command> [options]")

      .command('add <username> <userid> <type> <token>', 'add one device token')
      .command('list <userId>', 'list token of a user identified by id')
      .command('del <token>', 'delete one device token')
      .command('send <type> <token> <badge> <message>', 'send notification to one device token')

      .command('list-with-username <username>', 'list token of a user identified by username')
      .command('send-with-username <username> <badge> <message>', 'send notification to one user')

      .demand(1)
      .help()
      .wrap(null)
      .argv

    if argv._[0] is 'add' then yield add(argv)
    if argv._[0] is 'list' then yield list(argv)
    if argv._[0] is 'del' then yield del(argv)
    if argv._[0] is 'send' then yield send(argv)

    if argv._[0] is 'send-with-username' then yield sendWithUsername(argv)
    if argv._[0] is 'list-with-username' then yield listWithUsername(argv)


  catch error
    console.log error, error.stack.split('\n') if error.stack

  yield amqpc.shutdown()
  process.exit()
