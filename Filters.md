### Plugin job enqueue, dequeue and processing

A job will go through 3 stages in its lifecycle: enqueue, processing, dequeue.
Message provides chained filter mechanism for developer to extend Message job processing.

There are 3 build-in filters:

1. Error Handling: catches and logs all StardardError in job's lifecycle.
2. Benchmarking: log benchmark time after processed a job.
3. Retry On Error: retry the action when catches any StardardError in job's lifecycle.

Error Handling and Retry On Error are configurable, see the document below for more details.

You can also add new filter to extend the way we processing job, for example, add debug log filter for a job's processing lifecycle:

    Message.job.filter('debug log') do |filter, job, action|
      lambda do |arg|
        Message.logger.debug { "Message #{action} #{job.name}: #{arg.inspect}" }
        filter.call(arg)
      end
    end

In above example, 'debug log' is filter name, the block defined is the filter.
The filter is call with 3 arguments:

1. filter: next filter object, is a lambda.
2. job: the job object applied the filter, please checkout Job interface for details.
3. action: [:enq, :deq, :process], indicates what action is applied for.

Then filter should initialize a lambda for processing the given job and action.

### Error handling

Job processing error handling is implemented as a job filter.

You can get the filter instance by:

    Message.filters.error_handling

You can configure a callback for any error caught by the error handling filter:

    Message.filters.error_handling.callback = lambda do |error, msg, job, action|
    end

### Retry on error

Message retries enqueue, processing and dequeue a job 3 tries by default.
It is implemented as a job filter and you can get the instance:

    Message.filters.retry_on_error

There are 3 options can be configured:

1. tries: how many times to retry when catched error, default is 3.
2. on: what's error to retry, default is StardardError.
3. sleep: how much time should sleep before next retry, default is 0.001.

