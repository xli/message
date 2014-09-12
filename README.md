# Message

[![Build Status](https://travis-ci.org/xli/message.svg?branch=master)](https://travis-ci.org/xli/message)


Message provides flexible & reliable background/asynchronous job processing mechanism on top of simple queue interface.

Any developer can create queue adapter for Message to hook up different messaging/queue system.

One in-memory queue is included with Message for you to start development and test,
and you can easily swap in other queues later.


## Installation


### Use AWS SQS as back-end queue system

    gem 'message-sqs'

## How to use

### Queuing jobs


Call .async.method(params) on any object and it will be processed in the background.

    # without message
    @img.resize(36)

    # with message
    @img.async.resize(36)

The above .async call will enqueue the job to a default job queue (Message.worker.default_job)

### Start worker to process default job queue

    Message.worker.start

### Named job queue

Queuing jobs into speicific queue named 'image-resize-queue':

    @img.async('image-resize-queue').resize(36)

Start a worker to process queued jobs:

    Message.worker('image-resize-queue').start

### Change to synchronize mode

    Message.worker.sync = true

This is designed for test environment or Rails development environment.
After set the synch option to true, the async jobs will be processed immediately when .async.method(params) is called.
The default value is false.

### Change default worker job name

For some environment or queue system (e.g. AWS SQS), you will need set an application specific job name, so that you can share same account for multiple applications using Message.

    Message.worker.default_job = "app-name-#{Rails.env}-message-default"

### Change backend queue system

By change queue adapter:

    Message.queue.adapter = :sqs

