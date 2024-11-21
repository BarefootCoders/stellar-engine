<!-- BEGIN TOC -->
- [Notes](#notes)
- [Variables](#variables)
<!-- END TOC -->

# Prerequisites
1. A project with App Engine configured (see App Engine blueprint)
1. Enable Datastore API
1. Modify index.yaml per your datastore requirements

# Notes
1. This module leverages local execs and should be carefully monitored.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L1) | The ID of your project. This project must contain an app engine instance. | <code>string</code> | ✓ |  |
| [region](variables.tf#L6) | The region of your project. | <code>string</code> | ✓ |  |
<!-- END TFDOC -->
