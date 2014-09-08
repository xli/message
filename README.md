# Message

Message provides reliable background/asynchronous job processing mechanism on top of simple queue interface.

You can plugin different queue implementation for different messaging system without worrying about job processing.

Also, Message provides an in-memory queue for making development and test easier.

## How to use

### Enqueue background job

Change from:

    WelcomeMailer.deliver(user)

To:

    WelcomeMailer.enq.deliver(user)

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

Dequeue message, non-blocking. Should remove message from queue.

### size

(Approximate) queue size.


