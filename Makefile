activate:
	source /opt/homebrew/opt/chruby/share/chruby/chruby.sh; \
	source /opt/homebrew/opt/chruby/share/chruby/auto.sh; \
	chruby ruby-3.3.3

build:
	bundle install
serve:
	bundle exec jekyll serve --drafts

git-squash:
	git reset $(git commit-tree HEAD^{tree} -m "A new start")
