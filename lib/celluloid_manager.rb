require_relative "./badge_downloader"
require_relative "./rubygems_api"

class CelluloidManager 
  include Celluloid
  include Celluloid::Logger
    
  @attributes = [:jobs,:job_to_worker , :worker_to_job, :params, :condition]
 
  attr_accessor *@attributes
  
  attr_reader :worker_supervisor, :workers
  trap_exit :worker_died
  finalizer :finalize
  
  
  def initialize
    @condition = Celluloid::Condition.new
     
    @jobs = {}
    @job_to_worker = {}
    @worker_to_job = {}
  end
 
  def finalize
    terminate 
  end
   
  
  def delegate(params)
    job_id = @jobs.size + 1 
    @jobs[job_id] = params
  
    rubygems_api = RubygemsApi.new(params)
    Actor.current.link rubygems_api

    worker = BadgeDownloader.new(params, rubygems_api)
    
    @job_to_worker[job_id] = worker
    @worker_to_job[worker.mailbox.address] = params
    Actor.current.link worker
    # puts "Worker who called back for job: #{job.inspect} was #{worker.inspect}"
    blk = lambda do |sum|
      @condition.signal(sum)
    end
    worker.async.fetch_image_badge_svg(blk)
    return  @condition.wait
  end
  
  def worker_died(worker, reason)
    job = @worker_to_job[worker.mailbox.address]
    @worker_to_job.delete(worker.mailbox.address)
    info "restarting #{job} on new worker" 
    if job.present?
      delegate(job)
    end
  end 
    
end


