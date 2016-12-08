#!/bin/bash
git add .
git commit -m 'trigger'
git push origin master
hugo -t hugo-future-imperfect
cd public
git add .
git commit -m "Generate site"
git push origin master

