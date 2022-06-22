# Build pipeline for ArgoCD Image Updater integration

## How it works

* Feature

```bash
make some changes in code
git add .
git commit -m "commit message"
git push
```

Results in
`cr.yandex/crps8j3slip157u5k5ko/gitops/build:0.0.0-202206141457.main-5d7a629d`

* Release

```bash
git tag 0.1.0
git push --tags
```

Results in
`cr.yandex/crps8j3slip157u5k5ko/gitops/build:0.1.0`

## Image updater setup


