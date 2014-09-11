# Message

https://travis-ci.org/xli/message.svg?branch=master

Message provides flexible & reliable background/asynchronous job processing mechanism on top of simple queue interface.

Any developer can create queue adapter for Message to hook up different messaging/queue system.

One in-memory queue is included with Message for you to start development and test,
and you can easily swap in other queues later.


## Installation


### Use AWS SQS as back-end queue system

    gem 'message-sqs'

## How to use

### Queuing jobs


Inspired by delayed_job API, call .async.method(params) on any object and it will be processed in the background.

    # without message
    @img.resize(36)

    # with message
    @img.async.resize(36)

### Start worker to process jobs

    Message.worker.start

### Change to synchronize mode

    Message.worker.sync = true

This is designed for test environment or Rails development environment.
After set the synch option to true, the async jobs will be processed immediately when .async.method(params) is called.
The default value is false.

### Change default worker job name

For some environment or queue system (e.g. AWS SQS), you will need set an application specific job name, so that you can share same account for multiple applications using Message.

    Message.worker.default_job = "app-name-#{Rails.env}-message-default"

## Job interface specification

Job = a queue + message processor

### initialize a job

    job = Message.job('name') { |msg| ... process msg ... }

### enq(msg), alias: <<

Queue up a message for processing:

    job << msg

### process(size=1)

Process a message in queue by processor defined when initializing the job

    job.process

Process multiple messages

    job.process(5)

## Job filters

You can add job filter to add additional functions to enqueue and process job message

    Message.job.filter(filter_name) do |next_filter, job, action|
      lambda do |*args, &block|
        next_filter.call(*args, &block)
      end
    end

Filters will be called as a chain by the order of initializing the filters.
When a job action executes, filters will be called to initialize a proc/lambda for executing
the action with parameters:

    next_filter: next filter's proc/lambda
    job: the job object executes the action
    action: :enq, :deq, :process


Checkout all filters:

    Message.job.filters # an Enumerable object

### filter example: log job actions

    Message.job.filter do |filter, job, action|
      lambda do |msg|
        Message.logger.info { "#{actoin} #{job.name} message: #{msg}" }
        filter.call(msg)
      end
    end

## Queue adapters

Change queue adapter to change different queue implementation. Default is a in memory queue for testing and development environments.

### Change adapter

    Message.queue.adapter = :sqs

### Add a new adapter

    Message.queue.adapters[:sqs] = Message::SqsQueue

## Queue interface specification

To hook up a new queue into Message.

### name

Queue name.

### enq(msg), alias: <<

Enqueue message, non-blocking.

### deq(size, &block)

Dequeue message, non-blocking.
It is up to Queue implementation when to delete the message in queue when deq got called with a block.

### size

(Approximate) queue size.

