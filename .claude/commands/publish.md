# Publish Ruby Gem

Publish a new version of this Ruby gem. Follow these steps exactly:

## 1. Pre-flight checks
- Run `bundle exec rspec` to ensure all tests pass. Stop if any fail.
- Run `git status` to confirm working tree is clean (or prompt to commit first).
- Read `lib/snitch/version.rb` and confirm the version looks correct for this release.

## 2. Build the gem
```
gem build snitch.gemspec
```
This creates a `.gem` file in the project root.

## 3. Push to RubyGems
```
gem push snitch-rails-<VERSION>.gem
```
Replace `<VERSION>` with the version from step 1.

## 4. Tag and push
```
git tag v<VERSION>
git push origin main
git push origin v<VERSION>
```

## 5. Clean up
Remove the `.gem` file from the project root (it's in .gitignore but clean up anyway):
```
rm snitch-rails-<VERSION>.gem
```

## 6. Confirm
Report the published version and RubyGems URL: `https://rubygems.org/gems/snitch-rails`
