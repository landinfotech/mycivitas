---
title: GeoSight-OS Documentation Home 
summary: GeoSight is UNICEF's geospatial web-based business intelligence platform.
    - Tim Sutton
    - Irwan Fathurrahman
date: 2023-08-03
some_url: https://github.com/unicef-drp/GeoSight-OS
copyright: Copyright 2023, Unicef
contact: geosight-no-reply@unicef.org
license: This program is free software; you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
#context_id: 1234
---

# Documentation Overview

This document describes the easiest workflow for editing documentation.

Requirements:

1. You need to have a GitHub account and be logged in to your account
2. You need to have been given access to the repo by the repo manager

## General Workflow

1. Go to the repo for the documentation.
2. Press the ``.`` key on your keyboard.
3. Select a file under the src folder to edit
4. Press Ctrl-S to save your work.
5. Go to the Source Control tab to commit your work. 
6. Add a short, descriptive comment describing your changes.
7. Press the ``Commit and push`` button.
8. Wait a few minutes and your changes should be published live.

## Adding a new page

Any new page you create needs to be also added to ```mkdocs-base.yml``` so that it gets 'built.
If you wish to build a page but not have it in the menu system, you can give it a blank menu description e.g.

```
# Pages to render but exclude from navigation
- "": developer/guide/templates/pull-request-template.md 
```

Conversely, to ensure it is shown in the menu, find the right place in the navigation tree and then insert it with a short descriptor. e.g.

```
# Pages to render and include from navigation
- "My Menu Item": developer/guide/my-page.md 
```

## Adding images

You can easily upload images into the documentation sources and then add them to your document.

1. Take an image using your favourite screenshot tool.
2. Using your file manager, drag the file from your desktop into the img folder in the relevant part of the documentation you are working on.
3. ``Shift+Drag`` the image into your markdown document.
4. Edit the image description (the part in square brackets)


## Adding links

You can add a link to any text by doing the following:

1. Copy the link from your web browser to your clipboard.
2. Either
  2.1 Past the link directly into the document sources.
  2.2 or, write some words ine square brackets and paste the link in round brackets after, VSCode will create a markdown formatted link.

This is a normal link https://staging-geosight.unitst.org/, [this is a link](https://staging-geosight.unitst.org/).

The above in markdown:

```
This is a normal link https://staging-geosight.unitst.org/, [this is a link](https://staging-geosight.unitst.org/).

```

## Page previews

You can easily preview the page you are working on by doing this:

1. Press ``Ctl-Shift-V`` to open a preview of the page you are currently working in.
2. Drag and drop the preview tab to the right side of the editing environment for a side-by-side view.

## Leaving the editor viewer

How to leave the interactive editor.

1. Click the 'hamburger' menu and go to the repository.
2. Wait a few moments and the 'normal' GitHub page will load.