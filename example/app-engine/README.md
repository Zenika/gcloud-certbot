# Deploy example

To deploy the app, make sure to login with the gcloud command and set your example project id

```bash
$ gcloud auth login
$ gcloud config set project <project-id>
```

Then, deploy the first default version of the app:

```bash
gcloud app publish . cat dog
```

For a more meaningfull example, you should create some other versions.
This will allow you to check that the routing and the wildcard certificate are working as expected.

For this, change the images (`cat/cat.png` and `dog/dog.jpg`) and deploy some new versions:

```bash
gcloud app deploy . cat dog --version dev --no-stop-previous-version --no-promote
gcloud app deploy . cat dog --version pr-1234 --no-stop-previous-version --no-promote
```

This simulate a `dev` version a deployed feature branch for PR 1234
