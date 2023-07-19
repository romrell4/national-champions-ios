# national-champions-ios

## Deployment

In order to deploy, run the following:
```
fl deploy ; notify
gco league-master
git merge -
fl deploy ; notify
gco -
```

If the deploy fails, try running pod install first, and test archiving from Xcode directly. It should then work
