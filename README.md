
### Using

#### Clone scripts

```bash
git clone https://github.com/AntonSizov/eng-deploy-pmm.git && cd eng-deploy-pmm
```

#### Edit version

Find necessary vars file in `group_vars` directory and edit it with service version
you need.

#### Credentials

Use inline credentials

```bash
SUS_USERNAME=<name> SUS_PASSWORD=<pass> ./deploy <HOST> <SERVICE>
```

or `credentials` file

```bash
$ echo -e "SUS_USERNAME=<name>\nSUS_PASSWORD=<pass>" > credentials
```

#### Ask ssh password

If you did not setup ssh access using keys (but you have to) you can ask scripts to use
password.

```bash
echo "ASK_PASSWORD=-k" >> credentials
```

#### Run script

Deploy script on stg for example:

```bash
./deploy just zain-sa-stg
```

### Get help

```bash
$ ./deploy
Usage: [SUS_USERNAME=<name> SUS_PASSWORD=<pass>] ./deploy <HOST> <SERVICE> [VERSION]
Where:
  HOST: zain-sa-m3 zain-sa-pp zain-sa-stg zain-kw-stg zain-kw-pp batelco-stg
  SERVICE: funnel just
  VERSION: by default from config file

You can also provide credentials with 'credentials' file:
$ echo -e "SUS_USERNAME=<name>\nSUS_PASSWORD=<pass>" > credentials

You can also setup script to ask ssh password:
$ echo "ASK_PASSWORD=-k" >> credentials
```

### Deploy standalone J3 for performance tests

To start you need configure you public key within host you
need to provision.

Check ansible version is 1.9 or higher.
Just version should be 3.8.0-devel-1 or higher.

To test scripts you can (not should) use Vagrantfile provided.
Run `vagrant up && vagrant ssh` and you are in. Add you public key to
`.ssh/authorized_keys`, take port number from vagrant startup
log messages and you are ready.

Start provisioning standalone Just host:

```bash
./deploy <user>@<host>:<port> standalone_j3 3.8.0-devel-1
```

Start provisioning eng host (erlang, rabbitmq, smppload, smppsink, rmq_tool):

```bash
./deploy <user>@<host>:<port> eng ignore_version
```

#### Start RabbitMQ

From root user:

```bash
[root@localhost]# rabbitmq-server
```

#### Start Smppsink

From root user:

```bash
[root@localhost]# /opt/smppsink/bin/smppsink console
```

#### Start J3

From bms user:

```bash
[bms@localhost]$ /opt/just/bin/just console
```

#### smppload & rmq_tool

smppload & rmq_tool are in PATH, hence you are able to start it from any desired
directory.

Note that you should have write permissions for current directory
to make rmq_tool able to dump queues and make other disk operations.
