#!/bin/bash
hugo -t hugo-future-imperfect
cd public
git add .
git commit -m "Generate site"
git push origin master

