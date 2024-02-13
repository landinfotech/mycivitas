---
title: MY_CIVITAS
summary: MyCivitas is a cost-effective and user-friendly asset management platform designed specifically for small communities. This comprehensive solution offers an all-inclusive and easy-to-use platform, empowering users to efficiently record and manage their assets within a powerful information system. With MyCivitas, communities can streamline their asset management processes, ensuring a seamless and effective approach to organising and overseeing their valuable resources.
    - Jeremy Prior
    - Ketan Bamniya
date: 01-02-2024
some_url: https://github.com/landinfotech/mycivitas
copyright: Copyright 2024, LandInfoTech
contact: support@civitas.ca
license: This program is free software; you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
---

# Contributing to MyCivitas

First off, thanks for taking the time to contribute! 🎉 😘 ✨

The following is a set of guidelines for contributing to this project.
These are mostly guidelines, not rules. Use your best judgment, and
feel free to propose changes to this document in a pull request.

## Reporting bugs

Bugs are tracked as GitHub issues. Search the list and try reproduce on your
local machine with a clean profile before you create an issue.
When you create an issue, please provide the following information by filling
in the template.

Explain the problem and include additional details to help maintainers reproduce the problem:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details
  as possible. Don't just say what you did, but explain how you did it. For
  example, if you moved the cursor to the end of a line, explain if you used a
  mouse or a keyboard.
* **Provide specific examples to demonstrate the steps.** Include links to
  files or GitHub projects, or copy/paste-able snippets, which you use in those
  examples. If you're providing snippets on the issue, use Markdown code blocks.
* **Describe the behaviour you observed after following the steps** and point
  out what exactly is the problem with that behaviour.
* **Explain which behaviour you expected to see instead and why.**
* **Include screenshots and animated GIFs** which show you following the
  described steps and clearly demonstrate the problem.

## Suggesting enhancements

In case you want to suggest an enhancement, please follow this guideline to
help maintainers and the community understand your suggestion.
Before creating suggestions, please check the [issue
list](https://github.com/landinfotech/mycivitas/issues) if
there's already a request.

Create an issue and provide the following information:

* **Use a clear and descriptive title** for the issue to identify the
  suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as
  many details as possible.
* **Provide specific examples to demonstrate the steps.** Include
  copy/paste-able snippets which you use in those examples, as Markdown code
  blocks.
* **Include screenshots and animated GIFs** which helps demonstrate the steps
  or point out the part of a project which the suggestion is related to.
* **Explain why this enhancement would be useful** to most users.
* **List some other text editors or applications where this enhancement
  exists.**

## First code contribution

Unsure where to begin contributing? You can start by looking
through these `document`, `good first issue` and `help wanted` issues:

* **document issues**: issues that should be reviewed or improved.
* **good first issues**: issues which should only require a few lines of code,
  and a test or two.
* **help wanted issues**: issues which should be a bit more involved than
  beginner issues.

## Pull requests

### Development workflow

* Set up your development environment
* Make change from the right branch
* Be sure the code passes tests
* Make a pull request

### Development environment

* Prepare your machine and its packages installed.
* Checkout our repository
* Follow README.md instructions to install dependencies

### Make changes

#### Checkout a branch

* **master**: PR Base branch.
* **production**: latest release branch with distribution files. Never make a PR on this.
* **gh-pages**: API docs, examples and demo

#### Check code style

Run the pylance extension and make sure all the tests pass.

#### Test

Run `TODO` and verify all the tests pass.
If you are adding new commands or features, they must include tests.
If you are changing functionality, update the tests if you need to.

#### Commit

Follow our [commit message conventions](../developer/guide/templates/commit-message-convention.md).

### Yes! Pull request

Make your pull request, then describe your changes.

#### Title

Follow other PR title formats below.

```
    <Type>: Short Description (fix #111)
    <Type>: Short Description (fix #123, #111, #122)
    <Type>: Short Description (ref #111)
```

* capitalize the first letter of the Type
* use present tense: 'change' not 'changed' or 'changes'

#### Description

If it has related issues, add links to the issues(like `#123`) in the description.
Fill in the [Pull Request Template](../developer/guide/templates/pull-request-template.md) by checking your case.

## Code of conduct

This project and everyone participating in it is governed by the [Code of
Conduct](code-of-conduct.md). By participating, you are expected to uphold this
code. Please report unacceptable behaviour to tim@kartoza.com.

> This guide is based on [atom contributing
guide](https://github.com/atom/atom/blob/master/CONTRIBUTING.md),
[CocoaPods](http://guides.cocoapods.org/contributing/contribute-to-cocoapods.html)
and [ESLint](http://eslint.org/docs/developer-guide/contributing/pull-requests)
