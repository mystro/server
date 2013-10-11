class Api::StatusesController < ApplicationController
  def show
    job_count    = Job.count
    job_error    = Job.errors?
    resque_count = Resque.workers.count
    resque_error = (resque_count == 0)
    d            = {
        jobs:   {
            count: job_count,
            error: job_error
        },
        resque: {
            count: resque_count,
            error: resque_error,
        }
    }
    render json: d, status: :ok
  end
end