quick bash scripts
==================


Basically just a bunch of scripts I wrote to make my life easier


Usage without local copy of script is simple

```
bash <(curl -s https://url_to_raw_script) arg0 arg1 arg2
```

Example:
```
bash <(curl -s https://raw.githubusercontent.com/willtrking/quick_scripts/master/easy-ecs-push.sh) -c email-lander -s email-lander -f email-lander -r DUMMY_REPO_URL -t 1
``` 
