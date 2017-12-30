Bunch of scripts I use to accomplish random tasks at work and for fun

Read in other languages: [:us:](README.md) [:ru:](README-ru.md) [:it:](README-it.md) [Hebrew](README-he.md) 

### Discalimers

Use at your risk - this is after all *tools* to help *me* accomplish *my* tasks with reasonable quality and developed in reasonable time ==>
* backup input files before using scripts
* portability might be an issue, this works on my MAC with this bash:
```
$ bash --version
GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin16)
Copyright (C) 2007 Free Software Foundation, Inc.
```

### Repo Structure and Tests
```
  |-test
  |  |-process_aws_sns_emails_batch
  |  |  |-expected_outputs
  |  |  |-inputs
```
Scripts are located in root dir, `test` has a directory for every script. By inspecting contents `inputs` and `expected_outputs` you can get an idea what the script does and what input does it expect

To run tests:
```
./RUN_SUITE.sh
```

### process_aws_sns_emails_batch.sh

Parse GMAIL threads from AWS SNS to create big sample pool of SNS messages for quick development of a POC module before creating an http endpoint in AWS

* when a company policy/iam doesn't allow connecting to prod/stage SNS with an http endpoint for development of a POC
* quick development - you already have large sample of real SNS messages that you can test you POC on, rather than waiting for the prod SNS in real time and monitoring logs to see if an unexpected format message payload has been received

Open GMail thread with SNS notifications (they are capped at 100 by GMail, but the script will work with any number)
Click "Print All"
In the next window close the print pop-up and copy all the contents of the page into input file(s)

Sometimes copied text is corrupted (I blame it on vim), and some jsons produced are not valid.
JSON messages that could not be processed are saved separately. Also the log file is available, all necessary data is displayed on screen in the end.
I had 2% of corrupted messages (the input pasted from GMail) on more than 1500 messages
