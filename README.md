# Message

Message provides flexible & reliable background/asynchronous job processing mechanism on top of simple queue interface.

Any developer can create queue adapter for Message to hook up different messaging/queue system.

One in-memory queue is included with Message for you to start development and test,
and you can easily swap in other queues later.


## Installation



## How to use

### Queuing jobs


Inspired by delayed_job API, call .enq.method(params) on any object and it will be processed in the background.

    # without message
    @img.resize(36)

    # with message
    @img.enq.resize(36)

### Start worker to process jobs

    Message.worker.start

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

    Message.job.filter(filter_name) do |next_filter, job|
      lambda do |*args, &block|
        next_filter.call(*args, &block)
      end
    end

Filters will be applied as the order initialized.
Checkout all filters:

    Message.job.filters

### enq filter

    Message.job.filter(:enq) do |filter, job|
      lambda do |work|
        filter.call(work)
      end
    end

### process filter

    Message.job.filter(:process) do |filter, job|
      lambda do |size, &processor|
        filter.call(size) do |msg|
          processor.call(msg)
        end
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

