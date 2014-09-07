# Message

Message provides reliable background/asynchronous job processing mechanism on top of simple queue interface.

You can plugin different queue implementation for different messaging system without worrying about job processing.

Also, Message provides an in-memory queue for making development and test easier.

## How to use

### Enqueue background job

    WelcomeMailer.enq.deliver(user)

### Start worker to process jobs

    Message.worker.start

## Job interface specification

Job = a queue + message processor

### enq(work), alias: <<

Queue up a new work

### process(size=1)

Process a work in queue by processor

## Job filters

    Message.job.filter(filter_name) do |next_filter|
      lambda do |*args, &block|
        next_filter.call(*args, &block)
      end
    end

Filters will be applied as the order initialized.
Checkout all filters:

    Message.job.filters

### add work filter

    Message.job.filter(:add) do |filter|
      lambda do |work|
        filter.call(work)
      end
    end

### process work filter


    Message.job.filter(:process) do |filter|
      lambda do |size, &processor|
        filter.call(size) do |msg|
          processor.call(msg)
        end
      end
    end

## Queue adapters

Change queue adapter to change different queue implementation. Default is a in memory queue for testing and development environment.

### Add a new adapter

    Message.queue.adapters[:sqs] = Message::SqsQueue

### Change adapter

    Message.queue.adapter = :sqs

## Queue interface specification

### name

Queue name.

### enq(msg), alias: <<

Enqueue message.

### deq(size, &block)

Dequeue message, non-blocking.

### size

(Approximate) queue size.


