
### Using

```bash
$ ./deploy
Usage: deploy <HOST> <SERVICE> [VERSION]
Where:
  HOST: zain-sa-m3 zain-sa-pp zain-sa-stg zain-kw-stg zain-kw-pp batelco-stg
  SERVICE: funnel just
  VERSION: by default from config file
```

NOTE: you have to define SUS_USERNAME & SUS_PASSWORD environment virables, for example:

```bash
SUS_USERNAME=<name> SUS_PASSWORD=<pass> ./deploy zain-sa-stg just
```