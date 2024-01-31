---
title: PROJECT_TITLE
summary: PROJECT_SUMMARY
    - PERSON_1
    - PERSON_2
date: DATE
some_url: PROJECT_GITHUB_URL
copyright: Copyright 2023, PROJECT_OWNER
contact: PROJECT_CONTACT
license: This program is free software; you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
#context_id: 1234
---

# Checking out the code

This section outlines the process of checking out the code for local development.

🚩 Make sure you have gone through the [Prerequisites Section](prerequisites.md) before following these notes.

Git Code check out [PROJECT_URL] <!-- Change this per project -->

```
git clone https://github.com/project-name/repository.git
```
<!-- Change this to project repository -->

📒**Which branch to use?**: Note that we deploy our staging work from the `develop` branch and our production environment from the `main` branch. If you are planning on contributing improvements to the project, please submit them against the `develop` branch.

🪧 Now that you have the code checked out, move on to the [IDE Setup](ide-setup.md) documentation.
