Kubernetes Cookiecutter
=======================

A reusable template for creating new Kubernetes projects.

[![Author](http://img.shields.io/badge/author-@superbalist-blue.svg?style=flat-square)](https://twitter.com/superbalist)
[![Build Status](https://img.shields.io/travis/Superbalist/cookiecutter-kubernetes-base/master.svg?style=flat-square)](https://travis-ci.org/Superbalist/cookiecutter-kubernetes-base)
[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)](LICENSE)

Requirements
------------

#### CookieCutter

Install `cookiecutter` command line: `pip install cookiecutter`

#### Additional Requirements

The following requirements can be installed by running `./scripts/bootstrap.sh` from your new project's path

* Homebrew (OSX)
* Python 3 + pip
* Git
* Docker
* Minikube
* Google Cloud SDK
* Kubectl
* Jinja2 CLI
* PyYAML
* Hostess


Usage
-----
Generate a new Cookiecutter template layout: `cookiecutter gh:superbalist/cookiecutter-kubernetes-base` 

Once your project is generated, the following commands are made available to you via a Makefile in the project directory:

* `make minikube` - Starts up minikube and creates an NFS mount (`/Users` on OSX, `/home` on Linux)
* `make up` - Deploys your project to minikube
* `make clean` - Deletes your project deployment & service and removes any data associated with it in minikube
* `make reset` - Runs `make clean` followed by `make up`
* `make test` - Runs tests on the project in minikube
* `make list` - Lists resources currently deployed for the project in minikube
* `make migrate` - Runs migrations for the project in minikube

Resources created by project
----------------------------

The following resources will be created by your project:

* A deployment named `<project_k8s_label>-app`
* A service named `<project_k8s_label>-app`
* A pod named `<project_k8s_label>-app`
* A pod named `<project_k8s_label>-migration`
* A pod named `<project_k8s_label>-tests`

Input
-----

When generating the project you are prompted for input.  Below are the fields and how they are used:

* Project name - Human-friendly name for your project, used in the Dockerfile schema name label
* Project slug - Machine-friendly name for your project, used as directory name
* Project K8s Label - Used to identify the project in Kubernetes
* Project description - Used in the Dockerfile schema description label
* Slackbot Webhook URL - Used for sending messages to Slack on deploy to production/staging
* Google Project ID Production - Used when deploying your project to Google Cloud production environment (ie Company-123)
* Google Project Zone Production - Used when deploying your project to Google Cloud production environment (ie europe-west1-b)
* Slack Notification Channel Prod - Used for sending messages to Slack on deploy to production
* Google Project ID Staging - Used when deploying your project to Google Cloud staging environment  (ie Company-uat-123)
* Google Project Zone Staging - Used when deploying your project to Google Cloud staging environment  (ie europe-west1-d)
* Slack Notification Channel Staging - Used for sending messages to Slack on deploy to staging
* Google Container Registry - Registry to use for images (ie eu.gcr.io)
* Vendor - Used in the Dockerfile schema vendor label
* Base Image - The image to use for your Dockerfile


License
-------
This project is licensed under the terms of the [MIT License](/LICENSE)
