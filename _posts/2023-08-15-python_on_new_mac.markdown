---
layout: post
title:  "Install Python on New Mac"
date:   2023-08-15 15:36:21 +0300
categories: python
---



## Overview

So you just bought a new laptop, and going to configure it for the work (this is what I did recently), and you need a refresher on how to configure everything from scratch. Or, you’re dissatisfied with your current setup and want to look for a better configuration. Let’s look at my setup step by step!

At first, there is a long list of tools I’m using for work. I’m going to save you time and not show everything here. Some things are either trivial, or their installation is obvious and trouble-free. E.g. you need some IDE (I prefer Visual Studio Code) and a version control system (git is probably an unrivaled leader nowadays). Also, you often need to use Docker, thankfully it’s [easy to install][DockerMac].

But I’m not going to waste your time on obvious things. I’ll put here a quite specific toolset which, from my personal experience, fits the best for extensive Python development and will help you handle any task in the future. Also, this is just what I installed immediately on my new laptop to deploy the majority of my current projects. Other specific things could be (and, for sure, will be) installed later, but this is a basic layer.

Also for time economy, I’m not going to provide full step-by-step guides on installation of these tools, which you can just see in their documentation. Only some specific nuances, or troubles I encountered, will be highlighted.

## Terminal
First, you need to set up a convenient terminal of course!

I recommend abandoning standard MacOS iTerm and immediately installing [iTerm2][iterm2].

Then, instead of Bash, I prefer to use ZSH shell, with [Oh My ZSH][OhMyZsh] configurations and plugins. Quite a lot of [guides][zsh-guides] for this setup on the internet could be found. This shell supports [a lot][ohmzsh-plugins] of autocompletion plugins, my usual list (which is specified in ~/.zshrc) is the following:

```
...
plugins=(
  git
  docker
  docker-compose
  poetry
  pyenv
)
...
```


## Pyenv

Your different projects often require different versions of Python.

You can obtain a restricted list of versions from [Brew][brew], as well as download and install manually any release from the [official Python site][python]. But the real freedom of managing Python versions comes from using [pyenv][pyenv], a tool that installs/uninstalls any Python version with a single shell command.

Typical usage:

```bash
pyenv # list of all commands
pyenv versions # list all installed (available to use) python version
pyenv install -l | grep 3.9 # Here you can see all the options and choose 
pyenv install 3.9.18

# Output:
# ... 
# Installed Python-3.9.18 to ~/.pyenv/versions/3.9.18


~/.pyenv/versions/3.9.18/bin/python -V # Check that it works

pyenv local 3.9.18 # will activate the version for current directory 
                   # (file .python-version will be created/updated)
                   # Important: it's not a per-project virtualenv still!
python -V # Check that it works
which python  # It shows installation at .pyenv 
```

Your installed pythons will be located in the ~/.pyenv directory, but executables like _pythonX.X_ will be available from anywhere with the help of symlinks called [shims]. In order to activate the required symlink pointing to the version needed, you should run the command `pyenv local`.

I should say, that pyenv can do way more in terms of managing Python, e.g. create virtual environments. But I use it exclusively for installing/uninstalling required versions. For managing per-project installations (virtual environments), I use the next tool.

## Poetry

[This amazing tool][poetry] is a:

dependency manager superior to pip
package/publishing manager superior to setuptools/twine
good virtual environment manager, although I was fine with `python3 -m venv .venv` too
The way how poetry manages environments could be adjusted. Some useful configuration I’ve found very practical is the following: when packaging your app into docker, inside docker container you don’t want poetry to create any virtual environments, and use just global python. In that case, the following flags could be set:

```bash
poetry config virtualenvs.create false # prevents creating of env
poetry config virtualenvs.in-project false  # prevents using of existing .venv, if any
```

Otherwise, it will put (under a unique name) the venv into poetry’s cache folder, which could be better in case you want to have several venvs (for different versions) and be able to quickly switch between them, without re-creating. Why then it’s sometimes better to have an in-project folder located venv? For example, your IDE would be easier to identify the current Python project interpreter (I use this for VSCode which easily sees the local .venv folder but is [unable to find][vscode-poetry] the one located in poetry’s cache).

How I use pyenv’s python to create/switch virtual env:

```bash
poetry env use ~/.pyenv/versions/3.8.18/bin/python # by specific path

# Or better by using pyenv shims:
pyenv local 3.9.18
poetry env use 3.9

# then you can easily switch to another version:
pyenv install 3.10
pyenv local 3.10
poentry env use 3.10
```


## Postgres client

If you plan to work with a Postgres database, you can encounter an error while installing psycopg, a Python Postgres client. Try running this:


```
pip3 install psycopg2-binary
```

In case you see the following error,


```
...
Error: pg_config executable not found.
...
```

you’re our patient. It’s because a Python package psycopg2 requires C libraries installed into the system, so in theory, you just need to install `libpq`.

It's quite often not so easy, despite a [lot][1] of internet [discussions][2] and [Stack][3] Overflow [questions][4] that propose different solutions. What’s missing in your installation depends on multiple factors, including a version of MacOS. What helped in my case (MacOS Monterey 12.5):

```bash
brew install postgresql # Probably not needed, but better to have
brew install libpq --build-from-source  # Should be normally enough, but...
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
```

The last line, the update of PATH, was a crucial ingredient in my case. Turns out, brew installs libraries in a special location (/opt/homebrew/) which is not expected by pip3-install (you can check beforehand that pg_config lies in /opt/homebrew/opt/libpq/bin).


## Additional

As I mentioned in the beginning, it’s just a bare minimum. With time, you’ll need much more, and I’ll put here some actions/tools I need to add later, which is pretty optional and depends on your projects.

* If you use Github (Gitlab, Bitbucket, etc.), [set up SSH keys][ssh] to not type a password each time

* Some libraries are easier to install not from PyPi, but from from more powerful package management systems, capable of installing system libraries in isolated environments. So having [Conda][conda] on board is a good idea (although it’s slow and usually it’s possible to avoid it)

* For sure, Docker is needed. I like to use it as an easy option to run some ready-to-use service locally (e.g. aforementioned Postgres database server) and prefer not to use it as a development environment (although some people do this and there’s [good support for this in VSCode][vscode-devcontainers])

* Quite often such a thing is needed (usually to compile C): `xcode-select — install`



[DockerMac]: https://docs.docker.com/desktop/install/mac-install/

[iterm2]: https://iterm2.com/
[OhMyZsh]: https://ohmyz.sh/
[zsh-guides]: https://www.freecodecamp.org/news/how-to-configure-your-macos-terminal-with-zsh-like-a-pro-c0ab3f3c1156/
[ohmzsh-plugins]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins

[brew]: https://brew.sh/
[python]: https://www.python.org/downloads/macos/
[pyenv]: https://github.com/pyenv/pyenv
[shims]: https://github.com/pyenv/pyenv#understanding-shims

[poetry]: https://python-poetry.org/
[vscode-poetry]: https://www.reddit.com/r/vscode/comments/11kvr74/what_is_needed_to_make_vscode_respect_python/

[1]: https://bobcares.com/blog/error-pg_config-executable-not-found/
[2]: https://github.com/psycopg/psycopg2/issues/1200
[3]: https://stackoverflow.com/questions/61439689/problem-with-installing-psycopg2-on-mac-virtualenv-pg-config-executable-not-fou
[4]: https://stackoverflow.com/questions/73042760/pip-install-psycopg2-on-macos-m1-and-python-3-10-5-not-working

[ssh]: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
[conda]: https://conda.io/projects/conda/en/latest/index.html
[vscode-devcontainers]: https://code.visualstudio.com/docs/devcontainers/containers
