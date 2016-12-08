+++
author = "Thai Tran"
categories = ["meteor"]
date = "2016-12-11"
description = "For a better logger"
featured="logger.png"
featuredalt = ""
featuredpath = "date"
linktitle = ""
title = "How do you override the console.log in Meteor"
type = "post"

+++

## Introduction

`console.log` is an easy way to debug your application. If you are using console.log, there is no change in your code between the client and the server. No need to define the logger and use the logger to show the log at all. The problem of this is console.log is pretty simple and you cannot redirect the level of the log in the way you want. Also, using console.log will make your log losing the timestamp when deploying in production mode (meteor build). Thus, moving the console.log to something else is a must

In term of logging, Winston is a really good candidate package. However, if you really use it in the official way, your server code and client code will be seperated. This is not good, in my opinion, since I need to think where I am in the project in order to print out the log.

## Solution

A quick and easy way is to override the behaviour of the console.log and inject the winston API into it. The good thing of meteor after 1.4 is it has the main gateway in `server/main.js` so you can be sure if you put code in this file, your code will be loaded before other files. This is not true if your project is still in 1.2 since most of the code will be loaded eagerly

```javascript

'use strict';

import util from 'util';
import winston from 'winston';
import path from 'path';
import { Meteor } from 'meteor/meteor';

winston.transports.DailyRotateFile = require('winston-daily-rotate-file');
let production = (process.env.NODE_ENV || '').toLowerCase() === 'production';

if (production) {
  let logDir = Meteor.settings['private']['logs'];

  let logOpts = {
    transports: [
      new(winston.transports.Console)(),
      new(winston.transports.DailyRotateFile)({
        name: 'info',
        datePattern: '.yyyy-MM-ddTHH',
        filename: path.join(logDir, "cba.log"),
        level: 'info',
        json : false,
        tailable : true
      }),
      new(winston.transports.DailyRotateFile)({
        name: 'error',
        datePattern: '.yyyy-MM-ddTHH',
        filename: path.join(logDir, "cba_error.log"),
        level: 'error',
        json : false,
        tailable : true
      })
    ]
  }

  let logger = new winston.Logger(logOpts);
  let formatArgs = (args) => {
    let arr = Array.prototype.slice.call(args);
    arr.unshift(`\t[${new Date().toISOString()}]\t`);
    return arr;
  }

  let log = console.log;
  console.log = function() {
    // a special case for Meteor, console log has to return during the LISTERNING log, otherwise, server cannot process request after
    // start up
    if (arguments.length === 1 && arguments[0] === 'LISTENING') return log.call(console, 'LISTENING');
    logger.info.apply(logger, arguments);
  };

  ['info', 'warn', 'error', 'debug'].forEach(function(method) {
    console[method] = function() {
      logger[method].apply(logger, arguments);
    }
  });
}

```
