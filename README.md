
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
```